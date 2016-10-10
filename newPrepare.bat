:: Name:     newPrepare.bat
:: Purpose:  Prepare development environment for ORTC and WebRTC
:: Author:   Sergej Jovanovic
:: Email:	 sergej@gnedo.com
:: Revision: September 2016 - initial version

@ECHO off

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

::paths
SET powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
SET curlPath=ortc\xplatform\curl
SET ortcWebRTCTemplatePath=ortc\windows\templates\libs\webrtc\webrtcForOrtc.vs2015.sln
SET ortcWebRTCDestinationPath=webrtc\xplatform\webrtc\webrtcForOrtc.vs2015.sln
::helper flags
SET taskFailed=0

::targets
SET prepare_ORTC_Environemnt=0
SET prepare_WebRTC_Environemnt=0

::platfroms
SET platform_ARM=1
SET platfrom_x86=1
SET platfrom_x64=1

::log levels
SET globalLogLevel=2											
SET error=0														
SET info=1														
SET warning=2													
SET debug=3														
SET trace=4														

::input arguments
SET supportedInputArguments=;platfrom;target;help;logLevel;diagnostic;					
SET target=all
SET platfrom=all
SET help=0
SET logLevel=2
SET diagnostic=0

::predefined messages
SET errorMessageInvalidArgument="Invalid input argument. For the list of available arguments and usage examples, please run script with -help option."
SET errorMessageInvalidTarget="Invalid target name. For the list of available targets and usage examples, please run script with -help option."
SET errorMessageInvalidPlatform="Invalid platfrom name. For the list of available targets and usage examples, please run script with -help option."
SET folderStructureError="ORTC invalid folder structure."

ECHO.
CALL:print %info% "Running prepare script ..."
ECHO.

:parseInputArguments
IF "%1"=="" (
	IF NOT "%nome%"=="" (
		SET "%nome%=1"
		SET nome=""
		
	) ELSE (
		GOTO:main
	)
)
SET aux=%1
IF "%aux:~0,1%"=="-" (
	IF NOT "%nome%"=="" (
		SET "%nome%=1"
	)
   SET nome=%aux:~1,250%
   SET validArgument=0
   CALL:checkIfArgumentIsValid !nome! validArgument
   IF !validArgument!==0 CALL:error 1 %errorMessageInvalidArgument%
) ELSE (
	IF NOT "%nome%"=="" (
		SET "%nome%=%1"
	) else (
		CALL:error 1 %errorMessageInvalidArgument%
	)
   SET nome=
)
SHIFT
GOTO parseInputArguments

::===========================================================================
:: Start execution of main flow (if parsing input parameters passed without issues)

:main

::Run diganostic if script is run in diagnostic mode
IF %diagnostic% EQU 1 CALL:diagnostic

::Determine targets
CALL:identifyTarget

::Determine targeted platforms
CALL:identifyPlatform

::Check is perl installed
CALL:perlCheck

::Check if python is installed. If it isn't install it and add in the path
CALL:pythonSetup

::Generate WebRTC VS2015 projects from gyp files
CALL:prepareWebRTC

::Prepare ORTC development environment
CALL:prepareORTC

::Download curl and build it
CALL:prepareCurl

::Finish script execution
CALL:done

GOTO:EOF
::===========================================================================

:diagnostic
SET logLevel=3
CALL:print 2 "Diagnostic mode - checking if some required programs are missing"
CALL:print 2  "================================================================================"
ECHO.
WHERE perl > NUL 2>&1
IF %ERRORLEVEL% EQU 1 (
	CALL:print 0 "Perl				not installed"
) else (
	CALL:print 1 "Perl				    installed"
)

WHERE python > NUL 2>&1
IF %ERRORLEVEL% EQU 1 (
	CALL:print 0 "Python				not installed"
) else (
	CALL:print 1 "Python				    installed"
)
ECHO.
CALL:print 2  "================================================================================"
ECHO.
CALL:print 1 "Diagnostic finished"
CALL bin\batchTerminator.bat
GOTO:EOF

REM Based on input arguments determine targeted projects (WebRTC or ORTC)
:identifyTarget
SET validInput=0
SET messageText=

