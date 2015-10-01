#!/bin/bash

set -e

echo
echo Preparing symbolic links for WebRTC...
echo

BUILD_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/build/
BORINGSSL_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/boringssl/src/
COLORAMA_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/colorama/src/
JSONCPP_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/jsoncpp/source/
LIBJPEG_TURBO_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/libjpeg_turbo/

LIBSRTP_TURBO_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/libsrtp/
LIBVPX_TURBO_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/libvpx/
LIBYUV_TURBO_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/libyuv/
OPENMAX_TURBO_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/openmax_dl/
OPUS_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/opus/src/

USRSCTP_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/usrsctp/usrsctplib/
PATCHED_YASM_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/yasm/source/patched-yasm/
YASM_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/yasm/binaries/
GYP_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/tools/gyp/
GTEST_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/testing/gtest/

GFLAGS_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/third_party/gflags/src/
GMOCK_FOLDER_CHROMIUM_DESTINATION=../webrtc-deps/chromium/testing/gmock/

SRC_FILES_PATH=./chromium/src
SRC_FILES_DESTINATION=../webrtc/chromium/src/

NINJA_PATH=../../bin/ninja/
NINJA_PATH_TO_REPLACE_WITH=""
NINJA_URL="http://github.com/martine/ninja/releases/download/v1.6.0/ninja-mac.zip"
NINJA_ZIP_FILE="ninja-mac.zip"

PROJECT_FILE=all.ninja.xcworkspace
PROJECT_MAC_FILE=all_osx.xcodeproj
PROJECT_IOS_FILE=all_ios.xcodeproj

OUTPUT_IOS=out_ios
OUTPUT_MAC=out_mac


setNinja()
{
	echo Start

	if  hash ninja 2>/dev/null; then
		echo "Ninja is present in the PATH"
	else
		if [ -f "$NINJA_PATH/ninja" ]; then
			echo "Ninja already installed"
			NINJA_PATH_TO_REPLACE_WITH="..\/..\/bin\/ninja"
			echo ninja path: $NINJA_PATH_TO_REPLACE_WITH
		else
			echo  $PWD
			echo "Downloading ninja"
			mkdir -p $NINJA_PATH                        		&& \
			pushd $NINJA_PATH                          		&& \
			curl -L0k $NINJA_URL >  $NINJA_ZIP_FILE			&& \
			unzip $NINJA_ZIP_FILE                       && \
			rm $NINJA_ZIP_FILE
			popd
			NINJA_PATH_TO_REPLACE_WITH="..\/..\/bin\/ninja"
			echo ninja path: $NINJA_PATH_TO_REPLACE_WITH
		fi
	fi
}

copyFolder()
{
	SOURCE=$1
	TARGET=$2

	if [[ -n $SOURCE && -n $TARGET ]]; then
		if [ -d $SOURCE ]; then
			echo "Copying $SOURCE to $TARGET"
			mkdir -p $TARGET && cp -r $SOURCE $TARGET
		else
			echo "ERROR (copyFolder): Folder $SOURCE doesn't exist."
		fi
	else
		echo "ERROR (copyFolder): Missing source and destination folders"
	fi
}
makeFolderStructure()
{
	echo Creating folder structure

	copyFolder ../webrtc-deps/build/ $BUILD_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/boringssl/ $BORINGSSL_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/colorama/ $COLORAMA_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/jsoncpp/ $JSONCPP_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/libjpeg_turbo/ $LIBJPEG_TURBO_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/libsrtp/ $LIBSRTP_TURBO_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/libvpx/ $LIBVPX_TURBO_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/libyuv/ $LIBYUV_TURBO_FOLDER_CHROMIUM_DESTINATION
  copyFolder ../webrtc-deps/openmax/ $OPENMAX_TURBO_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/openmax/ $OPENMAX_TURBO_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/opus/ $OPUS_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/usrsctp/ $USRSCTP_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/patched-yasm/ $PATCHED_YASM_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/yasm/ $YASM_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/gyp/ $GYP_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/gtest/ $GTEST_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/gflags/ $GFLAGS_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/gmock/ $GMOCK_FOLDER_CHROMIUM_DESTINATION
	copyFolder ../webrtc-deps/chromium/ $SRC_FILES_DESTINATION

	echo Finished creating folder structure
}

