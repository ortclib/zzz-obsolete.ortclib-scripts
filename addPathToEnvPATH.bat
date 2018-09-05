@echo off

::usage example: 
::from the folder ortclib-sdk>  bin\addPathToEnvPATH.bat C:\this\is\new\path

set arg1=%1
SET PATH=%PATH%;%arg1%