IF /I "%target%"=="all" (
	SET prepare_ORTC_Environemnt=1
	SET prepare_WebRTC_Environemnt=1
	SET validInput=1
	SET messageText=Preparing webRTC and ORTC development environment ...
) ELSE (
	IF /I "%target%"=="webrtc" (
		SET prepare_WebRTC_Environemnt=1
		SET validInput=1
	)
	IF /I "%target%"=="ortc" (
		SET prepare_ORTC_Environemnt=1
		SET validInput=1
	)

	IF !validInput!==1 (
		SET messageText=Preparing %target% development environment ...
	)
)

:: If input is not valid terminate script execution
IF !validInput!==1 (
	CALL:print %warning% "!messageText!"
) ELSE (
	CALL:error 1 %errorMessageInvalidTarget%
)
GOTO:EOF

REM Based on input arguments determine targeted platforms (x64, x86 or ARM)
:identifyPlatform
SET validInput=0
SET messageText=

IF /I "%platfrom%"=="all" (
	SET platform_ARM=1
	SET platform_x64=1
	SET platform_x86=1
	SET validInput=1
	SET messageText=Preparing development environment for ARM, x64 and x86 platforms ...
) ELSE (
	IF /I "%platfrom%"=="arm" (
		SET platform_ARM=1
		SET validInput=1
	)
	
	IF /I "%platfrom%"=="x64" (
		SET platform_x64=1
		SET validInput=1
	)

	IF /I "%platfrom%"=="x86" (
		SET platform_x86=1
		SET validInput=1
	)
	
	IF !validInput!==1 (
		SET messageText=Preparing development environment for %platfrom% platform...
	)
)
:: If input is not valid terminate script execution
IF !validInput!==1 (
	CALL:print %warning% "!messageText!"
) ELSE (
	CALL:error 1 %errorMessageInvalidPlatform%
)
GOTO:EOF

REM Check if entered valid input argument
:checkIfArgumentIsValid
IF "!supportedInputArguments:;%~1;=!" neq "%supportedInputArguments%" (
	::it is valid
	SET %2=1
) ELSE (
	::it is not valid
	SET %2=0
)
GOTO:EOF

REM check if perl is installed
:perlCheck
WHERE perl > NUL 2>&1
IF %ERRORLEVEL% EQU 1 (
	ECHO.
	CALL:print 2  "================================================================================"
	ECHO.
	CALL:print 2  "Warning! Warning! Warning! Warning! Warning! Warning! Warning!"
	ECHO.
	CALL:print 2  "Perl is missing."
	CALL:print 2  "You need to have installed Perl to build projects properly."
	CALL:print 2  "Use the 32-bit perl from Strawberry http://strawberryperl.com/ to avoid possible linking errors and incorrect assember files generation."
	CALL:print 2  "Download URL: http://strawberryperl.com/download/5.22.1.2/strawberry-perl-5.22.1.2-32bit.msi"
	CALL:print 2  "Make sure that the perl path from Strawberry appears at the beginning of all other perl paths in the PATH" 
	ECHO.
	CALL:print 2  "================================================================================"
	ECHO.
	CALL:print 2  "NOTE: Please restart your command shell after installing perl and re-run this script..."	
	ECHO.
	
	CALL:error 1 "Perl has to be installed before running prepare script!"
	ECHO.	
)
GOTO:EOF

:pythonSetup
WHERE python > NUL 2>&1
IF %ERRORLEVEL% EQU 1 (
	CALL:print %warning%  "NOTE: Installing Python and continuing build..."
	CALL:print %debug%  "Installing Python ..."
	CALL:download https://www.python.org/ftp/python/2.7.6/python-2.7.6.msi  python-2.7.6.msi
	IF !taskFailed!==1 (
		CALL:error 1  "Downloading python installer has failed. Script execution will be terminated. Please, run script once more, if python doesn't get installed again, please do it manually."
	) ELSE (
		START "Python install" /wait msiexec /i python-2.7.6.msi /quiet
		IF !ERRORLEVEL! NEQ 0 (
			CALL:error 1  "Python installation has failed. Script execution will be terminated. Please, run script once more, if python doesn't get installed again, please do it manually."
		) ELSE (
			CALL:print %debug% "Python is successfully installed"
		)
		CALL:print %trace%  "Deleting downloaded file."
		DEL python-2.7.6.msi
		IF !ERRORLEVEL! NEQ 0 (
			CALL:error 0  "Deleting python installer from /bin folder has failed. You can delete it manually."
		)
	)
	
	IF EXIST C:\Python27\nul CALL:set_path "C:\Python27"
	IF EXIST D:\Python27\nul CALL:set_path "D:\Python27"
	
	WHERE python > NUL 2>&1
	IF !ERRORLEVEL! EQU 1 (
		CALL:error 0  "Python is not added to the path."
	) else (
		CALL:print %debug%  "Python is added to the path."
	)
) ELSE (
	CALL:print %trace%  "Python is present."
)

