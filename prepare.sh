#!/bin/bash
echo
echo PREPARING ORTC-LIB-SDK...
echo

set -e

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
#prepare "libs/curl" "prepare.sh" "curl"

echo
echo Success: ortc-lib SDK is prepared.
echo
