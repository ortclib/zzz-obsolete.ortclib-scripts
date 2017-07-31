:: Name:      prepare.bat
:: Purpose:   Prepare development environment for ORTC and WebRTC
:: Author:    Sergej Jovanovic
:: Email:     sergej@gnedo.com
:: Twitter:   @JovanovicSergej
:: Revision:  September 2016 - initial version

@ECHO off

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

::paths
SET powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
SET curlPath=ortc\xplatform\curl
SET ortcWebRTCTemplatePath=ortc\windows\templates\libs\webrtc\webrtcForOrtc.vs2015.sln
SET ortcWebRTCDestinationPath=webrtc\xplatform\webrtc\webrtcForOrtc.vs2015.sln
SET ortcWebRTCWin32TemplatePath=ortc\windows\templates\libs\webrtc\webrtcForOrtc.Win32.vs2015.sln
SET ortcWebRTCWin32DestinationPath=webrtc\xplatform\webrtc\webrtcForOrtc.Win32.vs2015.sln
SET webRTCTemplatePath=webrtc\windows\templates\libs\webrtc\webrtcLib.sln
SET webRTCDestinationPath=webrtc\xplatform\webrtc\webrtcLib.sln
SET ortciOSBinariesDestinationFolder=ortc\apple\libs\
SET ortciOSBinariesDestinationPath=ortc\apple\libs\libOrtc.dylib

::downloads
SET pythonVersion=2.7.6
SET ninjaVersion=v1.6.0
SET pythonDestinationPath=python-%pythonVersion%.msi
SET ninjaDestinationPath=.\bin\ninja-win.zip
SET ortcBinariesDestinationPath=ortc\windows\projects\msvc\OrtcBinding\libOrtc.dylib
 
::urls
SET pythonDownloadUrl=https://www.python.org/ftp/python/%pythonVersion%/python-%pythonVersion%.msi
SET ninjaDownloadUrl=http://github.com/martine/ninja/releases/download/%ninjaVersion%/ninja-win.zip 
SET binariesGitPath=https://github.com/ortclib/ortc-binaries.git

::helper flags
SET taskFailed=0
SET ortcAvailable=0
SET startTime=%time%
SET endingTime=0
SET defaultProperties=0

::targets
SET prepare_ORTC_Environemnt=0
SET prepare_WebRTC_Environemnt=0

::platforms
SET platform_ARM=1
SET platform_x86=1
SET platform_x64=1
SET platform_win32=1
SET platform_win32_x64=0

::log levels
SET globalLogLevel=2											
SET error=0														
SET info=1														
SET warning=2													
SET debug=3														
SET trace=4														

::input arguments
SET supportedInputArguments=;platform;target;help;logLevel;diagnostic;noEventing;getBinaries;				
SET target=all
SET platform=all
SET help=0
SET logLevel=2
SET diagnostic=0
SET noEventing=0
SET getBinaries=1
::predefined messages
SET errorMessageInvalidArgument="Invalid input argument. For the list of available arguments and usage examples, please run script with -help option."
SET errorMessageInvalidTarget="Invalid target name. For the list of available targets and usage examples, please run script with -help option."
SET errorMessageInvalidPlatform="Invalid platform name. For the list of available targets and usage examples, please run script with -help option."
SET folderStructureError="ORTC invalid folder structure."

CALL:precheck

IF "%1"=="" (
	CALL:print %warning% "Running script with default parameters: "
	CALL:print %warning% "Target: all ^(Ortc and WebRtc^)"
	CALL:print %warning% "Platform: all ^(x64, x86, arm and win32^)"
	CALL:print %warning% "Log level: %logLevel% ^(warning^)"
	SET defaultProperties=1
)

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

CALL:showHelp

::Run diganostic if script is run in diagnostic mode
IF %diagnostic% EQU 1 CALL:diagnostic

ECHO.
CALL:print %info% "Running prepare script ..."
ECHO.

IF EXIST bin\Config.bat CALL bin\Config.bat

IF %defaultProperties% EQU 0 (
	CALL:print %warning% "Running script parameters:"
	CALL:print %warning% "Target: %target%"
	CALL:print %warning% "Platform: %platform%"
	CALL:print %warning% "Log level: %logLevel%"
	SET defaultProperties=1
)

::Check if ORTC is available
CALL:checkOrtcAvailability
 
::Determine targets
CALL:identifyTarget

::Determine targeted platforms
CALL:identifyPlatform

