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
logLevel=4

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

platform_iOS=0
platform_macOS=0
platform_linux=0
platform_android=0

HOST_SYSTEM=mac
HOST_OS=osx

webrtcGnPath="webrtc/xplatform/webrtc"
ortcGnPath="webrtc/xplatform/webrtc/ortc"
webrtcGnBuildPath="ortc/xplatform/templates/gn/webRtcBUILD.gn"
webrtcGnBuildPathDestination="webrtc/xplatform/webrtc/BUILD.gn"
ortcGnBuildPath="ortc/xplatform/templates/gn/ortcBUILD.gn"
ortcGnBuildPathDestination="webrtc/xplatform/webrtc/ortc/BUILD.gn"

libCxxGnBuildTemplatePath="ortc/xplatform/templates/gn/libc++/BUILD.gn"
libCxxGnBuildPathDestination="webrtc/xplatform/buildtools/third_party/libc++/BUILD.gn"
libCxxAbiGnBuildTemplatePath="ortc/xplatform/templates/gn/libc++abi/BUILD.gn"
libCxxAbiGnBuildPathDestination="webrtc/xplatform/buildtools/third_party/libc++abi/BUILD.gn"

gnEventingPythonScriptSource="bin/runEventCompiler.py"
gnEventingPythonScriptDestination="webrtc/xplatform/webrtc/ortc/runEventCompiler.py"
gnIDLPythonScriptSource="bin/runIDLCompiler.py"
gnIDLPythonScriptDestination="webrtc/xplatform/webrtc/ortc/runIDLCompiler.py"
print()
{
  logType=$1
  logMessage=$2

  if [ $logLevel -eq  $logType ] || [ $logLevel -gt  $logType ]
  then
    if [ $logType -eq 0 ]
    then
      printf "\e[0;31m $logMessage \e[m\n"
    fi
    if [ $logType -eq 1 ]
    then
      printf "\e[0;32m $logMessage \e[m\n"
    fi
    if [ $logType -eq 2 ]
    then
      printf "\e[0;33m $logMessage \e[m\n"
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
  printf "\e[0;32m prepare.sh help \e[m\n"
  echo
  printf "\e[0;32m Available parameters: \e[m\n"
  echo
  printf "\e[0;33m-h\e[0m   Show script usage"
  echo
  printf "\e[0;33m-l\e[0m  Log level (error=0, info =1, warning=2, debug=3, trace=4)"
  echo
  printf "\e[0;33m-n\e[0m   Flag not to run eventing preparations for Ortc"
  echo
  printf "\e[0;33m-t\e[0m  Name of the target to prepare environment for. Ortc or WebRtc. If this parameter is not set, dev environment will be prepared for both available targets."
  echo
  printf "\e[0;33m-p\e[0m   Platform name to set environment for. Default is All (win32,x86,x64,arm)"
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
#cleanup
    exit 1
  fi
}

path_remove() {
  PATH=${PATH/":$1"/} # delete any instances in the middle or at the end
  PATH=${PATH/"$1:"/} # delete any instances at the beginning
  print $trace "new tmp path: $PATH"
}

depotToolsPathCheck(){

for file in $(echo $PATH | tr ":" "\n"); do
    if [ -f $file/depot-tools-auth* ]
        then
            print $trace "found $file"
            path_remove $file
            numberOfRemoved=$((numberOfRemoved+1))
            print $trace "numberOfRemoved $numberOfRemoved"
    fi
done

}


finished()
{
  if [ $result -gt 0 ]
  then
    PATH=$oldPath
    print $trace "restored path=$PATH"
  fi

  echo
  print $info "Success: Development environment is set."
  echo
#cleanup
}

systemcheck()
{
  if [ "$OSTYPE" == "linux-gnu" ];
  then
    HOST_SYSTEM=linux
    HOST_OS=$(lsb_release -si | awk '{print tolower($0)}')
    HOST_ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
    HOST_VER=$(lsb_release -sr)
  fi
}

