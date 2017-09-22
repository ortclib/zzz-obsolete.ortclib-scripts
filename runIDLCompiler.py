import os
import sys

dir_path = os.path.dirname(os.path.realpath(__file__))

inputArray=sys.argv

idlPath=inputArray[1]
sourcePathPrefix=inputArray[2]

compilerPath="zslib-eventing-tool-compiler"

currentWorkingPath=os.getcwd()

print "runIDLCompiler - CurrentWorkingPath:" + currentWorkingPath

compilerNewPath = os.getcwd() + "/" + compilerPath;
os.chdir(os.path.dirname(idlPath))
jsonFile=os.path.basename(idlPath)

print "runIDLCompiler - idlPath: " + idlPath
print "runIDLCompiler - jsonFile: " + jsonFile
print "runIDLCompiler - sourcePathPrefix: " + sourcePathPrefix
print "runIDLCompiler - NewWorkingPath:" + os.getcwd()

#os.system(compilerNewPath + " -idl cx c dotnet json wrapper -c config.json -o .")
os.system(compilerNewPath + " -idl cx c dotnet json wrapper -c " + jsonFile + " -o .")

updateScriptPath = os.path.dirname(os.path.realpath(__file__)) + "/../../../../bin/updateGniFileWithSources.py"

print "runIDLCompiler - UpdateScriptPath:" + updateScriptPath

#sources.gni is prepopulated, so there is no need to update that file anymore
#os.system("python " + updateScriptPath + " wrapper ortc " + sourcePathPrefix)

os.chdir(os.path.dirname(currentWorkingPath))