import os
import sys

inputArray=sys.argv

projectPath=inputArray[1]
targetName=inputArray[2]
pathPrefix=inputArray[3]

sourcesList = targetName + "_sources = [\n"

for dirpath,_,filenames in os.walk(projectPath):
       for f in filenames:
           sourcesList += ' "%s%s",\n' % (pathPrefix,os.path.relpath(os.path.join(dirpath, f)))

sourcesList+="]"

print "updateGniFileWithSources - CurrentWorkingPath:" + os.getcwd()

text_file = open('sources.gni', 'w')
text_file.write(str(sourcesList))
text_file.close