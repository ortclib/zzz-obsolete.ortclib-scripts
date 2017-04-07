#!/bin/bash

set -e

target=all
platform=all
logLevel=4
platform_iOS=0
platform_macOS=0

#log levels
error=0
info=1
warning=2
debug=3
trace=4

BUILD_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/build/
CHROMIUM_FOLDER_DESTINATION=../../chromium-pruned/
BORINGSSL_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/boringssl/src/
#COLORAMA_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/colorama/src/
JSONCPP_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/jsoncpp/source/
LIBJPEG_TURBO_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/libjpeg_turbo/

LIBSRTP_TURBO_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/libsrtp/
LIBVPX_TURBO_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/libvpx/source/libvpx/
LIBYUV_TURBO_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/libyuv/
OPENMAX_TURBO_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/openmax_dl/
OPUS_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/opus/src/

USRSCTP_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/usrsctp/usrsctplib/
PATCHED_YASM_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/yasm/source/patched-yasm/
YASM_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/yasm/binaries/
GYP_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/tools/gyp/
GTEST_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/testing/gtest/

GFLAGS_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/third_party/gflags/src/
GMOCK_FOLDER_CHROMIUM_DESTINATION=../chromium-pruned/testing/gmock/

BOGUS_EXPAT_PATH=../../../ortc/apple/templates/libs/bogus_gyps/bogus_expat.gyp
BOGUS_CLASS_DUMP_PATH=../../../ortc/apple/templates/libs/bogus_gyps/bogus_class-dump.gyp

NINJA_WRAPPER_IOS_PATH=../../../ortc/apple/templates/libs/webrtc/webrtcWrapper_ios.ninja
NINJA_WRAPPER_MAC_PATH=../../../ortc/apple/templates/libs/webrtc/webrtcWrapper_mac.ninja

SRC_FILES_PATH=./chromium/src
SRC_FILES_DESTINATION=../webrtc/chromium/src/

NINJA_PATH=../../../bin/ninja/
#NINJA_PATH_TO_REPLACE_WITH=""
NINJA_URL="http://github.com/martine/ninja/releases/download/v1.6.0/ninja-mac.zip"
NINJA_ZIP_FILE="ninja-mac.zip"

PROJECT_FILE=all.ninja.xcworkspace
PROJECT_MAC_FILE=all_osx.xcodeproj
PROJECT_IOS_FILE=all_ios.xcodeproj

OUTPUT_IOS=out_ios
OUTPUT_MAC=out_mac

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

  print $warning "$messageText"
}

copyFolder()
{
	SOURCE=$1
	TARGET=$2
	
	if [[ -n $SOURCE && -n $TARGET ]]; then
		if [ -d $SOURCE ]; then
			print $debug "Copying $SOURCE to $TARGET"
			mkdir -p $TARGET && cp -r $SOURCE $TARGET
		else
			error 1 "(copyFolder): Folder $SOURCE doesn't exist."
		fi
	else
		error 1 "(copyFolder): Missing source and destination folders"
	fi
}

makeFolderStructure()
{

	print $debug Creating folder structure

	#copyFolder ../build/ $BUILD_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../boringssl/ $BORINGSSL_FOLDER_CHROMIUM_DESTINATION
	#copyFolder ../colorama/ $COLORAMA_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../jsoncpp/ $JSONCPP_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../libjpeg_turbo/ $LIBJPEG_TURBO_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../libsrtp/ $LIBSRTP_TURBO_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../libvpx/ $LIBVPX_TURBO_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../libyuv/ $LIBYUV_TURBO_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../openmax/ $OPENMAX_TURBO_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../opus/ $OPUS_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../usrsctp/ $USRSCTP_FOLDER_CHROMIUM_DESTINATION

  copyFolder ../yasm/patched-yasm/ $PATCHED_YASM_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../yasm/binaries/ $YASM_FOLDER_CHROMIUM_DESTINATION

	copyFolder ../gyp/ $GYP_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../googletest/ $GTEST_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../gflags/ $GFLAGS_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../googlemock/ $GMOCK_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../chromium-pruned/ $SRC_FILES_DESTINATION

	print $warning "Finished creating folder structure"
}

removeFolder()
{
	SOURCE=$1

  print $trace "Trying to delete folder $SOURCE"

	if [ -n $SOURCE ]; then
		if [ -d $SOURCE ]; then
			print $trace "Removing folder $SOURCE"
			rm -r $SOURCE
      if [ $? -ne 0 ]; then
        error 0 "Failed deleting $SOURCE"
      fi
    else
      error 0 "$SOURCE is not a valid folder"
		fi
	else
		error 0 "removeFolder: Folder path is not provided."
	fi
}

