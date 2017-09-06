import os
import sys

print(sys.argv[1])

inputArray=sys.argv

eventJsonPath=inputArray[1]
eventProviderPath=inputArray[2]
compilerPath="out/linux-x64-debug/zslib-eventing-tool-compilerPath"

print("eventJsonPath: ", eventJsonPath)
print("eventProviderPath: ", eventProviderPath)
print("compilerPath: ",compilerPath)

os.system(compilerPath + "-c ./" + eventJsonPath + "-o" + eventProviderPath)
