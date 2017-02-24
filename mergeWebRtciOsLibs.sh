#!/bin/bash

set -e

inputFolderPath1=$1
inputFolderPath2=$2
outputFolderPath=$3
outputLibFolderPath=$4
make_directory()
{
	if [ ! -d "$1" ]; then
		echo "Creating directory \"$1\"..."
		mkdir -p $1
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

merge_libs_with_different_arch
make_fat_webrtc