removeFolderStructure()
{
	print $debug "Removing temporary folders"

	#removeFolder $BUILD_FOLDER_CHROMIUM_DESTINATION
	removeFolder $BORINGSSL_FOLDER_CHROMIUM_DESTINATION
	removeFolder $JSONCPP_FOLDER_CHROMIUM_DESTINATION
	removeFolder $LIBJPEG_TURBO_FOLDER_CHROMIUM_DESTINATION

	removeFolder $LIBSRTP_TURBO_FOLDER_CHROMIUM_DESTINATION
	removeFolder $LIBVPX_TURBO_FOLDER_CHROMIUM_DESTINATION
	removeFolder $LIBYUV_TURBO_FOLDER_CHROMIUM_DESTINATION
	removeFolder $OPENMAX_TURBO_FOLDER_CHROMIUM_DESTINATION
	removeFolder $OPUS_FOLDER_CHROMIUM_DESTINATION

	removeFolder $USRSCTP_FOLDER_CHROMIUM_DESTINATION
	removeFolder $PATCHED_YASM_FOLDER_CHROMIUM_DESTINATION
	removeFolder $YASM_FOLDER_CHROMIUM_DESTINATION
	removeFolder $GYP_FOLDER_CHROMIUM_DESTINATION
	removeFolder $GTEST_FOLDER_CHROMIUM_DESTINATION

	removeFolder $GFLAGS_FOLDER_CHROMIUM_DESTINATION
	removeFolder $GMOCK_FOLDER_CHROMIUM_DESTINATION
}

cleanPreviousResults()
{
	removeFolderStructure

	print $warning "Cleaning old data from $PWD"

	if [ -d "$PROJECT_FILE" ]; then
		print $debug "Deleting $PROJECT_FILE"
		rm -r $PROJECT_FILE
	fi

	if [ -d "$PROJECT_IOS_FILE" ]; then
		print $debug "Deleting $PROJECT_IOS_FILE"
		rm -r $PROJECT_IOS_FILE
	fi

	if [ -d "$PROJECT_MAC_FILE" ]; then
		print $debug "Deleting $PROJECT_MAC_FILE"
		rm -r $PROJECT_MAC_FILE
	fi

	if [ -d "$OUTPUT_IOS" ]; then
		print $debug "Deleting $OUTPUT_IOS"
		rm -r $OUTPUT_IOS
	fi

	if [ -d "$OUTPUT_MAC" ]; then
		print $debug "Deleting $OUTPUT_MAC"
		rm -r $OUTPUT_MAC
	fi

	#Check if it is a softlink
	if [[ -L "$SRC_FILES_PATH" && -d "$SRC_FILES_PATH" ]]; then
		print $debug "Removing src softlink"
		rm $SRC_FILES_PATH
	fi

	if [ -d "$SRC_FILES_PATH" ]; then
		print $debug "Deleting src folder"
		rm -r $SRC_FILES_PATH
	fi
}

setNinja()
{
	print $debug "Ninja check"

	if  hash ninja 2>/dev/null; then
		print $debug "Ninja is present in the PATH"
		EXISTING_NINJA_PATH="$(which ninja)"
	else
		if [ -f "$NINJA_PATH/ninja" ]; then
			print $debug "Ninja already installed"
			NINJA_PATH_TO_REPLACE_WITH="..\/..\/..\/bin\/ninja"
			print $debug "ninja path: $NINJA_PATH_TO_REPLACE_WITH"
		else
			print $debug "Downloading ninja to $PWD"
			mkdir -p $NINJA_PATH                        		&& \
			pushd $NINJA_PATH                          		&& \
			curl -L0k $NINJA_URL >  $NINJA_ZIP_FILE			&& \
			unzip $NINJA_ZIP_FILE                       && \
			rm $NINJA_ZIP_FILE
			popd
			NINJA_PATH_TO_REPLACE_WITH="..\/..\/..\/bin\/ninja"
			print $debug "ninja path: $NINJA_PATH_TO_REPLACE_WITH"
		fi
	fi
}