precheck()
{
  if [[ $pwd == *" "* ]]; then
    error 1 "Path must not contain folders with spaces in name"
  fi

  binDir=..\bin
  if [ -d $binDir ]; then
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

  if [ "$platform" == "all" ]; then
    if [ "$HOST_SYSTEM" == "linux" ]; then
      platform_linux=1
      platform_android=1
      messageText="Preparing development environment for linux and android platforms ..."
    else
      platform_iOS=1
      platform_macOS=1
      messageText="Preparing development environment for iOS and macOS platforms ..."
    fi
    validInput=1
  elif [ "$platform" == "iOS" ]; then
    platform_iOS=1
    validInput=1
    messageText="Preparing development environment for $platform platform..."
  elif [ "$platform" == "macOS" ]; then
    platform_macOS=1
    validInput=1
    messageText="Preparing development environment for $platform platform..."
  elif [ "$platform" == "linux" ]; then
    platform_linux=1
    validInput=1
    messageText="Preparing development environment for $platform platform..."
  elif [ "$platform" == "android" ]; then
    platform_android=1
    validInput=1
    messageText="Preparing development environment for $platform platform..."
  else
    error 1 "Invalid platform"
  fi

  print $warning "$messageText"
}

identifyLogLevel()
{
  if [ $logLevel -eq $error ]; then
    print $warning "LogLevel is set to error"
  elif [ $logLevel -eq $info ]; then
    print $warning "LogLevel is set to info"
  elif [ $logLevel -eq $warning ]; then
    print $warning "LogLevel is set to warning"
  elif [ $logLevel -eq $debug ]; then
    print $warning "LogLevel is set to debug"
  elif [ $logLevel -eq $trace ]; then
    print $warning "LogLevel is set to trace"
  else
    error 1 "Invalid logLevel"
  fi
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
      mkdir -p $NINJA_PATH                            && \
      pushd $NINJA_PATH                              && \
      curl -L0k $NINJA_URL >  $NINJA_ZIP_FILE      && \
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
  #NINJA_PATH_TO_REPLACE_WITH=$NINJA_PATH_TO_USE
  ./bin/prepareWebRtc.sh -p $platform -l $logLevel
}

