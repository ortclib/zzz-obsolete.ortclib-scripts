import os
import sys

dir_path = os.path.dirname(os.path.realpath(__file__))

inputArray=sys.argv

idlPath=inputArray[1]
sourcePathPrefix=inputArray[2]
toolchainCPU=inputArray[3]
#tempToolchain=toolchain.split(":")
#toolchainCPU=tempToolchain[1]

if (os.name == "posix"):
  compilerPath="zslib-eventing-tool-compiler"
else:
  compilerPath="zslib-eventing-tool-compiler.exe"

currentWorkingPath=os.getcwd()
pathname = os.path.dirname(sys.argv[0]) 
idlCompilationPath=dir_path + "/idl.flg"
print "idlCompilationPath - : " + idlCompilationPath
if not os.path.isfile(idlCompilationPath):
  print("Running idl compilation")

  compilerNewPath = os.getcwd() + "/" + compilerPath;
  if not os.path.isfile(compilerNewPath):
    compilerNewPath = os.getcwd() + "/" + toolchainCPU + "/" + compilerPath;
    if not os.path.isfile(compilerNewPath):
      sys.exit("Idl compiler doesn't exist")
      
  os.chdir(os.path.dirname(idlPath))
  jsonFile=os.path.basename(idlPath)

  print "runIDLCompiler - idlPath: " + idlPath
  print "runIDLCompiler - jsonFile: " + jsonFile
  print "runIDLCompiler - sourcePathPrefix: " + sourcePathPrefix
  print "runIDLCompiler - NewWorkingPath:" + os.getcwd()
  print "runIDLCompiler - compilerNewPath: " + compilerNewPath

  result=os.system(compilerNewPath + " -idl c dotnet json cx json wrapper python cppwinrt msidl -c " + jsonFile + " -o .")
  if (result!=0):
    sys.exit("Failed idl compilation" + str(result))
    
  updateScriptPath = os.path.dirname(os.path.realpath(__file__)) + "/../../../../bin/updateGniFileWithSources.py"

  print "runIDLCompiler - UpdateScriptPath:" + updateScriptPath

  #sources.gni is prepopulated, so there is no need to update that file anymore
  #os.system("python " + updateScriptPath + " wrapper ortc " + sourcePathPrefix)

  open(idlCompilationPath,'w').close()
  os.chdir(os.path.dirname(currentWorkingPath))
else:
  print("Idls have been already compiled")