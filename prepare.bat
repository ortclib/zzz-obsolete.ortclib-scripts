@echo off
echo.
echo Preparing ortc-lib-sdk...
echo.

set failure=0

call:doprepare . prepare-webrtc.bat WebRTC
if "%failure%" neq "0" goto:eof

call:doprepare libs\curl prepare.bat curl
if "%failure%" neq "0" goto:eof

goto:done


:doprepare

if NOT EXIST %~1\%~2 call:failure -1 "Did not find %~3 preparation script in %~1\%~2!"
if "%failure%" neq "0" goto:eof

pushd %~1 > NUL
if ERRORLEVEL 1 call:failure %errorlevel% "%~3 preparation failed."
call %~2
if ERRORLEVEL 1 call:failure %errorlevel% "%~3 preparation failed."
popd > NUL
if "%failure%" neq "0" goto:eof


goto:eof


:failure
echo.
echo ERROR: %~2
echo.
echo FAILURE: Could not prepare ortc-lib-sdk.

set failure=%~1

goto:eof

:done
echo.
echo Success: completed preparation of ortc-lib SDK.
echo.