prepareORTC()
{
  print $debug "Preparing Ortc..."

  if [ "$HOST_SYSTEM" != "linux" ]; then
    prepareCurl
    if [ "$noEventing" != "1" ]; then
      prepareEventing
    fi
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

cleanup()
{
  if [ -f "$webrtcGnPath/originalBuild.gn" ]
  then
    rm -f $webrtcGnPath/BUILD.gn
    mv $webrtcGnPath/originalBuild.gn $webrtcGnPath/BUILD.gn
  else
    echo "File $webrtcGnPath/originalBuild.gn does not exist."
  fi
}

makeDirectory()
{
  TARGET=$1
  if [ ! -d $TARGET ]; then
    print $debug "Creating folder $TARGET"
    mkdir -p $TARGET
  fi
  if [ ! -d $TARGET ]; then
    error 1 "(makeDirectory): Unable to create folder $TARGET"
  fi

}

makeLink()
{
  print $debug "Preparing webrtc paths symbolic links for \"$2\" pointing to \"$3\""
  if [ ! -d "$1" ]; then
    error 1 "Path to link does not exist \"$1\" !"
  fi

  pushd $1 > /dev/null

  if [ ! -d "$3" ]; then
    error 1 "Link destination is not found \"$3\" inside \"$1\" !"
  fi

  if [ ! -h "$2" ]; then
    print $debug "In path \"$1\" creating webrtc symbolic link \"$2\" pointing to \"$3\"..."
    #ln -s $3 $2

    linkName=$(python -c "import os.path; print os.path.split('$2')[1]")
    linkPath=$(python -c "import os.path; print os.path.split('$2')[0]")
    linkAbsPath=$(python -c "import os.path; print os.path.abspath('$3')")
     #relPath=$(python -c "import os.path; print os.path.relpath('$3', '$linkPath')")

    if [ -z "$linkPath" ]; then
      linkPath="."
    fi

    if [ ! -d "$linkPath" ]; then
      error 1 "Link path does not exist: $linkPath"
    fi

     ln -s $linkAbsPath $2

    if [ $? -ne 0 ]; then
      failure=$?
      error 1 "Failed to create symbolic link: ln -s $linkAbsPath $2"
    fi
  fi

  popd > /dev/null
}

prepareGN()
{

#  cleanup

  makeDirectory "$ortcGnPath"

#  mv $webrtcGnPath/BUILD.gn $webrtcGnPath/originalBuild.gn

  yes | cp $webrtcGnBuildPath $webrtcGnBuildPathDestination
  yes | cp $ortcGnBuildPath $ortcGnBuildPathDestination

  yes | cp -rf $libCxxGnBuildTemplatePath $libCxxGnBuildPathDestination
  yes | cp -rf $libCxxAbiGnBuildTemplatePath $libCxxAbiGnBuildPathDestination

  print $info "In path $(pwd) creating symbolic link ortc/xplatform/udns to webrtc/xplatform/webrtc/ortc/udns"
 #ln -s $(pwd)"/ortc/xplatform/udns" $(pwd)"/webrtc/xplatform/webrtc/ortc/udns"
  makeLink "." "$webrtcGnPath/ortc/udns" "./ortc/xplatform/udns"
  makeLink "." "$webrtcGnPath/ortc/idnkit" "./ortc/xplatform/idnkit"
  makeLink "." "$webrtcGnPath/ortc/cryptopp" "./ortc/xplatform/cryptopp"
  makeLink "." "$webrtcGnPath/ortc/ortclib" "./ortc/xplatform/ortclib-cpp"
  makeLink "." "$webrtcGnPath/ortc/ortclib-services" "./ortc/xplatform/ortclib-services-cpp"
  makeLink "." "$webrtcGnPath/ortc/zsLib" "./ortc/xplatform/zsLib"
  makeLink "." "$webrtcGnPath/ortc/zsLib-eventing" "./ortc/xplatform/zsLib-eventing"
  makeLink "." "$webrtcGnPath/ortc/curl" "./ortc/xplatform/curl"
}



#platform;target;help;logLevel;noEventing;
while true;
do
  tempParam=$(echo $1 | awk '{print tolower($0)}')
  case "$tempParam" in
    "")
        break;;
    -platform|-p)
        platform=$2
        shift 2
        ;;
    -target|t)
        target=$2
        shift 2
        ;;
    -help|-h)
        help
        exit 1
        ;;
    -loglevel|-l)
        logLevel=$2
        if [ "$2" == "error" ]; then
          logLevel=0
        elif [ "$2" == "info" ]; then
          logLevel=1
        elif [ "$2" == "warning" ]; then
          logLevel=2
        elif [ "$2" == "debug" ]; then
          logLevel=3
        elif [ "$2" == "trace" ]; then
          logLevel=4
        fi
        shift 2
        ;;
    -noeventing|-n)
        noEventing=1
        shift
        ;;
    *)
        error 1 "Command line argument was not understood"
  esac
done

print $info "Running prepare script ..."

systemcheck

print $warning "Running script with following parameters: "
print $warning "Target: $target"
print $warning "Platform: $platform"
print $warning "LogLevel: $logLevel"
if [ noEventing == 1 ]; then
  print $warning "Eventing: false"
else
  print $warning "Eventing: true"
fi


#Main flow

precheck
print $info "Running on $HOST_SYSTEM $HOST_OS $HOST_ARCH $HOST_VER ..."

checkOrtcAvailability

identifyTarget
identifyPlatform
identifyLogLevel

##installNinja

numberOfRemoved=0
oldPath=$(echo $PATH)
print $trace "oldPath=$oldPath"
depotToolsPathCheck
result=$numberOfRemoved
print $trace "Number of paths temporarily removed from environment PATH:=$result"

if [ $prepare_ORTC_Environemnt -eq 1 ];
then
  prepareGN
  cp $gnEventingPythonScriptSource $gnEventingPythonScriptDestination
  cp $gnIDLPythonScriptSource $gnIDLPythonScriptDestination
fi

prepareWebRTC



if [ $prepare_ORTC_Environemnt -eq 1 ];
then
  prepareORTC
fi

finished