removeFolder()
{
	SOURCE=$1

	if [ -n $SOURCE ]; then
		if [ -d $SOURCE ]; then
			echo "Removing folder $SOURCE"
			rm -r $SOURCE
		fi
	else
		echo "ERROR (removeFolder): Folder path is not provided."
	fi
}
removeFolderStructure()
{
	echo Removing temporary folders

	removeFolder $BUILD_FOLDER_CHROMIUM_DESTINATION
	removeFolder $BORINGSSL_FOLDER_CHROMIUM_DESTINATION
	removeFolder $COLORAMA_FOLDER_CHROMIUM_DESTINATION
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

	echo Cleaning old data from $PWD

	if [ -d "$PROJECT_FILE" ]; then
		echo Deleting $PROJECT_FILE
		rm -r $PROJECT_FILE
	fi

	if [ -d "$PROJECT_IOS_FILE" ]; then
		echo Deleting $PROJECT_IOS_FILE
		rm -r $PROJECT_IOS_FILE
	fi

	if [ -d "$PROJECT_MAC_FILE" ]; then
		echo Deleting $PROJECT_MAC_FILE
		rm -r $PROJECT_MAC_FILE
	fi

	if [ -d "$OUTPUT_IOS" ]; then
		echo Deleting $OUTPUT_IOS
		rm -r $OUTPUT_IOS
	fi

	if [ -d "$OUTPUT_MAC" ]; then
		echo Deleting $OUTPUT_MAC
		rm -r $OUTPUT_MAC
	fi

	#Check if it is a softlink
	if [[ -L "$SRC_FILES_PATH" && -d "$SRC_FILES_PATH" ]]; then
		echo Removing src softlink
		rm $SRC_FILES_PATH
	fi

	if [ -d "$SRC_FILES_PATH" ]; then
		echo Deleting src folder
		rm -r $SRC_FILES_PATH
	fi
}

precheck()
{
	if [ -d "../bin" ]; then
		echo Do not change into the bin directory to run scripts.
		echo
		exit -1
	fi
}

preparelink()
{
	if [ ! -d "$1" ]; then
		echo ERROR: Path to link does not exist \"$1\" !
		exit -1
	fi

	pushd $1 > /dev/null

	if [ ! -d "$3" ]; then
		echo ERROR: Link destination is not found \"$3\" inside \"$1\" !
		popd > /dev/null
		exit -1
	fi

	if [ ! -h "$2" ]; then
		echo In path \"$1\" creating webrtc symbolic link \"$2\" pointing to \"$3\"...
		ln -s $3 $2
		if [ $? -ne 0 ]; then
			failure=$?
			echo Failed to create symbolic link
			popd > /dev/null
			exit $failure
		fi
	fi

	popd > /dev/null
}

make_directory()
{
	if [ ! -d "$1" ]; then
		echo Creating directory \"$1\"...
		mkdir -p $1
	fi
}

make_ios_project()
{
	echo "Generating ios project ..."

	export GYP_CROSSCOMPILE=1
	export GYP_DEFINES="OS=ios target_arch=arm clang_xcode=1"
	export GYP_GENERATOR_FLAGS="xcode_project_version=3.2 xcode_ninja_target_pattern=all_ios|webrtc|webrtc_all|boringssl|libsrtp|libvpx|webrtc_opus|jsoncpp|libyuv|libjpeg|usrsctp|common_video|rtc_base_approved|system_wrappers|video_capture_module_internal_impl|video_capture_module|video_render_module_internal_impl|video_render_module|webrtc_common xcode_ninja_executable_target_pattern=AppRTCDemo|libjingle_peerconnection_objc_test|libjingle_peerconnection_unittest output_dir=out_ios"
	export GYP_GENERATORS="ninja,xcode-ninja"

	result=$(python webrtc/build/gyp_webrtc -DGENERATOR_FLAVOR='ninja' -DOS_RUNTIME='' -Dbuild_with_libjingle=0)
	echo $result

	if [ -d "./all.ninja.xcodeproj" ]; then
		#Add ninja to path
		if [ -n "$NINJA_PATH_TO_REPLACE_WITH" ]; then
			echo "Adding ninja path: $NINJA_PATH_TO_REPLACE_WITH"
			sed -i -e "s/PATH=/PATH=$NINJA_PATH_TO_REPLACE_WITH:/g" all.ninja.xcodeproj/project.pbxproj
		fi
		echo "Renaming ios project"
		mv all.ninja.xcodeproj all_ios.xcodeproj
	fi



}

