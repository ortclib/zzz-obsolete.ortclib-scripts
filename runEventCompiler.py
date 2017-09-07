import os
import sys


dir_path = os.path.dirname(os.path.realpath(__file__))

inputArray=sys.argv

eventJsonPath=inputArray[1]
#eventProviderPath=inputArray[2]
compilerPath="zslib-eventing-tool-compiler"
eventProviderName=os.path.splitext(os.path.basename(eventJsonPath))[0]

print("eventProviderName: ", eventProviderName)
print("eventJsonPath: ", eventJsonPath)
#print("eventProviderPath: ", eventProviderPath)
#print("eventProviderPath111111: ", os.path.dirname(eventProviderPath))
print("compilerPath: ",compilerPath)
print("file: ",__file__)
print("getcwd", os.getcwd())



compilerNewPath = os.getcwd() + "/" + compilerPath;
os.chdir(os.path.dirname(eventJsonPath))
eventJsonNewPath = os.getcwd() + "/" + os.path.basename(eventJsonPath)
print("compilerNewPath: ",compilerNewPath)
print("eventJsonNewPath: ",eventJsonNewPath)



print("NOVO getcwd", os.getcwd())
print("out", os.path.dirname(eventJsonNewPath))
#os.system(os.getcwd() + "/" + compilerPath + " -c " + eventJsonPath + " -o " + os.path.dirname(eventJsonPath))
os.system(compilerNewPath + " -c " + eventJsonNewPath + " -o " + os.path.dirname(eventJsonNewPath) + "/../internal/" + eventProviderName)
