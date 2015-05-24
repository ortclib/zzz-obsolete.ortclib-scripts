#!/bin/bash
echo
echo PREPARING ORTC-LIB-SDK...
echo

set -e

TARGET="$1"

if [ -z "$TARGET" ]; then
	echo "Usage: prepare.sh [ios | osx]"
	echo Defaulting to osx target...
	echo
	TARGET=osx
fi

if [ `echo $TARGET | tr [:upper:] [:lower:]` = `echo ios | tr [:upper:] [:lower:]` ]; then
	TARGET=ios
else
	TARGET=osx
fi

echo Target found=$TARGET

prepare()
{
	if [ ! -e $1/$2 ]; then
		echo
		echo Failed to find $1/$2 !
		echo
		exit -1
	fi

	echo Preparing $3 ...
	echo

	pushd $1 > /dev/null
	sh $2 $TARGET
	popd > /dev/null

	echo
}

precheck()
{
	if [ -d "../bin" ]; then
		echo Do not change into the bin directory to run scripts.
		echo
		exit -1
	fi
}

precheck
prepare "libs/webrtc" "../../bin/prepare-webrtc.sh" "WebRTC"
prepare "libs/curl" "prepare.sh" "curl"

echo 
echo Success: ortc-lib SDK is prepared.
echo
