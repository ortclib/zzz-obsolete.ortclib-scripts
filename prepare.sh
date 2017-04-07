# Name:      prepare.bat
# Purpose:   Prepare development environment for ORTC and WebRTC
# Author:    Sergej Jovanovic
# Email:     sergej@gnedo.com
# Twitter:   @JovanovicSergej
# Revision:  March 2017 - initial version
#!/bin/bash

set -e

#input arguments
target=all
platform=all
ortcAvailable=0
logLevel=2

#log levels
error=0
info=1
warning=2
debug=3
trace=4

NINJA_PATH=./bin/ninja/
NINJA_PATH_TO_USE=""
NINJA_URL="https://github.com/ninja-build/ninja/releases/download/v1.7.2/ninja-mac.zip"
NINJA_ZIP_FILE="ninja-mac.zip"

CURL_PATH=./ortc/xplatform/curl/

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
  printf "\e[0;32m prepare.sh help \e[m\n"
  echo
  printf "\e[0;32m Available parameters: \e[m\n"
  echo
  printf "\e[0;33m-h[0m 	Show script usage"
  echo
  printf "\e[0;33m-l[0m	Log level (error=0, info =1, warning=2, debug=3, trace=4)"
  echo
  printf "\e[0;33m-n[0m 	Flag not to run eventing preparations for Ortc"
  echo
  printf "\e[0;33m-t[0m	Name of the target to prepare environment for. Ortc or WebRtc. If this parameter is not set, dev environment will be prepared for both available targets."
  echo
  printf "\e[0;33m-p[0m 	Platform name to set environment for. Default is All (win32,x86,x64,arm)"
  echo
  echo
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

  print $warning "$messageText"
}

identifyPlatform()
{
  validInput=0

  if [ "$platform" == "all" ];
  then
	  platform_iOS=1
	  platform_macOS=1
	  validInput=1
	  messageText="Preparing development environment for iOS and macOS platforms ..."
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
  NINJA_PATH_TO_REPLACE_WITH=$NINJA_PATH_TO_USE ./bin/prepareWebRtc.sh -p $platform -l $logLevel
}

prepareORTC()
{
  print $debug "Preparing Ortc..."
  
  prepareCurl
  if [ "$noEventing" != "1" ]; then
  	prepareEventing
  fi
}

prepareCurl()
{
  pushd $CURL_PATH > /dev/null
  sh prepareCurl.sh $TARGET
  popd > /dev/null
}

prepareEventing()
{
  ./bin/prepareEventing.sh -l $logLevel
}

#platform;target;help;logLevel;noEventing;
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
    n)
        noEventing=1
        ;;
    esac
done

print $info "Running prepare script ..."

print $warning "Running script with following parameters: "
print $warning "Target: all (Ortc and WebRtc)"
print $warning "Platform: all (Mac OS and iOS)"
print $warning "Log level: $logLevel (warning)"


#Main flow
precheck

checkOrtcAvailability

identifyTarget

#identifyPlatform
installNinja

prepareWebRTC

if [ $prepare_ORTC_Environemnt -eq 1 ];
then
  prepareORTC
fi

finished
