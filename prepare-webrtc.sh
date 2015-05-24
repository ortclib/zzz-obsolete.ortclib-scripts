#!/bin/bash

set -e

echo
echo Preparing symbolic links for WebRTC...
echo

TARGET="$1"

if [ -z "$TARGET" ]; then
	echo "Usage: prepare-webrtc.sh [ios | osx]"
	echo Defaulting to osx target...
	echo
	TARGET=osx
fi

if [ `echo $TARGET | tr [:upper:] [:lower:]` = `echo ios | tr [:upper:] [:lower:]` ]; then
	TARGET=ios
else
	TARGET=osx
fi

echo WebRTC target found=$TARGET
echo

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
		mkdir $1
	fi
}

precheck

preparelink "." "build" "../webrtc-deps/build/"

make_directory "chromium/src"
make_directory "chromium/src/third_party"
make_directory "chromium/src/tools"


preparelink "chromium/src/third_party" "jsoncpp" "../../../../webrtc-deps/chromium/third_party/jsoncpp"
preparelink "chromium/src/third_party/jsoncpp" "source" "../../../../webrtc-deps/jsoncpp"
preparelink "chromium/src/tools" "protoc_wrapper" "../../../../webrtc-deps/chromium/tools/protoc_wrapper"
preparelink "chromium/src/third_party" "protobuf" "../../../../webrtc-deps/chromium/third_party/protobuf"
preparelink "chromium/src/third_party" "yasm" "../../../../webrtc-deps/chromium/third_party/yasm"
preparelink "chromium/src/third_party" "opus" "../../../../webrtc-deps/chromium/third_party/opus"
preparelink "chromium/src/third_party" "colorama" "../../../../webrtc-deps/chromium/third_party/colorama"
preparelink "chromium/src/third_party" "boringssl" "../../../../webrtc-deps/chromium/third_party/boringssl"
preparelink "chromium/src/third_party" "usrsctp" "../../../../webrtc-deps/chromium/third_party/usrsctp"
preparelink "chromium/src" "testing" "../../../webrtc-deps/chromium/testing"
preparelink "." "testing" "chromium/src/testing"
preparelink "tools" "protoc_wrapper" "../chromium/src/tools/protoc_wrapper"
preparelink "third_party" "protobuf" "../chromium/src/third_party/protobuf"
preparelink "third_party" "yasm" "../chromium/src/third_party/yasm"
preparelink "third_party/yasm" "binaries" "../../../../webrtc-deps/yasm/binaries"
preparelink "third_party/yasm/source" "patched-yasm" "../../../../../webrtc-deps/patched-yasm"
preparelink "third_party" "opus" "../chromium/src/third_party/opus"
preparelink "third_party/opus" "src" "../../../../webrtc-deps/opus"
preparelink "third_party" "colorama" "../chromium/src/third_party/colorama"
preparelink "third_party/colorama" "src" "../../../../webrtc-deps/colorama"
preparelink "third_party" "boringssl" "../chromium/src/third_party/boringssl"
preparelink "third_party/boringssl" "src" "../../../../webrtc-deps/boringssl"
preparelink "third_party" "usrsctp" "../chromium/src/third_party/usrsctp"
preparelink "third_party/usrsctp" "usrsctplib" "../../../../webrtc-deps/usrsctp"
preparelink "third_party" "protobuf" "../chromium/src/third_party/protobuf"
preparelink "third_party" "libsrtp" "../../webrtc-deps/libsrtp"
preparelink "third_party" "libvpx" "../../webrtc-deps/libvpx"
preparelink "third_party" "libyuv" "../../webrtc-deps/libyuv"
preparelink "third_party" "openmax_dl" "../../webrtc-deps/openmax"
preparelink "third_party" "libjpeg_turbo" "../../webrtc-deps/libjpeg_turbo"
preparelink "third_party" "jsoncpp" "../chromium/src/third_party/jsoncpp"
preparelink "tools" "gyp" "../../webrtc-deps/gyp"
preparelink "testing" "gtest" "../../../webrtc-deps/gtest"

make_directory "third_party/expat"
cp ../../bin/bogus_expat.gyp third_party/expat/expat.gyp

echo DEPOT_TOOLS_WIN_TOOLCHAIN=0
echo GYP_GENERATORS=msvs-winrt

if [ "$TARGET" = "osx" ]; then
	echo python webrtc/build/gyp_webrtc -Dbuild_with_libjingle=0 -Dwinrt_platform=win_phone
fi

if [ "$TARGET" = "ios" ]; then
	echo python webrtc/build/gyp_webrtc -Dbuild_with_libjingle=0 -Dwinrt_platform=win_phone
fi

#preparelink "third_party/yasm/source" "patched-yasm" "../../../../webrtc-deps/patched-yasm/"
#preparelink "third_party/opus" "src" "../../../webrtc-deps/opus/"
#preparelink "third_party/colorama" "src" "../../../webrtc-deps/colorama/"
#preparelink "third_party" "libsrtp" "../../webrtc-deps/libsrtp/"
#preparelink "third_party" "libvpx" "../../webrtc-deps/libvpx/"
#preparelink "third_party" "libyuv" "../../webrtc-deps/libyuv/"
#preparelink "third_party" "openmax_dl" "../../webrtc-deps/openmax/"
#preparelink "third_party" "libjpeg_turbo" "../../webrtc-deps/libjpeg_turbo/"
#preparelink "tools" "gyp" "../../webrtc-deps/gyp/"
#preparelink ".." "third_party" "webrtc/third_party/"
#preparelink ".." "build" "webrtc-deps/build/"
#preparelink "../webrtc-deps" "yasm" "../webrtc/third_party/yasm"

echo
echo WebRTC ready.
echo
