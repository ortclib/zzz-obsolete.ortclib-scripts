#!/bin/bash

set -e

#log levels
error=0
info=1
warning=2
debug=3
trace=4

eventsIncludePath=../Internal
eventsIntermediatePath=IntermediateTemp
eventsOutput=$PWD/ortc/Apple/workspace/eventing/
compilerPath=$PWD/bin/eventing/zsLib.Eventing.Compiler.Tool


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

make_directory()
{
	if [ ! -d "$1" ]; then
		print $trace "Creating directory \"$1\"..."
		mkdir -p $1
	fi
}

buildEventCompiler()
{
  print $warning "Building event compiler ..."

  if [ -f $compilerPath ];
  then
    return
  fi

  pushd ortc/xplatform/zsLib-eventing/projects/xcode > /dev/null
  if [ $logLevel -gt $debug ];
  then
  	xcodebuild -workspace zsLib-Eventing.xcworkspace -scheme "zsLib.Eventing.Compiler.Tool" -configuration "Release" -derivedDataPath "./zsLib.Eventing.Compiler.Tool-osx.Tool/output/"
	else
		xcodebuild -workspace zsLib-Eventing.xcworkspace -scheme "zsLib.Eventing.Compiler.Tool" -configuration "Release" -derivedDataPath "./zsLib.Eventing.Compiler.Tool-osx.Tool/output/" > /dev/null
	fi
  if (( $? )); then
    error 1 "zsLib.Eventing.Compiler.Tool compilation has failed"
  else
    print $warning "Event compiler is built successfully"
  fi

  make_directory ../../../../../bin/eventing/

  if [ -f ./zsLib.Eventing.Compiler.Tool-osx.Tool/output/Build/Products/Release/zsLib.Eventing.Compiler.Tool ] && [ -f ./zsLib.Eventing.Compiler.Tool-osx.Tool/output/Build/Products/Release/libcryptopp-osx.a ]
  then
    cp ./zsLib.Eventing.Compiler.Tool-osx.Tool/output/Build/Products/Release/zsLib.Eventing.Compiler.Tool ../../../../../bin/eventing/zsLib.Eventing.Compiler.Tool
    cp ./zsLib.Eventing.Compiler.Tool-osx.Tool/output/Build/Products/Release/libcryptopp-osx.a ../../../../../bin/eventing/libcryptopp-osx.a
  fi

  popd > /dev/null
}

compileIdl()
{
  print $warning "Compiling IDL files..."

  eventPath=./ortc/xplatform/ortclib-cpp/ortc/idl

  pushd $eventPath > /dev/null
  $compilerPath -idl cx c dotnet json wrapper -c config.json -o . > /dev/null
  if (( $? )); then
    popd > /dev/null
    error 1 "$providerName event compilation has failed"
  fi
  popd > /dev/null
}

compileEvent()
{
  print $warning "Compiling event provider $1"

  eventJsonPath=$1
  eventPath=$(dirname "${eventJsonPath}")
  filename=$(basename "${eventJsonPath}")
  providerName="${filename%.*}"
  intermediatePath=.$eventPath/$eventsIntermediatePath/
  headersPath=$eventPath$eventsIncludePath
  outputPath=.$eventsOutput$providerName

  #make_directory $intermediatePath
  #make_directory $outputPath

  pushd $eventPath > /dev/null
  $compilerPath -c ./$filename -o $eventsIncludePath/$providerName  > /dev/null
  if (( $? )); then
    popd > /dev/null
    error 1 "$providerName event compilation has failed"
  fi
  popd > /dev/null
}

finished()
{
  echo
  print $info "Success: Eventing preparations is finished successfully."
  echo
}

#;logLevel;
while getopts ":p:l:" opt; do
  case $opt in
    l)
        logLevel=$OPTARG
        ;;
    esac
done

echo
print $info "Running prepare eventing script ..."

#Main flow
buildEventCompiler

for f in $(find ./ortc -name '*.events.json'); do
  compileEvent "$f"
done

compileIdl

finished
