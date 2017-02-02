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
  printf "\e[0;33m-diagnostic\e[m		Flag for runing check if system is ready for webrtc development."
  ECHO.
  printf "\e[0;33m-help[0m 		Show script usage"
  ECHO.
  printf "\e[0;33m-logLevel[0m	Log level (error=0, info =1, warning=2, debug=3, trace=4)"
  ECHO.
  printf "\e[0;33m-noEventing[0m 	Flag not to run eventing preparations for Ortc"
  ECHO.
  printf "\e[0;33m-target[0m		Name of the target to prepare environment for. Ortc or WebRtc. If this parameter is not set dev environment will be prepared for both available targets."
  ECHO.
  printf "\e[0;33m-platform[0m 	Platform name to set environment for. Default is All (win32,x86,x64,arm)"
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

precheck()
{
  spacePattern=" |'"
  if [[ $pwd =~ $pattern ]]
  then
    error 1 "Path must not contain folders with spaces in name"
  fi

  binDir=..\bin
  if [ -d $binDir ];
  then
	 error 1 "Do not run scripts from bin directory!"
 fi
}

checkOrtcAvailability()
{
  binDir=.\ortc
  if [ -d $binDir ];
  then
     ortcAvailable=1
  fi
}

identifyTarget()
{
  validInput=0
  if [ "$target" == "all" ];
  then
    prepare_ORTC_Environemnt=$ortcAvailable
    prepare_WebRTC_Environemnt=1
    validInput=1
    if [ $prepare_ORTC_Environemnt -eq 1];
    then
      messageText=Preparing webRTC and ORTC development environment ...
    else
      messageText=Preparing webRTC development environment ...
    fi
  elif [ "$target" == "webrtc" ];
    prepare_WebRTC_Environemnt=1
    validInput=1
    messageText=Preparing $target development environment ...
  elif [ "$target" == "ortc" ];
    if [ $ortcAvailable -eq 0 ];
    then
      prepare_WebRTC_Environemnt=1
      validInput=1
      messageText=Preparing $target development environment ...
    fi
  else
    error 1 "Invalid target"
  fi

  CALL:print $warning $messageText
}

identifyPlatform()
{
  validInput=0

  if [ "$platform" == "all" ];
  then
	  platform_iOS=1
	  platform_macOS=1
	  validInput=1
	  messageText=Preparing development environment for iOS and macOS platforms ...
  elif [ "$platform" == "iOS" ];
	  platform_iOS=1
		validInput=1
    messageText=Preparing development environment for $platform platform...
  elif [ "$platform" == "macOS" ]
    platform_macOS=1
    validInput=1
    messageText=Preparing development environment for $platform platform...
  else
    error 1 "Invalid platform"
  fi

  CALL:print $warning $messageText
}

print $info "Running prepare script ..."

if [ -z "$VAR" ];
then
	print $warning "Running script with default parameters: "
	print $warning "Target: all ^(Ortc and WebRtc^)"
	print $warning "Platform: all ^(Mac OS and iOS)"
	print $warning "Log level: %logLevel% ^(warning^)"
	defaultProperties=1
fi

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
        help
        exit 1
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

#Main flow
precheck
checkOrtcAvailability

:main

::Determine targeted platforms
CALL:identifyPlatform

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
