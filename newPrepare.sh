#!/bin/bash

set -e

target=all
platform=iOS
ortcAvailable=0
logLevel=2
#log levels
globalLogLevel=2
error=0
info=1
warning=2
debug=3
trace=4

NINJA_PATH=./bin/ninja/
NINJA_PATH_TO_USE=""
#NINJA_URL="http://github.com/martine/ninja/releases/download/v1.6.0/ninja-mac.zip"
NINJA_URL="https://github.com/ninja-build/ninja/releases/download/v1.7.2/ninja-mac.zip"
NINJA_ZIP_FILE="ninja-mac.zip"

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
      printf "\e[0;33m $logMessage \e[m\n"
    fi
    if [ $logType -gt 2 ]
    then
      echo $logMessage
    fi
  fi
}

help()
{
  echo
  printf "\e[0;32m Available parameters: \e[m\n"
  echo
  printf "\e[0;33m-diagnostic\e[m		Flag for runing check if system is ready for webrtc development."
  echo
  printf "\e[0;33m-help[0m 		Show script usage"
  echo
  printf "\e[0;33m-logLevel[0m	Log level (error=0, info =1, warning=2, debug=3, trace=4)"
  echo
  printf "\e[0;33m-noEventing[0m 	Flag not to run eventing preparations for Ortc"
  echo
  printf "\e[0;33m-target[0m		Name of the target to prepare environment for. Ortc or WebRtc. If this parameter is not set dev environment will be prepared for both available targets."
  echo
  printf "\e[0;33m-platform[0m 	Platform name to set environment for. Default is All (win32,x86,x64,arm)"
  echo
  exit 1
}

error()
{
  criticalError=$1
  errorMessage=$2

  if [ $criticalError -eq 0 ]
  then
  	echo
  	print $warning "WARNING: $errorMessage"
  	echo
  else
  	echo
    print $error "CRITICAL ERROR: $errorMessage"
  	echo
  	echo
  	print $error "FAILURE:Preparing environment has failed!"
  	echo
  	#SET endTime=%time%
  	#CALL:showTime
  	::terminate batch execution
  	exit 1
  fi
}

finished()
{
  echo
  print $info "Success: Development environment is set."
  echo
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
  binDir=./ortc
  if [ -d $binDir ];
  then
     ortcAvailable=1
   else
     ortcAvailable=0
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
    if [ $prepare_ORTC_Environemnt -eq 1 ];
    then
      messageText="Preparing webRTC and ORTC development environment ..."
    else
      messageText="Preparing webRTC development environment ..."
    fi
  elif [ "$target" == "webrtc" ]; then
    prepare_WebRTC_Environemnt=1
    validInput=1
    messageText="Preparing $target development environment ..."
  elif [ "$target" == "ortc" ]; then
    if [ $ortcAvailable -eq 0 ];
    then
      prepare_WebRTC_Environemnt=1
      validInput=1
      messageText="Preparing $target development environment ..."
    fi
  else
    error 1 "Invalid target"
  fi

  printf $messageText

  print $warning $messageText
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
  elif [ "$platform" == "iOS" ]; then
	  platform_iOS=1
		validInput=1
    messageText="Preparing development environment for $platform platform..."
  elif [ "$platform" == "macOS" ]; then
    platform_macOS=1
    validInput=1
    messageText="Preparing development environment for $platform platform..."
  else
    error 1 "Invalid platform"
  fi

  print $warning $messageText
}

installNinja()
{
	print $debug "Ninja check"

	if  hash ninja 2>/dev/null; then
		print $debug "Ninja is present in the PATH"
		EXISTING_NINJA_PATH="$(which ninja)"
	else
		if [ -f "$NINJA_PATH/ninja" ]; then
			print $debug "Ninja already installed"
			NINJA_PATH_TO_USE="..\/..\/..\/bin\/ninja"
			print $debug "ninja path: $NINJA_PATH_TO_USE"
		else
			print $warning "Downloading ninja from to $PWD"
			mkdir -p $NINJA_PATH                        		&& \
			pushd $NINJA_PATH                          		&& \
			curl -L0k $NINJA_URL >  $NINJA_ZIP_FILE			&& \
			unzip $NINJA_ZIP_FILE                       && \
			rm $NINJA_ZIP_FILE
			popd
			NINJA_PATH_TO_USE="..\/..\/..\/bin\/ninja"
			print $debug "ninja path: $NINJA_PATH_TO_USE"
		fi
	fi
}

prepareWebRTC()
{
  NINJA_PATH_TO_REPLACE_WITH=$NINJA_PATH_TO_USE ./bin/newPrepareWebRtc.sh -p all

  #sh ./bin/newPrepareWebRtc.sh -p all
  #pushd ./webrtc/xvplatform/webrtc > /dev/null
  #prepare "libs/webrtc" "../../bin/prepare-webrtc.sh" "WebRTC"
  #CALL bin\prepareWebRtc.bat -platform %platform% -logLevel %logLevel%
  echo prepareWebRTC
}

prepareORTC()
{
  echo prepareORTC
# Copy webrtc solution template
#CALL:copyTemplates %ortcWebRTCTemplatePath% %ortcWebRTCDestinationPath%
}

prepareCurl()
{
  echo prepareCurl
}

prepareEventing()
{
  echo prepareEventing
}

print $info "Running prepare script ..."

if [ -z "$VAR" ];
then
	print $warning "Running script with default parameters: "
	print $warning "Target: all (Ortc and WebRtc)"
	print $warning "Platform: all (Mac OS and iOS)"
	print $warning "Log level: $logLevel (warning)"
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
identifyTarget
identifyPlatform
installNinja
prepareWebRTC

if [ $prepare_ORTC_Environemnt -eq 1 ];
then
  prepareORTC
  prepareCurl
  prepareEventing
fi

finished