preparelink()
{
  print $debug "Preparing webrtc paths symbolic links for $3"
	if [ ! -d "$1" ]; then
		error 1 "Path to link does not exist \"$1\" !"
	fi

	pushd $1 > /dev/null

	if [ ! -d "$3" ]; then
		error 1 "Link destination is not found \"$3\" inside \"$1\" !"
	fi

	if [ ! -h "$2" ]; then
		print $debug "In path \"$1\" creating webrtc symbolic link \"$2\" pointing to \"$3\"..."
		ln -s $3 $2
		if [ $? -ne 0 ]; then
			failure=$?
			error 1 "Failed to create symbolic link"
		fi
	fi

	popd > /dev/null
}

makeLinks()
{
	print $warning "Creating soft links"

	preparelink "." "build" $BUILD_FOLDER_CHROMIUM_DESTINATION
	#preparelink "chromium" "src" $CHROMIUM_FOLDER_DESTINATION
	preparelink "." "testing" "chromium/src/testing"
	preparelink "tools" "protoc_wrapper" "../chromium/src/tools/protoc_wrapper"
	preparelink "tools" "gyp" "../chromium/src/tools/gyp"
	preparelink "tools" "clang" "../chromium/src/tools/clang"

	preparelink "third_party" "protobuf" "../chromium/src/third_party/protobuf"
	preparelink "third_party" "yasm" "../chromium/src/third_party/yasm"
	preparelink "third_party" "opus" "../chromium/src/third_party/opus"
	preparelink "third_party" "colorama" "../chromium/src/third_party/colorama"
	preparelink "third_party" "boringssl" "../chromium/src/third_party/boringssl"
	preparelink "third_party" "usrsctp" "../chromium/src/third_party/usrsctp"
	preparelink "third_party" "jsoncpp" "../chromium/src/third_party/jsoncpp"
	preparelink "third_party" "protobuf" "../chromium/src/third_party/protobuf"
	preparelink "third_party" "libsrtp" "../chromium/src/third_party/libsrtp"
	preparelink "third_party" "libvpx" "../chromium/src/third_party/libvpx"
	preparelink "third_party" "libyuv" "../chromium/src/third_party/libyuv"
	preparelink "third_party" "openmax_dl" "../chromium/src/third_party/openmax_dl"
	preparelink "third_party" "libjpeg_turbo" "../chromium/src/third_party/libjpeg_turbo"
	preparelink "third_party" "ocmock" "../chromium/src/third_party/ocmock"

  #preparelink "third_party" "expat" "../chromium/src/third_party/expat"
	preparelink "third_party/gflags" "src" "../../chromium/src/third_party/gflags/src"
}

make_directory()
{
	if [ ! -d "$1" ]; then
		print $trace "Creating directory \"$1\"..."
		mkdir -p $1
	fi
}

updateClang()
{
	print $warning "Running clang update ..."

  pushd "./chromium/src"  > /dev/null
	result=$(python tools/clang/scripts/update.py 2>&1)
  make_directory "third_party/llvm"
  popd  > /dev/null
	print $debug "$result"

	#preparelink "third_party" "llvm" "../chromium/src/third_party/llvm"
	#preparelink "third_party" "llvm-build" "../chromium/src/third_party/llvm-build"

}

setBogusGypFiles()
{
	print $warning "Placing bogus gyp files"

	make_directory "third_party/expat"
	cp $BOGUS_EXPAT_PATH third_party/expat/expat.gyp

	make_directory "third_party/class-dump"
  cp $BOGUS_CLASS_DUMP_PATH third_party/class-dump/class-dump.gyp
}