::Check is perl installed
CALL:perlCheck

::Check if git installed
CALL:gitCheck

::Check if python is installed. If it isn't install it and add in the path
CALL:pythonSetup

::Install ninja if missing
::CALL:installNinja

::Generate WebRTC VS2015 projects from gn files
CALL:prepareWebRTC

IF %prepare_ORTC_Environemnt% EQU 1 (
	::Prepare ORTC development environment
	CALL:prepareORTC

	::Download curl and build it
	CALL:prepareCurl
	
	CALL:prepareEventing

	CALL:getBinaries
)

::Finish script execution
CALL:done

GOTO:EOF
::===========================================================================

:precheck
IF NOT "%CD%"=="%CD: =%" CALL:error 1 "Path must not contain folders with spaces in name"
IF EXIST ..\bin\nul (
	CALL:error 1 "Do not run scripts from bin directory!"
	CALL batchTerminator.bat
)
GOTO:EOF

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

WHERE git > NUL 2>&1
IF %ERRORLEVEL% EQU 1 (
	CALL:print 0 "Git   				not installed"
) else (
	CALL:print 1 "Git   				    installed"
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
	SET prepare_ORTC_Environemnt=%ortcAvailable%
	SET prepare_WebRTC_Environemnt=1
	SET validInput=1
	IF !prepare_ORTC_Environemnt! EQU 1 (
		SET messageText=Preparing webRTC and ORTC development environment ...
	) ELSE (
		SET messageText=Preparing webRTC development environment ...
		)
) ELSE (
	IF /I "%target%"=="webrtc" (
		SET prepare_WebRTC_Environemnt=1
		SET validInput=1
	)
	IF /I "%target%"=="ortc" (
	IF %ortcAvailable% EQU 0 CALL:ERROR 1 "ORTC is not available!"
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

IF /I "%platform%"=="all" (
	SET platform_ARM=1
	SET platform_x64=1
	SET platform_x86=1
	SET platform_win32=1
	SET validInput=1
	SET messageText=Preparing development environment for ARM, x64, x86 and win32 platforms ...
) ELSE (
	IF /I "%platform%"=="arm" (
		SET platform_ARM=1
		SET validInput=1
	)
	
	IF /I "%platform%"=="x64" (
		SET platform_x64=1
		SET validInput=1
	)

	IF /I "%platform%"=="x86" (
		SET platform_x86=1
		SET validInput=1
	)
	
	IF /I "%platform%"=="win32" (
		SET platform_win32=1
		SET validInput=1
	)
	
	IF /I "%platform%"=="win32_x64" (
		SET platform_win32_x64=1
		SET validInput=1
	)
	
	IF !validInput!==1 (
		SET messageText=Preparing development environment for %platform% platform...
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

REM check if git is installed
:gitCheck
WHERE git > NUL 2>&1
IF %ERRORLEVEL% EQU 1 (
	ECHO.
	CALL:print 2  "================================================================================"
	ECHO.
	CALL:print 2  "Warning! Warning! Warning! Warning! Warning! Warning! Warning!"
	ECHO.
	CALL:print 2  "Git is missing."
	CALL:print 2  "You need to have installed git to build projects properly."
	ECHO.
	CALL:print 2  "================================================================================"
	ECHO.
	CALL:print 2  "NOTE: Please restart your command shell after installing git and re-run this script..."	
	ECHO.
	
	CALL:error 1 "git has to be installed before running prepare script!"
	ECHO.	
)
GOTO:EOF

:pythonSetup
WHERE python > NUL 2>&1
IF %ERRORLEVEL% EQU 1 (
	CALL:print %warning%  "NOTE: Installing Python and continuing build..."
	CALL:print %debug%  "Installing Python ..."
	CALL:download %pythonDownloadUrl% %pythonDestinationPath%
	IF !taskFailed!==1 (
		CALL:error 1  "Downloading python installer has failed. Script execution will be terminated. Please, run script once more, if python doesn't get installed again, please do it manually."
	) ELSE (
		START "Python install" /wait msiexec /i %pythonDestinationPath% /quiet
		IF !ERRORLEVEL! NEQ 0 (
			CALL:error 1  "Python installation has failed. Script execution will be terminated. Please, run script once more, if python doesn't get installed again, please do it manually."
		) ELSE (
			CALL:print %debug% "Python is successfully installed"
		)
		CALL:print %trace%  "Deleting downloaded file."
		DEL %pythonDestinationPath%
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
CALL:copyTemplates %ortcWebRTCTemplatePath% %ortcWebRTCDestinationPath%
CALL:copyTemplates %ortcWebRTCWin32TemplatePath% %ortcWebRTCWin32DestinationPath%
::CALL:copyTemplates %webRTCTemplatePath% %webRTCDestinationPath%

::START solutions\ortc-lib-sdk-win.vs20151.sln

GOTO:EOF

::Generate WebRTC projects
:prepareWebRTC

CALL bin\prepareWebRtc.bat -platform %platform% -logLevel %logLevel%

GOTO:EOF

REM Download and build curl
:prepareCurl
CALL:print %debug% "Preparing curl ..."

IF NOT EXIST %curlPath% CALL:error 1 "%folderStructureError:"=% %curlPath% does not exist!"

PUSHD %curlPath% > NUL
CALL:print %trace% "Pushed %curlPath% path"

CALL prepareCurl.bat -logLevel %globalLogLevel%

::IF %logLevel% GEQ %trace% (
::	CALL prepare.bat curl 
::) ELSE (
::	CALL prepare.bat curl  >NUL
::)

IF !ERRORLEVEL! EQU 1 CALL:error 1 "Curl preparation has failed."

POPD > NUL

GOTO:EOF

::Generate events providers
:prepareEventing

IF %noEventing% EQU 0 (
	CALL bin\prepareEventing.bat -platform x64 -logLevel %logLevel%
	CALL bin\prepareEventing.bat -platform x86 -logLevel %logLevel%
	CALL bin\prepareEventing.bat -platform win32 -logLevel %logLevel%
)

GOTO:EOF


:downloadBinariesFromRepo
ECHO.
CALL:print %info% "Donwloading binaries from repo !BINARIES_DOWNLOAD_REPO_URL!"
IF EXIST ..\ortc-binaries\NUL RMDIR /q /s ..\ortc-binaries\
	
PUSHD ..\
CALL git clone !BINARIES_DOWNLOAD_REPO_URL! -b !BINARIES_DOWNLOAD_REPO_BRANCH! > NUL
IF !ERRORLEVEL! EQU 1 CALL:error 1 "Failed cloning binaries."
POPD
	
CALL:makeDirectory %ortciOSBinariesDestinationFolder%
CALL:copyTemplates ..\ortc-binaries\Release\libOrtc.dylib %ortciOSBinariesDestinationPath%
	
IF EXIST ..\ortc-binaries\NUL RMDIR /q /s ..\ortc-binaries\
GOTO:EOF

:downloadBinariesFromURL
ECHO.
CALL:print %info% "Donwloading binaries from URL !BINARIES_DOWNLOAD_URL!"

CALL:makeDirectory %ortciOSBinariesDestinationFolder%
CALL:download !BINARIES_DOWNLOAD_URL! %ortciOSBinariesDestinationPath%
IF !taskFailed! EQU 1 CALL:ERROR 1 "Failed downloading binaries from !BINARIES_DOWNLOAD_URL!"

GOTO:EOF

:getBinaries

IF %getBinaries% EQU 1 (
	IF DEFINED BINARIES_DOWNLOAD_REPO_URL (
		CALL:downloadBinariesFromRepo
	) ELSE (
		IF DEFINED BINARIES_DOWNLOAD_URL CALL:downloadBinariesFromURL
	)
)

GOTO:EOF


REM Download file (first argument) to desired destination (second argument)
:download
IF EXIST %~2 GOTO:EOF
::%powershell_path% "Start-BitsTransfer %~1 -Destination %~2"
%powershell_path% -Command (new-object System.Net.WebClient).DownloadFile('%~1','%~2')

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

IF NOT EXIST %~1 CALL:error 1 "%folderStructureError:"=% %~1 does not exist!"

echo COPY %~1 %~2
COPY %~1 %~2 >NUL

echo CALL print %trace% Copied file %~1 to %~2
CALL:print %trace% Copied file %~1 to %~2

IF %ERRORLEVEL% NEQ 0 CALL:error 1 "%folderStructureError:"=% Unable to copy WebRTC template solution file"

GOTO:EOF

:checkOrtcAvailability
IF EXIST ortc\NUL SET ortcAvailable=1
GOTO:EOF

:installNinja

WHERE ninja > NUL 2>&1
IF !ERRORLEVEL! EQU 1 (

	CALL:print %trace% "Ninja is not in the path"
	
	IF NOT EXIST .\bin\ninja.exe (
		CALL:print %trace% "Downloading ninja ..."
		CALL:download %ninjaDownloadUrl% %ninjaDestinationPath%

		IF EXIST .\bin\ninja-win.zip (
			CALL::print %trace% "Unarchiving ninja-win.zip ..."
			CALL:unzipfile "%~dp0" "%~dp0ninja-win.zip" 
		) ELSE (
			CALL:error 0 "Ninja is not installed. Projects won't be buildable."
		)
	)
	
	IF EXIST .\bin\ninja.exe (
		CALL::print %trace% "Updating projects ..."
		START /B /wait .\bin\upn.exe .\bin\ .\webrtc\xplatform\webrtc\ .\webrtc\xplatform\webrtc\chromium\src\
	)
)

GOTO:EOF

:unzipfile 
SET vbs="%temp%\_.vbs"
IF EXIST %vbs% DEL /f /q %vbs%
>%vbs%  ECHO Set fso = CreateObject("Scripting.FileSystemObject")
>>%vbs% ECHO If NOT fso.FolderExists(%1) Then
>>%vbs% ECHO fso.CreateFolder(%1)
>>%vbs% ECHO End If
>>%vbs% ECHO set objShell = CreateObject("Shell.Application")
>>%vbs% ECHO set FilesInZip=objShell.NameSpace(%2).items
>>%vbs% ECHO objShell.NameSpace(%1).CopyHere(FilesInZip)
>>%vbs% ECHO Set fso = Nothing
>>%vbs% ECHO Set objShell = Nothing
CSCRIPT //nologo %vbs%
IF EXIST %vbs% DEL /f /q %vbs%
DEL /f /q %2
GOTO:EOF

:showHelp
IF %help% EQU 0 GOTO:EOF

ECHO.
ECHO    [92mAvailable parameters:[0m
ECHO.
ECHO  	[93m-diagnostic[0m 		Flag for runing check if system is ready for webrtc development.
ECHO.
ECHO 	[93m-help[0m 		Show script usage
ECHO.
ECHO 	[93m-logLevel[0m	Log level (error=0, info =1, warning=2, debug=3, trace=4)
ECHO.
ECHO		[93m-noEventing[0m 	Flag not to run eventing preparations for Ortc
ECHO.
ECHO 	[93m-target[0m		Name of the target to prepare environment for. Ortc or WebRtc. If this parameter is not set dev environment will be prepared for both available targets.
ECHO.
ECHO		[93m-platform[0m 	Platform name to set environment for. Default is All (win32,x86,x64,arm)
ECHO.
CALL bin\batchTerminator.bat

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
	SET endTime=%time%
	CALL:showTime
	::terminate batch execution
	CALL bin\batchTerminator.bat
)
GOTO:EOF

:showTime

SET options="tokens=1-4 delims=:.,"
FOR /f %options% %%a in ("%startTime%") do SET start_h=%%a&SET /a start_m=100%%b %% 100&SET /a start_s=100%%c %% 100&SET /a start_ms=100%%d %% 100
FOR /f %options% %%a in ("%endTime%") do SET end_h=%%a&SET /a end_m=100%%b %% 100&SET /a end_s=100%%c %% 100&SET /a end_ms=100%%d %% 100

SET /a hours=%end_h%-%start_h%
SET /a mins=%end_m%-%start_m%
SET /a secs=%end_s%-%start_s%
SET /a ms=%end_ms%-%start_ms%
IF %ms% lss 0 SET /a secs = %secs% - 1 & SET /a ms = 100%ms%
IF %secs% lss 0 SET /a mins = %mins% - 1 & SET /a secs = 60%secs%
IF %mins% lss 0 SET /a hours = %hours% - 1 & SET /a mins = 60%mins%
IF %hours% lss 0 SET /a hours = 24%hours%

SET /a totalsecs = %hours%*3600 + %mins%*60 + %secs% 

IF 1%ms% lss 100 SET ms=0%ms%
IF %secs% lss 10 SET secs=0%secs%
IF %mins% lss 10 SET mins=0%mins%
IF %hours% lss 10 SET hours=0%hours%

:: mission accomplished
ECHO [93mTotal execution time: %hours%:%mins%:%secs% (%totalsecs%s total)[0m

GOTO:EOF

:done
ECHO.
CALL:print %info% "Success: Development environment is set."
SET endTime=%time%
CALL:showTime
ECHO. 