GOTO:EOF

:prepareORTC

:: Create solutions folder where will be stored links to real solutions
::CALL:makeDirectory .\solutions

:: Make link to ortc-lib-sdk-win.vs2015 solution
::CALL:makeLinkToFile solutions\ortc-lib-sdk-win.vs20151.sln ortc\windows\wrapper\projects\ortc-lib-sdk-win.vs2015.sln

:: Copy webrtc solution template
CALL:copyTemplates

::START solutions\ortc-lib-sdk-win.vs20151.sln

GOTO:EOF

::Generate WebRTC projects
:prepareWebRTC

CALL bin\newWebRTC-Prepare.bat -platform %platform% -logLevel %logLevel%

GOTO:EOF

REM Download and build curl
:prepareCurl
CALL:print %debug% "Preparing curl ..."

IF NOT EXIST %curlPath% CALL:error 1 "%folderStructureError:"=% %curlPath% does not exist!"

PUSHD %curlPath% > NUL
CALL:print %trace% "Pushed %curlPath% path"

CALL newCurl-Prepare.bat -logLevel %globalLogLevel%

::IF %logLevel% GEQ %trace% (
::	CALL prepare.bat curl 
::) ELSE (
::	CALL prepare.bat curl  >NUL
::)

if !ERRORLEVEL! EQU 1 CALL:error 1 "Curl preparation has failed."

POPD > NUL


GOTO:EOF

REM Download file (first argument) to desired destination (second argument)
:download
IF EXIST %~2 GOTO:EOF
%powershell_path% "Start-BitsTransfer %~1 -Destination %~2"
IF %ERRORLEVEL% EQU 1 SET taskFailed=1

GOTO:EOF

REM Add path to the user variables
:set_path
IF "%~1"=="" EXIT /b 2
IF NOT DEFINED PATH EXIT /b 2
::
:: Determine if function was called while delayed expansion was enabled
SETLOCAL
SET "NotDelayed=!"
::
:: Prepare to safely parse PATH into individual paths
SETLOCAL DisableDelayedExpansion
SET "var=%path:"=""%"
SET "var=%var:^=^^%"
SET "var=%var:&=^&%"
SET "var=%var:|=^|%"
SET "var=%var:<=^<%"
SET "var=%var:>=^>%"
SET "var=%var:;=^;^;%"
SET var=%var:""="%
SET "var=%var:"=""Q%"
SET "var=%var:;;="S"S%"
SET "var=%var:^;^;=;%"
SET "var=%var:""="%"
SETLOCAL EnableDelayedExpansion
SET "var=!var:"Q=!"
SET "var=!var:"S"S=";"!"
::
:: Remove quotes from pathVar and abort if it becomes empty
rem set "new=!%~1:"^=!"
SET new=%~1

