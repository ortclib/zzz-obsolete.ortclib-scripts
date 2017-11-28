#!/bin/bash

set -e


target=webrtc
platform=all
configuration=debug
architecture=all
merge=1
logLevel=2
################
target_webrtc=0
target_ortc=0

platform_iOS=0
platform_macOS=0
platform_linux=0
platform_android=0

configuration_Release=0
configuration_Debug=0

architecture_arm=0
architecture_armv7=0
architecture_arm64=0
architecture_x86=0
architecture_x64=0

#log levels
error=0
info=1
warning=2
debug=3
trace=4
################

HOST_SYSTEM=mac
HOST_OS=osx

basePath="webrtc/xplatform/webrtc/out"
ninjaExe="webrtc/xplatform/depot_tools/ninja"
webrtcLibPath=obj/webrtc/libwebrtc.a
ortcLibPath=libortclib.dylib

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

identifyPlatform()
{
  print $trace "Identifying target platforms ..."
  if [ "$platform" == "all" ]; then
    if [ "$HOST_SYSTEM" == "linux" ]; then
      platform_linux=1
      platform_android=1
      platform_iOS=0
      platform_macOS=0
      messageText="WebRtc will be built for linux and android platforms ..."
    else
      platform_iOS=1
      platform_macOS=1
      platform_linux=0
      platform_android=0
      messageText="WebRtc will be built for iOS and macOS platforms ..."
    fi
  elif [ "$platform" == "ios" ]; then
    platform_iOS=1
    platform_macOS=0
    platform_linux=0
    platform_android=0
    messageText="WebRtc will be built for $platform platform..."
  elif [ "$platform" == "mac" ]; then
    platform_macOS=1
    platform_iOS=0
    platform_linux=0
    platform_android=0
    messageText="WebRtc will be built for $platform platform..."
  elif [ "$platform" == "linux" ]; then
    platform_linux=1
    platform_macOS=0
    platform_iOS=0
    platform_android=0
    messageText="WebRtc will be built for $platform platform..."
  elif [ "$platform" == "android" ]; then
    platform_android=1
    platform_linux=0
    platform_macOS=0
    platform_iOS=0
    messageText="WebRtc will be built for $platform platform..."
  else
    error 1 "Invalid platform"
  fi

  print $warning "$messageText"
}

identifyConfiguration()
{
  print $trace "Identifying target configuration ..."

  if [ "$configuration" == "all" ]; then
    configuration_Release=1
    configuration_Debug=1
  elif [ "$configuration" == "release" ]; then
    configuration_Release=1
    configuration_Debug=0
  else
    configuration_Release=0
    configuration_Debug=1
  fi
}

identifyArchitecture()
{
  print $trace "Identifying target architecture ..."
  if [ $platform_iOS -eq 1 ] || [ $platform_android -eq 1 ]; then
    if [ "$architecture" == "all" ]; then
      architecture_arm=1
      architecture_arm64=1
    elif [ "$architecture" == "arm" ]; then
      architecture_arm=1
      architecture_arm64=0
    elif [ "$architecture" == "arm64" ]; then
      architecture_arm=0
      architecture_arm64=1
    fi
  fi

  if [ $platform_macOS -eq 1 ] || [ $platform_linux -eq 1 ]; then
    if [ "$architecture" == "all" ]; then
      architecture_x86=1
      architecture_x64=1
    elif [ "$architecture" == "x86" ]; then
      architecture_x86=1
      architecture_x64=0
    elif [ "$architecture" == "x64" ]; then
      architecture_x86=0
      architecture_x64=1
    fi
  fi
}

identifyTarget()
{
  print $trace "Identifying target ..."

  if [ "$target" == "all" ]; then
    target_webrtc=1
    target_ortc=1
  elif [ "$target" == "ortc" ]; then
    target_webrtc=0
    target_ortc=1
  else
    target_webrtc=1
    target_ortc=0
  fi
}

