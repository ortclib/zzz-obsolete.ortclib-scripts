#!/bin/bash

set -e

echo
echo Synchronizing pruned-chromium with chromium...
echo

SOURCE=../chromium

precheck()
{
	if [ -d "../bin" ]; then
		echo Do not change into the bin directory to run scripts.
		echo
		exit -1
	fi
}

sourcepath()
{
	if [ ! -d "$SOURCE" ]; then
		if [ -d "$1" ]; then
			SOURCE="$1"
			echo Found chromium in location \"$SOURCE\"
		fi
	fi
}

checkpath()
{
	if [ ! -d "$1" ]; then
		echo
		echo ERROR: Could not find location \"$1\"
		echo
		exit -1
	fi
}

make_directory()
{
	if [ ! -d "$1" ]; then
		echo Creating directory \"$1\"...
		mkdir $1
	fi
}

copy_path()
{
	if [ ! -d "$SOURCE/$1" ]; then
		echo
		echo ERROR: Coudl not find source path \"$SOURCE/$1\"
		echo
		exit -2
	fi

	if [ -d "$DEST/$1" ]; then
		pushd "$DEST/$1" > /dev/null

		rm -fr ./*
		rm -fr .??*

		popd > /dev/null

		rmdir "$DEST/$1"
	fi

	if [ ! -d "$DEST/$1" ]; then
		echo Creating directory \"$DEST/$1\"...
		mkdir -p "$DEST/$1"
	fi

	cp -R "$SOURCE/$1/" "$DEST/$1"
}

precheck

sourcepath "../chromium"
sourcepath "../../chromium"
sourcepath "../RTC_chromium"
sourcepath "../../RTC_chromium"

DEST="libs/webrtc-deps/chromium"

checkpath "$SOURCE"
checkpath "$DEST"

echo
echo Preparing to synchronize from \"$SOURCE\" to \"$DEST\"
echo

copy_path "build"
copy_path "testing"
copy_path "third_party/boringssl"
copy_path "third_party/colorama"
copy_path "third_party/jsoncpp"
copy_path "third_party/ocmock"
copy_path "third_party/opus"
copy_path "third_party/protobuf"
copy_path "third_party/libvpx_new"
copy_path "third_party/usrsctp"
copy_path "third_party/yasm"
copy_path "tools/clang"
copy_path "tools/protoc_wrapper"

echo
echo Chromium synchronized.
echo
