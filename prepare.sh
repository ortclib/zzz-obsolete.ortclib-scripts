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
	sh $2
	popd > /dev/null

	echo
}


prepare "." "prepare-webrtc.sh" "WebRTC"
#prepare libs/curl" "prepare.sh" "curl"

echo 
echo Success: ortc-lib SDK is prepared.
echo
