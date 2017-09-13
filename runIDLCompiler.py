import os
import sys

dir_path = os.path.dirname(os.path.realpath(__file__))

inputArray=sys.argv

idlPath=inputArray[1]
compilerPath="zslib-eventing-tool-compiler"

currentWorkingPath=os.getcwd()

print "runIDLCompiler - CurrentWorkingPath:" + currentWorkingPath

compilerNewPath = os.getcwd() + "/" + compilerPath;
os.chdir(os.path.dirname(idlPath))

print "runIDLCompiler - NewWorkingPath:" + os.getcwd()

#os.system(compilerNewPath + " -idl cx c dotnet json wrapper -c config.json -o .")
os.system(compilerNewPath + " -idl c json wrapper -c config.json -o .")

updateScriptPath = os.path.dirname(os.path.realpath(__file__)) + "/../../../../bin/updateGniFileWithSources.py"

print "runIDLCompiler - UpdateScriptPath:" + updateScriptPath

os.system("python " + updateScriptPath + " wrapper ortc_sources")

os.chdir(os.path.dirname(currentWorkingPath))