make_ios_project()
{
	print $warning "Generating ios project for $1 platform ..."

	export GYP_CROSSCOMPILE=1
  if [ "$1" == "armv7" ]; then
	   export GYP_DEFINES="OS=ios target_arch=arm clang_xcode=1"
	else
     export GYP_DEFINES="OS=ios target_arch=arm64 clang_xcode=1"
  fi
  export GYP_GENERATOR_FLAGS="xcode_project_version=3.2 output_dir=out_ios_$1 xcode_ninja_target_pattern=^audio_coding_module$|^audio_conference_mixer$|^audio_decoder_interface$|^audio_device$|^audio_encoder_interface$|^audio_processing$|^bitrate_controller$|^boringssl$|^cng$|^common_audio$|^common_audio_neon$|^common_video$|^field_trial_default$|^g711$|^g722$|^ilbc$|^isac$|^isac_fix$|^isac_neon$|^libjpeg$|^libsrtp$|^libvpx$|^libyuv$|^libyuv_neon$|^media_file$|^metrics_default$|^neteq$|^openmax_dl$|^opus$|^paced_sender$|^pcm16b$|^red$|^remote_bitrate_estimator$|^rtc_base_approved$|^rtp_rtcp$|^system_wrappers$|^usrsctplib$|^video_capture_module$|^video_capture_module_internal_impl$|^video_coding_utility$|^video_processing$|^video_render_module$|^video_render_module_internal_impl$|^voice_engine$|^webrtc$|^webrtc_common$|^webrtc_h264$|^webrtc_i420$|^webrtc_opus$|^webrtc_utility$|^webrtc_video_coding$|^webrtc_vp8$|^webrtc_vp9$ xcode_ninja_executable_target_pattern=^$"
  export GYP_GENERATORS="ninja,xcode-ninja"

	result=$(python webrtc/build/gyp_webrtc -DGENERATOR_FLAVOR='ninja' -DOS_RUNTIME='' -Dbuild_with_libjingle=0)
	print 3 "$result"

	if [ -d "./all.ninja.xcodeproj" ]; then
		#Add ninja to path
		if [ -n "$NINJA_PATH_TO_REPLACE_WITH" ]; then
			print $debug "Adding ninja path: $NINJA_PATH_TO_REPLACE_WITH"
			sed -i -e "s/PATH=/PATH=$NINJA_PATH_TO_REPLACE_WITH:/g" all.ninja.xcodeproj/project.pbxproj
		fi
		print $debug "Renaming ios project"
    if [ -d "all_ios_$1.xcodeproj" ]; then
      rm -rf all_ios_$1.xcodeproj
    fi
		mv all.ninja.xcodeproj all_ios_$1.xcodeproj

		cp $NINJA_WRAPPER_IOS_PATH ./out_ios_$1/Debug/webrtcWrapper_ios.ninja
		cp $NINJA_WRAPPER_IOS_PATH ./out_ios_$1/Debug-iphoneos/webrtcWrapper_ios.ninja
		cp $NINJA_WRAPPER_IOS_PATH ./out_ios_$1/Release/webrtcWrapper_ios.ninja
		cp $NINJA_WRAPPER_IOS_PATH ./out_ios_$1/Release-iphoneos/webrtcWrapper_ios.ninja
	fi
}

make_mac_project()
{
	print $warning "Generating mac project ..."

	export GYP_DEFINES="OS=mac target_arch=x64 clang_xcode=1 debug_extra_cflags=-stdlib=libc++ release_extra_cflags=-stdlib=libc++ mac_deployment_target=10.7"
	export GYP_GENERATOR_FLAGS="xcode_project_version=3.2 xcode_ninja_target_pattern=^audio_coding_module$|^audio_conference_mixer$|^audio_decoder_interface$|^audio_device$|^audio_encoder_interface$|^audio_processing$|^audio_processing_sse2$|^audioproc_debug_proto$|^bitrate_controller$|^boringssl$|^cng$|^common_audio$|^common_audio_sse2$|^common_video$|^field_trial_default$|^g711$|^g722$|^ilbc$|^isac$|^libjpeg$|^libsrtp$|^libvpx_new$|^libvpx_intrinsics_mmx$|^libvpx_intrinsics_avx2$|^libvpx_intrinsics_sse2$|^libvpx_intrinsics_ssse3$|^libvpx_intrinsics_sse4_1$|^libyuv$|^media_file$|^metrics_default$|^neteq$|^openmax_dl$|^opus$|^paced_sender$|^pcm16b$|^protobuf_lite$|^red$|^remote_bitrate_estimator$|^rtc_base_approved$|^rtp_rtcp$|^system_wrappers$|^usrsctplib$|^video_capture_module$|^video_capture_module_internal_impl$|^video_coding_utility$|^video_processing$|^video_processing_sse2$|^video_render_module$|^video_render_module_internal_impl$|^voice_engine$|^webrtc$|^webrtc_common$|^webrtc_h264$|^webrtc_i420$|^webrtc_opus$|^webrtc_utility$|^webrtc_video_coding$|^webrtc_vp8$|^webrtc_vp9$ xcode_ninja_executable_target_pattern=^$ output_dir=out_mac"
	export GYP_GENERATORS="ninja,xcode-ninja"

	result=$(python webrtc/build/gyp_webrtc -DGENERATOR_FLAVOR='ninja' -DOS_RUNTIME='' -Dbuild_with_libjingle=0)
	print $debug "$result"

	sed -i -e "s/ldflags =/ldflags = -lc++/g" out_mac/Debug/obj.host/chromium/src/third_party/protobuf/protoc.ninja
	sed -i -e "s/ldflags =/ldflags = -lc++/g" out_mac/Release/obj.host/chromium/src/third_party/protobuf/protoc.ninja

	if [ -d "./all.ninja.xcodeproj" ]; then
		#Add ninja to path
		if [ -n "$NINJA_PATH_TO_REPLACE_WITH" ]; then
			print $debug "Adding ninja path: $NINJA_PATH_TO_REPLACE_WITH"
			sed -i -e "s/PATH=/PATH=$NINJA_PATH_TO_REPLACE_WITH:/g" all.ninja.xcodeproj/project.pbxproj
		fi
		print $debug "Renaming mac project"
    if [ -d "all_osx.xcodeproj" ]; then
      rm -rf all_osx.xcodeproj
    fi
		mv all.ninja.xcodeproj all_osx.xcodeproj

		cp $NINJA_WRAPPER_MAC_PATH ./out_mac/Debug/webrtcWrapper_mac.ninja
		cp $NINJA_WRAPPER_MAC_PATH ./out_mac/Release/webrtcWrapper_mac.ninja
	fi
}

