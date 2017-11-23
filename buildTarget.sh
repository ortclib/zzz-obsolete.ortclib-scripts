#!/bin/bash

set -e

merge=1
target_webrtc=1
target_ortc=0
configuration=debug

TARGET_CPU_arm=0
TARGET_CPU_armv7=0
TARGET_CPU_arm64=0
TARGET_CPU_x86=0
TARGET_CPU_x64=1

configuration_Release=0
configuration_Debug=1

HOST_SYSTEM=mac
HOST_OS=osx

platform_iOS=1
platform_macOS=0
platform_linux=0
platform_android=0

configuration_release=0
configuration_debug=1

error=0
info=1
warning=2
debug=3
trace=4

basePath="webrtc/xplatform/webrtc/out"
ninjaExe="webrtc/xplatform/depot_tools/ninja"
webrtcLibPath=obj/webrtc/libwebrtc.a
ortcLibPath=ortclib.dylib
identifyPlatform()
{
  validInput=0

  if [ "$platform" == "all" ]; then
    if [ "$HOST_SYSTEM" == "linux" ]; then
      platform_linux=1
      platform_android=1
      messageText="WebRtc will be built for linux and android platforms ..."
    else
      platform_iOS=1
      platform_macOS=1
      messageText="WebRtc will be built for iOS and macOS platforms ..."
    fi
    validInput=1
  elif [ "$platform" == "iOS" ]; then
    platform_iOS=1
    validInput=1
    messageText="WebRtc will be built for $platform platform..."
  elif [ "$platform" == "macOS" ]; then
    platform_macOS=1
    validInput=1
    messageText="WebRtc will be built for $platform platform..."
  elif [ "$platform" == "linux" ]; then
    platform_linux=1
    validInput=1
    messageText="WebRtc will be built for $platform platform..."
  elif [ "$platform" == "android" ]; then
    platform_android=1
    validInput=1
    messageText="WebRtc will be built for $platform platform..."
  else
    error 1 "Invalid platform"
  fi

  print $warning "$messageText"
}

identifyConfiguration()
{
  shopt -s nocasematch
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
  shopt -u nocasematch
}

identifyArchitecture()
{
  shopt -s nocasematch
  
  if [ "$platform" == "iOS" ]; then
    if [ "$architecture" == "all" ]; then
      TARGET_CPU_arm=1
      TARGET_CPU_arm64=1
    elif [ "$architecture" == "arm" ]; then
      TARGET_CPU_arm=1
      TARGET_CPU_arm64=0
    elif [ "$architecture" == "arm64" ]; then
      TARGET_CPU_arm=0
      TARGET_CPU_arm64=1
    fi
  fi

  if [ "$platform" == "macOS" ] || [ "$platform" == "linux" ]; then
    if [ "$architecture" == "all" ]; then
      TARGET_CPU_x86=1
      TARGET_CPU_x64=1
    elif [ "$architecture" == "x86" ]; then
      TARGET_CPU_x86=1
      TARGET_CPU_x64=0
    elif [ "$architecture" == "x64" ]; then
      TARGET_CPU_x86=0
      TARGET_CPU_x64=1
    fi
  fi
  shopt -u nocasematch
}

identifyTarget()
{
  shopt -s nocasematch
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
  shopt -u nocasematch
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
  if [ $TARGET_CPU_arm -eq 1]; then
    buildArchitecture $1 arm
  fi

  if [ $TARGET_CPU_arm64 -eq 1]; then
    buildArchitecture $1 arm64
  fi

  if [ $TARGET_CPU_x86 -eq 1]; then
    buildArchitecture $1 x86
  fi

  if [ $TARGET_CPU_x64 -eq 1]; then
    buildArchitecture $1 x64
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
  if [ $platform_iOS -eq 1 ]; then
      if [ -f "$basePath/ios_arm_$1/$2" ] && [ -f "$basePath/ios_arm64_$1/$2" ]; then
        make_directory "webrtc/xplatform/webrtc/out_ios_$1"
        runLipo $basePath/ios_arm_$1/$2" $basePath/ios_arm64_$1/$2 webrtc/xplatform/webrtc/out_ios_$1/$3.a
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
merge()
{
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
		echo "Creating directory \"$1\"..."
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

build_webrtc()
{
  webrtc/xplatform/depot_tools/ninja -C "webrtc/xplatform/webrtc/out/ios_$1_$2" webrtc
  if [ $? -ne 0 ]; then
    error 1 "Could not build WebRTC projects for %1 platform, %2 configuration"
  fi
}

merge_arm_libs()
{
  if [ -f "webrtc/xplatform/webrtc/out/ios_arm_$1/obj/webrtc/libwebrtc.a" ] && [ -f "webrtc/xplatform/webrtc/out/ios_arm64_$1/obj/webrtc/libwebrtc.a" ]; then
    make_directory "webrtc/xplatform/webrtc/out_ios_$1"
    if [ $? -ne 0 ]; then
      error 1 "Could not make directory webrtc/xplatform/webrtc/out_ios_$1"
    fi

    lipo -create "webrtc/xplatform/webrtc/out/ios_arm_$1/obj/webrtc/libwebrtc.a" "webrtc/xplatform/webrtc/out/ios_arm64_$1/obj/webrtc/libwebrtc.a" -output "webrtc/xplatform/webrtc/out_ios_$1/webrtc.a"
    if [ $? -ne 0 ]; then
      error 1 "Could not merge arm and arm64 webrtc libs"
    fi
  else
    error 1 "Could not merge arm and arm64 webrtc libs because they do not exist"
  fi
}

merge_libs_with_different_arch()
{
  if [ -d "$inputFolderPath1" ] && [ -d "$inputFolderPath2" ]; then
    make_directory $outputFolderPath
    for f in $(find $inputFolderPath1 -name '*.a'); do
      filename=$(basename "${f}")
      echo filename: $filename
      echo CHECKING $inputFolderPath2/$filename
      if [ -f $inputFolderPath2/$filename ]; then
        echo filename: MERGING  $filename
        lipo -create $f $inputFolderPath2/$filename -output $outputFolderPath/$filename
      else
        echo filename 1: COPYING $filename
        cp $f $outputFolderPath
      fi
    done

    for f in $(find $inputFolderPath2 -name '*.a'); do
      filename=$(basename "${f}")
      if [ ! -f $inputFolderPath1/$filename ]; then
        echo filename 2: COPYING $filename
        cp $f $outputFolderPath
      fi
    done
  fi
}

make_fat_webrtc()
{
  make_directory $outputLibFolderPath
  if [ -d "$outputFolderPath" ]; then
    libtool -static -o $outputLibFolderPath/webrtc.a $outputFolderPath/*.a
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
        exit 1
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

identifyPlatform()
identifyConfiguration()
identifyArchitecture()
identifyTarget()

build()
merge()
#build_webrtc arm Debug
#build_webrtc arm64 Debug
#build_webrtc arm Release
#build_webrtc arm64 Release
#merge_arm_libs release
#merge_libs_with_different_arch
#make_fat_webrtc
