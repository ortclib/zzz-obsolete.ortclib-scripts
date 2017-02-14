#!/bin/bash

set -e

eventsIncludePath=../Internal
eventsIntermediatePath=IntermediateTemp
eventsOutput=$PWD/ortc/Apple/workspace/eventing/
compilerPath=$PWD/bin/eventing/zsLib.Eventing.Compiler.Tool


make_directory()
{
	if [ ! -d "$1" ]; then
		#print $trace "Creating directory \"$1\"..."
		mkdir -p $1
	fi
}

buildEventCompiler()
{
  if [ -f $compilerPath ];
  then
    return
  fi

  pushd ortc/xplatform/zsLib-eventing/projects/xcode
  xcodebuild -workspace zsLib-Eventing.xcworkspace -scheme "zsLib.Eventing.Compiler.Tool" -configuration "Release" -derivedDataPath "./zsLib.Eventing.Compiler.Tool-osx.Tool/output/"

  if (( $? )); then
    echo "zsLib.Eventing.Compiler.Tool compilation has failed" >&2
    exit 1
  fi

  make_directory ../../../../../bin/eventing/

  if [ -f ./zsLib.Eventing.Compiler.Tool-osx.Tool/output/Build/Products/Release/zsLib.Eventing.Compiler.Tool ] && [ -f ./zsLib.Eventing.Compiler.Tool-osx.Tool/output/Build/Products/Release/libcryptopp-osx.a ]
  then
    cp ./zsLib.Eventing.Compiler.Tool-osx.Tool/output/Build/Products/Release/zsLib.Eventing.Compiler.Tool ../../../../../bin/eventing/zsLib.Eventing.Compiler.Tool
    cp ./zsLib.Eventing.Compiler.Tool-osx.Tool/output/Build/Products/Release/libcryptopp-osx.a ../../../../../bin/eventing/libcryptopp-osx.a
  fi

  popd
}

compileEvent()
{
  eventJsonPath=$1
  eventPath=$(dirname "${eventJsonPath}")
  filename=$(basename "${eventJsonPath}")
  providerName="${filename%.*}"
  intermediatePath=.$eventPath/$eventsIntermediatePath/
  headersPath=$eventPath$eventsIncludePath
  outputPath=.$eventsOutput$providerName

  make_directory $intermediatePath
  #make_directory $outputPath

  pushd $eventPath
  $compilerPath -c ./$filename -o $eventsIncludePath/$providerName
  popd
  if (( $? )); then
    echo "$providerName event compilation has failed"
    exit 1
  fi
}

finished()
{
  echo
  echo "Success: Eventing preparations is finished successfully."
  echo
}

buildEventCompiler

#for f in /ortc/*.events.json ortc/**/*.events.json ; do
for f in $(find ./ortc -name '*.events.json'); do
  compileEvent "$f"
done

finished