setNinjaPathForWrappers()
{
	if  hash ninja 2>/dev/null; then
		print $debug "Ninja is present in the PATH"
		NINJA_PATH_TO_REPLACE_WITH="$(which ninja)"
		NINJA_PATH_TO_REPLACE_WITH=${NINJA_PATH_TO_REPLACE_WITH%/ninja}
	else
		NINJA_PATH_TO_REPLACE_WITH="..\/..\/..\/..\/..\/bin\/ninja"
	fi

	print $debug "Ninja path is $NINJA_PATH_TO_REPLACE_WITH"

	WEBRTC_WRAPPER_IOS_PATH=../../../ortc/apple/projects/xcode/webrtcWrappers/webrtcWrapper_ios/webrtcWrapper_ios.xcodeproj/
	WEBRTC_WRAPPER_MAC_PATH=../../../ortc/apple/projects/xcode/webrtcWrappers/webrtcWrapper_mac/webrtcWrapper_mac.xcodeproj/

	if ! grep -q $NINJA_PATH_TO_REPLACE_WITH "${WEBRTC_WRAPPER_IOS_PATH}project.pbxproj"; then
		pushd $WEBRTC_WRAPPER_IOS_PATH
		sed -i -e "s~PATH=~PATH=$NINJA_PATH_TO_REPLACE_WITH:~g" project.pbxproj
		git update-index --assume-unchanged project.pbxproj
		popd
		#sed -i -e "s~PATH=~PATH=$NINJA_PATH_TO_REPLACE_WITH:~g" "$WEBRTC_WRAPPER_IOS_PATH"
		#git update-index --assume-unchanged "$WEBRTC_WRAPPER_IOS_PATH"
	fi

	if ! grep -q $NINJA_PATH_TO_REPLACE_WITH "${WEBRTC_WRAPPER_MAC_PATH}project.pbxproj"; then
		pushd $WEBRTC_WRAPPER_MAC_PATH
		sed -i -e "s~PATH=~PATH=$NINJA_PATH_TO_REPLACE_WITH:~g" project.pbxproj
		git update-index --assume-unchanged project.pbxproj
		popd
		#sed -i -e "s~PATH=~PATH=$NINJA_PATH_TO_REPLACE_WITH:~g" "$WEBRTC_WRAPPER_MAC_PATH"
		#git update-index --assume-unchanged "$WEBRTC_WRAPPER_MAC_PATH"
	fi
}

finished()
{
  echo
  print $info "Success: WebRtc development environment is set."
  	
}
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

#if [ -z "$VAR" ];
#then
#	print $warning "Running script with default parameters: "
#	print $warning "Target: all (Ortc and WebRtc)"
#	print $warning "Platform: all (Mac OS and iOS)"
#	print $warning "Log level: $logLevel (warning)"
#	defaultProperties=1
#fi

#;platform;logLevel;
while getopts ":p:l:" opt; do
  case $opt in
    p)
        platform=$OPTARG
        ;;
    l)
        logLevel=$OPTARG
        ;;
    esac
done

echo
print $info "Running WebRtc prepare script ..."

#Main flow
pushd ./webrtc/xplatform/webrtc > /dev/null

precheck
makeFolderStructure
identifyPlatform
#cleanPreviousResults
#setNinja
makeLinks
setBogusGypFiles
updateClang

if [ $platform_iOS -eq  1 ]; 
then
  	make_ios_project armv7
  	make_ios_project arm64
fi

if [ $platform_macOS -eq  1 ]; 
then
	make_mac_project
fi
	
setNinjaPathForWrappers
popd > /dev/null
finished
