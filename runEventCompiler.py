import os
import sys


dir_path = os.path.dirname(os.path.realpath(__file__))
inputArray=sys.argv

eventJsonPath=inputArray[1]
toolchainCPU=inputArray[2]
#tempToolchain=toolchain.split(":")
#toolchainCPU=tempToolchain[1]


#eventProviderPath=inputArray[2]
if (os.name == "posix"):
  compilerPath="zslib-eventing-tool-compiler"
else:
  compilerPath="zslib-eventing-tool-compiler.exe"
  
eventProviderName=os.path.splitext(os.path.basename(eventJsonPath))[0]
eventCompilationPath=dir_path + "/" + eventProviderName + "_eventsCompiled.flg"
print ("Event compilation flag path: ",eventCompilationPath)
if not os.path.isfile(eventCompilationPath):
  print("Running events compilation for " + eventJsonPath)

  #print("eventProviderName: ", eventProviderName)
  #print("eventJsonPath: ", eventJsonPath)
  #print("compilerPath: ",compilerPath)
  #print("file: ",__file__)
  #print("getcwd", os.getcwd())

  compilerNewPath = os.getcwd() + "/" + compilerPath;
  if not os.path.isfile(compilerNewPath):
    compilerNewPath = os.getcwd() + "/" + toolchainCPU + "/" + compilerPath;
    if not os.path.isfile(compilerNewPath):
      sys.exit("Idl compiler doesn't exist")
      
  os.chdir(os.path.dirname(eventJsonPath))
  eventJsonNewPath = os.getcwd() + "/" + os.path.basename(eventJsonPath)
  #print("compilerNewPath: ",compilerNewPath)
  #print("eventJsonNewPath: ",eventJsonNewPath)
  #print("NOVO getcwd", os.getcwd())
  #print("out", os.path.dirname(eventJsonNewPath))
  #os.system(os.getcwd() + "/" + compilerPath + " -c " + eventJsonPath + " -o " + os.path.dirname(eventJsonPath))
  result=os.system(compilerNewPath + " -c " + eventJsonNewPath + " -o " + os.path.dirname(eventJsonNewPath) + "/../internal/" + eventProviderName)

  if (result==0):
    open(eventCompilationPath,'w').close()
  else:
    sys.exit("Failed event compilation" + str(result))
else:
  print("Events " + eventJsonPath + " have been already compiled")