IF NOT DEFINED new EXIT /b 2
::
:: Determine if pathVar is fully qualified
ECHO("!new!"|FINDSTR /i /r /c:^"^^\"[a-zA-Z]:[\\/][^\\/]" ^
                           /c:^"^^\"[\\][\\]" >NUL ^
  && SET "abs=1" || SET "abs=0"
::
:: For each path in PATH, check if path is fully qualified and then
:: do proper comparison with pathVar. Exit if a match is found.
:: Delayed expansion must be disabled when expanding FOR variables
:: just in case the value contains !
FOR %%A IN ("!new!\") DO FOR %%B IN ("!var!") DO (
  IF "!!"=="" SETLOCAL disableDelayedExpansion
  FOR %%C IN ("%%~B\") DO (
    ECHO(%%B|FINDSTR /i /r /c:^"^^\"[a-zA-Z]:[\\/][^\\/]" ^
                           /c:^"^^\"[\\][\\]" >NUL ^
      && (IF %abs%==1 IF /i "%%~sA"=="%%~sC" EXIT /b 0) ^
      || (IF %abs%==0 IF /i %%A==%%C EXIT /b 0)
  )
)
::
:: Build the modified PATH, enclosing the added path in quotes
:: only if it contains ;
SETLOCAL enableDelayedExpansion
IF "!new:;=!" NEQ "!new!" SET new="!new!"
IF /i "%~2"=="/B" (SET "rtn=!new!;!path!") ELSE SET "rtn=!path!;!new!"
::
:: rtn now contains the modified PATH. We need to safely pass the
:: value accross the ENDLOCAL barrier
::
:: Make rtn safe for assignment using normal expansion by replacing
:: % and " with not yet defined FOR variables
SET "rtn=!rtn:%%=%%A!"
SET "rtn=!rtn:"=%%B!"
::
:: Escape ^ and ! if function was called while delayed expansion was enabled.
:: The trailing ! in the second assignment is critical and must not be removed.
IF NOT DEFINED NotDelayed SET "rtn=!rtn:^=^^^^!"
IF NOT DEFINED NotDelayed SET "rtn=%rtn:!=^^^!%" !
::
:: Pass the rtn value accross the ENDLOCAL barrier using FOR variables to
:: restore the % and " characters. Again the trailing ! is critical.
FOR /f "usebackq tokens=1,2" %%A IN ('%%^ ^"') DO (
  ENDLOCAL & ENDLOCAL & ENDLOCAL & ENDLOCAL & ENDLOCAL
  SET "path=%rtn%" !
)
%powershell_path% -NoProfile -ExecutionPolicy Bypass -command "[Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::User)"

GOTO:EOF

REM Create a folder
:makeDirectory
IF NOT EXIST %~1\NUL (
	MKDIR %~1
	CALL:print %trace% "Created folder %~1"
) ELSE (
	CALL:print %trace% "%~1 folder already exists"
)
GOTO:EOF

REM Create symbolic link (first argument), that will point to desired file (second argument)
:makeLinkToFile

IF EXIST %~1 GOTO:alreadyexists
IF NOT EXIST %~2 CALL:error 1 "%folderStructureError:"=% %~2 does not exist!"

CALL:print %trace% Creating symbolic link "%~1" for the file "%~2"

::Make hard link to ortc-lib-sdk-win.vs20151.sln

IF %logLevel% GEQ %trace% (
	MKLINK /H %~1 %~2
) ELSE (
	MKLINK /H %~1 %~2  >NUL
)
IF %ERRORLEVEL% NEQ 0 CALL:ERROR 1 "COULD NOT CREATE SYMBOLIC LINK TO %~2"

:alreadyexists
POPD

GOTO:EOF

REM Copy all ORTC template required to set developer environment
:copyTemplates

IF NOT EXIST %ortcWebRTCTemplatePath% CALL:error 1 "%folderStructureError:"=% %ortcWebRTCTemplatePath% does not exist!"

COPY %ortcWebRTCTemplatePath% %ortcWebRTCDestinationPath% >NUL

CALL:print %trace% Copied file %ortcWebRTCTemplatePath% to %ortcWebRTCDestinationPath%

IF %ERRORLEVEL% NEQ 0 CALL:error 1 "%folderStructureError:"=% Unable to copy WebRTC temaple solution file"

GOTO:EOF

REM Print logger message. First argument is log level, and second one is the message
:print
SET logType=%1
SET logMessage=%~2

if %logLevel% GEQ  %logType% (
	if %logType%==0 ECHO [91m%logMessage%[0m
	if %logType%==1 ECHO [92m%logMessage%[0m
	if %logType%==2 ECHO [93m%logMessage%[0m
	if %logType%==3 ECHO %logMessage%
	if %logType%==4 ECHO %logMessage%
)

GOTO:EOF

REM Print the error message and terminate further execution if error is critical.Firt argument is critical error flag (1 for critical). Second is error message
:error
SET criticalError=%~1
SET errorMessage=%~2

IF %criticalError%==0 (
	ECHO.
	CALL:print %warning% "WARNING: %errorMessage%"
	ECHO.
) ELSE (
	ECHO.
	CALL:print %error% "CRITICAL ERROR: %errorMessage%"
	ECHO.
	ECHO.
	CALL:print %error% "FAILURE:Preparing environment has failed!"
	ECHO.
	::terminate batch execution
	CALL bin\batchTerminator.bat
)
GOTO:EOF

:done
ECHO.
CALL:print %info% "Success: Development environment is set."
ECHO. 
