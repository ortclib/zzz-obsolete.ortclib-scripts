#!/bin/bash

logLevel=4
#log levels
globalLogLevel=2
error=0
info=1
warning=2
debug=3
trace=4

print()
{
  logType=$1
  logMessage=$2

  if [ $logLevel -eq  $logType ] || [ $logLevel -gt  $logType ]
  then
  	if [ $logType -eq 0 ]
    then
      printf "\e[0;31m $logMessage \e[m\n"
    fi
    if [ $logType -eq 1 ]
    then
      printf "\e[0;32m $logMessage \e[m\n"
    fi
    if [ $logType -eq 2 ]
    then
      printf "\e[0;33m $logMessage \e[\nm"
    fi
    if [ $logType -gt 2 ]
    then
      ECHO $logMessage
    fi
  fi
}

help()
{
  echo.
  printf "\e[0;32m Available parameters: \e[m\n"
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
}

error()
{
  criticalError=$1
  errorMessage=$2

  if [ $criticalError -eq 0]
  then
  	ECHO.
  	print %warning% "WARNING: $errorMessage"
  	ECHO.
  else
  	ECHO.
    print %error% "CRITICAL ERROR: $errorMessage"
  	ECHO.
  	ECHO.
  	print %error% "FAILURE:Preparing environment has failed!"
  	ECHO.
  	#SET endTime=%time%
  	#CALL:showTime
  	::terminate batch execution
  	exit 1
  fi
}

done()
{
  ECHO.
  print %info% "Success: Development environment is set."
  ECHO.
}

#platform;target;help;logLevel;diagnostic;noEventing;
while getopts ":p:t:hl:dn" opt; do
  case $opt in
    p)
        platform=$OPTARG
        ;;
    t)
        target=$OPTARG
        ;;
    h)
        help=1
        ;;
    l)
        logLevel=$OPTARG
        ;;
    d)
        diagnostic=1
        ;;
    n)
        noEventing=1
        ;;
    esac
done
print 0 $platform

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

::Check if python is installed. If it isn't install it and add in the path
CALL:pythonSetup

::Generate WebRTC VS2015 projects from gyp files
CALL:prepareWebRTC

::Install ninja if missing
IF %platform_win32% EQU 1 CALL:installNinja

IF %prepare_ORTC_Environemnt% EQU 1 (
	::Prepare ORTC development environment
	CALL:prepareORTC

	::Download curl and build it
	CALL:prepareCurl

	CALL:prepareEventing
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

if !ERRORLEVEL! EQU 1 CALL:error 1 "Curl preparation has failed."

POPD > NUL

GOTO:EOF

::Generate events providers
:prepareEventing

IF %noEventing% EQU 0 CALL bin\prepareEventing.bat -platform x64 -logLevel %logLevel%

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

COPY %~1 %~2 >NUL

CALL:print %trace% Copied file %~1 to %~2

IF %ERRORLEVEL% NEQ 0 CALL:error 1 "%folderStructureError:"=% Unable to copy WebRTC temaple solution file"

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
			CALL:error 0 "Ninja is not installed. Win32 projects cwon't be buildable."
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
