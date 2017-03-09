#!/bin/bash
echo
echo PREPARING ORTC-LIB-SDK...
echo

set -e

precheck()
{
	if [ -d "../bin" ]; then
		echo Do not change into the bin directory to run scripts.
		echo
		exit -1
	fi
}

cmake_copy()
{
	if [ ! -d $2 ]; then
		echo Destination path does not exist: $2 !
	fi

	if [ ! -e $1 ]; then
		echo
		echo Failed to find $1 !
		echo
		exit -1
	fi

	echo cmake copy $1 to $2 ...
	echo

    cp $1 $2/CMakeLists.txt

	echo
}

do_cmake()
{
	if [ ! -d $2 ]; then
		echo cmake path does not exist: $1 !
	fi

	pushd $1 > /dev/null
	echo `pwd`\$ cmake .
	cmake .
	popd > /dev/null

}

precheck
cmake_copy "bin/templates/linux/webrtc_CMakeLists.txt" "webrtc/xplatform"
cmake_copy "bin/templates/linux/boringssl_CMakeLists.txt" "webrtc/xplatform/boringssl"
cmake_copy "bin/templates/linux/libsrtp_CMakeLists.txt" "webrtc/xplatform/libsrtp"
do_cmake "webrtc/xplatform"

echo
echo Success: ortc-lib SDK is prepared.
echo