buildTarget()
{
  targetPath=$basePath/$1_$2_$3
  print $debug "Buidling $4 in $targetPath ..."
  $ninjaExe -C $targetPath $4
}
buildConfiguration()
{
  if [ $target_webrtc -eq 1 ]; then
    buildTarget $1 $2 $3 webrtc
  fi

  if [ $target_ortc -eq 1 ]; then
    buildTarget $1 $2 $3 ortc
  fi
}
buildArchitecture()
{
  if [ $configuration_Release -eq 1 ]; then
    buildConfiguration $1 $2 release
  fi

  if [ $configuration_Debug -eq 1 ]; then
    buildConfiguration $1 $2 debug
  fi
}
buildPlatform()
{
  print $debug "Building for platform $1"
  if [ "$1" == "ios" ] || [ "$1" == "android" ]; then
    if [ $architecture_arm -eq 1 ]; then
      buildArchitecture $1 arm
    fi

    if [ $architecture_arm64 -eq 1 ]; then
      buildArchitecture $1 arm64
    fi
  fi

  if [ "$1" == "mac" ] || [ "$1" == "linux" ]; then
    if [ $architecture_x86 -eq 1 ]; then
      buildArchitecture $1 x86
    fi

    if [ $architecture_x64 -eq 1 ]; then
      buildArchitecture $1 x64
    fi
  fi
}
build()
{
  if [ $platform_iOS -eq 1 ]; then
    buildPlatform ios
  fi

  if [ $platform_macOS -eq 1 ]; then
    buildPlatform mac
  fi

  if [ $platform_linux -eq 1 ]; then
    buildPlatform linux
  fi

  if [ $platform_android -eq 1 ]; then
    buildPlatform android
  fi
}

runLipo()
{
  print $debug "Merging $1 and $2 to $3 ..."
  lipo -create $1 $2 -output $3
    if [ $? -ne 0 ]; then
      error 1 "Could not merge in #3 lib"
    fi
}

mergeConfiguration()
{
  print $trace "Running merge for  $1 $2 $3"
  if [ $platform_iOS -eq 1 ]; then
      if [ -f $basePath/ios_arm_$1/$2 ] && [ -f $basePath/ios_arm64_$1/$2 ]; then
        make_directory webrtc/xplatform/webrtc/out_ios_$1
        if [ "$3" == "webrtc" ]; then 
          runLipo $basePath/ios_arm_$1/$2 $basePath/ios_arm64_$1/$2 webrtc/xplatform/webrtc/out_ios_$1/$3.a
        fi

        if [ "$3" == "ortc" ]; then 
          runLipo $basePath/ios_arm_$1/$2 $basePath/ios_arm64_$1/$2 webrtc/xplatform/webrtc/out_ios_$1/$3.dylib
        fi

      fi
  fi
}
mergeTarget()
{ 
  if [ $configuration_Release -eq 1 ]; then
    mergeConfiguration release $1 $2
  fi

  if [ $configuration_Debug -eq 1 ]; then
    mergeConfiguration debug $1 $2
  fi
}
mergeLibs()
{
  print $debug "Merging libs ..."
  if [ $target_webrtc -eq 1 ]; then
    mergeTarget $webrtcLibPath webrtc
  fi

  if [ $target_ortc -eq 1 ]; then
    mergeTarget $ortcLibPath ortc
  fi
}

make_directory()
{
	if [ ! -d "$1" ]; then
		print $trace "Creating directory \"$1\"..."
		mkdir -p $1
    if [ $? -ne 0 ]; then
      error 1 "Failed creating $1 directory"
    fi
	fi
}

print()
{
  logType=$1
  logMessage=$2

  if [ $logLevel -eq $logType ] || [ $logLevel -gt $logType ]
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
    print $error "FAILURE:Preparing WebRtc environment has failed!"
    echo
    popd > /dev/null
    exit 1
  fi
}

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
    -target|-t)
        target=$2
        shift 2
        ;;
    -configuration|-c)
        configuration=$2
        shift 2
        ;;
    -architecture|-a)
        architecture=$2
        shift 2
        ;;
    -merge|-m)
        merge=1
        shift 1
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
    *)
        error 1 "Command line argument was not understood"
  esac
done

systemcheck

identifyPlatform
identifyConfiguration
identifyArchitecture
identifyTarget

build
if [ $merge -eq 1 ]; then
  mergeLibs
fi