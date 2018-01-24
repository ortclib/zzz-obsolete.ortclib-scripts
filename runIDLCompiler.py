import os
import sys

dir_path = os.path.dirname(os.path.realpath(__file__))

inputArray=sys.argv

idlPath=inputArray[1]
sourcePathPrefix=inputArray[2]

compilerPath="zslib-eventing-tool-compiler"

currentWorkingPath=os.getcwd()
pathname = os.path.dirname(sys.argv[0]) 
idlCompilationPath=dir_path + "/idl.flg"
print "idlCompilationPath - : " + idlCompilationPath
if not os.path.isfile(idlCompilationPath):
  print("Running idl compilation")

  compilerNewPath = os.getcwd() + "/" + compilerPath;
  os.chdir(os.path.dirname(idlPath))
  jsonFile=os.path.basename(idlPath)

  print "runIDLCompiler - idlPath: " + idlPath
  print "runIDLCompiler - jsonFile: " + jsonFile
  print "runIDLCompiler - sourcePathPrefix: " + sourcePathPrefix
  print "runIDLCompiler - NewWorkingPath:" + os.getcwd()

  #os.system(compilerNewPath + " -idl cx c dotnet json wrapper -c config.json -o .")
  os.system(compilerNewPath + " -idl c dotnet json -c " + jsonFile + " -o .")
  os.system(compilerNewPath + " -idl cx json wrapper -c " + jsonFile + " -s winuwp.json -o .")

  updateScriptPath = os.path.dirname(os.path.realpath(__file__)) + "/../../../../bin/updateGniFileWithSources.py"

  print "runIDLCompiler - UpdateScriptPath:" + updateScriptPath

  #sources.gni is prepopulated, so there is no need to update that file anymore
  #os.system("python " + updateScriptPath + " wrapper ortc " + sourcePathPrefix)

  open(idlCompilationPath,'w').close()
  os.chdir(os.path.dirname(currentWorkingPath))
else:
  print("Idls have been already compiled")