make_mac_project()
{
	echo "Generating mac project ..."

	export GYP_DEFINES="OS=mac target_arch=x64 clang_xcode=1 debug_extra_cflags=-stdlib=libc++ release_extra_cflags=-stdlib=libc++ mac_deployment_target=10.8"
	export GYP_GENERATOR_FLAGS="xcode_project_version=3.2 xcode_ninja_target_pattern=^audio_coding_module$|^audio_conference_mixer$|^audio_decoder_interface$|^audio_device$|^audio_encoder_interface$|^audio_processing$|^audio_processing_sse2$|^audioproc_debug_proto$|^bitrate_controller$|^boringssl$|^cng$|^common_audio$|^common_audio_sse2$|^common_video$|^field_trial_default$|^g711$|^g722$|^ilbc$|^isac$|^libjpeg$|^libsrtp$|^libvpx$|^libvpx_intrinsics_mmx$|^libvpx_intrinsics_avx2$|^libvpx_intrinsics_sse2$|^libvpx_intrinsics_ssse3$|^libvpx_intrinsics_sse4_1$|^libyuv$|^media_file$|^metrics_default$|^neteq$|^openmax_dl$|^opus$|^paced_sender$|^pcm16b$|^protobuf_lite$|^red$|^remote_bitrate_estimator$|^rtc_base_approved$|^rtp_rtcp$|^system_wrappers$|^usrsctplib$|^video_capture_module$|^video_capture_module_internal_impl$|^video_coding_utility$|^video_processing$|^video_processing_sse2$|^video_render_module$|^video_render_module_internal_impl$|^voice_engine$|^webrtc$|^webrtc_common$|^webrtc_h264$|^webrtc_i420$|^webrtc_opus$|^webrtc_utility$|^webrtc_video_coding$|^webrtc_vp8$|^webrtc_vp9$ xcode_ninja_executable_target_pattern=^$ output_dir=out_mac"
	export GYP_GENERATORS="ninja,xcode-ninja"

	result=$(python webrtc/build/gyp_webrtc -DGENERATOR_FLAVOR='ninja' -DOS_RUNTIME='' -Dbuild_with_libjingle=0)
	echo $result

	sed -i -e "s/ldflags =/ldflags = -lc++/g" out_mac/Debug/obj.host/chromium/src/third_party/protobuf/protoc.ninja
	sed -i -e "s/ldflags =/ldflags = -lc++/g" out_mac/Release/obj.host/chromium/src/third_party/protobuf/protoc.ninja

	if [ -d "./all.ninja.xcodeproj" ]; then
		#Add ninja to path
		if [ -n "$NINJA_PATH_TO_REPLACE_WITH" ]; then
			echo "Adding ninja path: $NINJA_PATH_TO_REPLACE_WITH"
			sed -i -e "s/PATH=/PATH=$NINJA_PATH_TO_REPLACE_WITH:/g" all.ninja.xcodeproj/project.pbxproj
		fi
		echo "Renaming mac project"
		mv all.ninja.xcodeproj all_osx.xcodeproj
	fi
}

makeLinks()
{
	echo Creating links

	preparelink "." "build" $BUILD_FOLDER_CHROMIUM_DESTINATION
	#preparelink "chromium" "src" "../../webrtc-deps/chromium/"
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

setBogusGypFiles()
{
	echo Placing bogus gyp files

	make_directory "third_party/expat"
	cp ../../bin/bogus_expat.gyp third_party/expat/expat.gyp

	make_directory "third_party/class-dump"
  cp ../../bin/bogus_class-dump.gyp third_party/class-dump/class-dump.gyp
}

updateClang()
{
	echo Runing clang update
	result=$(python tools/clang/scripts/update.py 2>&1)
	echo $result

	preparelink "third_party" "llvm" "../chromium/src/third_party/llvm"
	preparelink "third_party" "llvm-build" "../chromium/src/third_party/llvm-build"

}

cleanPreviousResults

setNinja

precheck

makeFolderStructure

makeLinks

setBogusGypFiles

updateClang

make_ios_project

make_mac_project

#removeFolderStructure

echo
echo WebRTC ready.
echo
