@echo off

set failure=0

if EXIST ..\bin\nul call:failure -1 "Do not run scripts from bin directory!"
if "%failure%" neq "0" goto:eof

call bin\prepare.bat no-webrtc

goto:eof
:failure
echo.

echo ERROR: %~2

echo.
echo FAILURE: Could not prepare ortc-lib-sdk.

set failure=%~1

goto:eof