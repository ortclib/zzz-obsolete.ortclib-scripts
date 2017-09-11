import os
import sys


dir_path = os.path.dirname(os.path.realpath(__file__))

inputArray=sys.argv

idlPath=inputArray[1]
compilerPath="zslib-eventing-tool-compiler"


compilerNewPath = os.getcwd() + "/" + compilerPath;
os.chdir(os.path.dirname(idlPath))

os.system(compilerNewPath + " -idl cx c dotnet json wrapper -c config.json -o .")
