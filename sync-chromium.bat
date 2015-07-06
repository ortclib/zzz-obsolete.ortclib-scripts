@echo off
echo.
echo Preparing symbolic links for WebRTC...
echo.

set failure=0

echo Synchronizing chromium to pruned chromium...

if EXIST ..\bin\nul call:failure -1 "Do not run scripts from bin directory!"
if "%failure%" neq "0" goto:done_with_error

set SOURCE=..\chromium

if NOT EXIST %SOURCE%\nul set SOURCE=..\RTC_chromium
if NOT EXIST %SOURCE%\nul set SOURCE=..\..\chromium
if NOT EXIST %SOURCE%\nul set SOURCE=..\..\RTC_chromium
if NOT EXIST %SOURCE%\nul set SOURCE=..\..\..\chromium
if NOT EXIST %SOURCE%\nul set SOURCE=..\..\..\RTC_chromium
if NOT EXIST %SOURCE%\nul call:failure -2 "Could not find chromium source directory"
if "%failure%" neq "0" goto:done_with_error

set DEST=libs\webrtc-deps\chromium
if NOT EXIST %DEST%\nul call:failure -2 "Could not find chromium pruned destination directory"
if "%failure%" neq "0" goto:done_with_error

call:copy_path testing
if "%failure%" neq "0" goto:done_with_error

call:copy_path third_party\boringssl
if "%failure%" neq "0" goto:done_with_error

call:copy_path third_party\colorama
if "%failure%" neq "0" goto:done_with_error

call:copy_path third_party\jsoncpp
if "%failure%" neq "0" goto:done_with_error

call:copy_path third_party\opus
if "%failure%" neq "0" goto:done_with_error

call:copy_path third_party\protobuf
if "%failure%" neq "0" goto:done_with_error

call:copy_path third_party\usrsctp
if "%failure%" neq "0" goto:done_with_error

call:copy_path third_party\yasm
if "%failure%" neq "0" goto:done_with_error

goto:done

:copy_path

if NOT EXIST %SOURCE%\%~1\nul call:failure -3 "Could not find source path %SOURCE%\%~1"
if "%failure%" neq "0" goto:eof

if EXIST %DEST%\%~1\nul del /S /Q %DEST%\%~1
if EXIST %DEST%\%~1\nul del /S /Q %DEST%\%~1
if EXIST %DEST%\%~1\nul rmdir /S /Q %DEST%\%~1
call:make_directory %DEST%\%~1
if "%failure%" neq "0" goto:eof

xcopy /S %SOURCE%\%~1 %DEST%\%~1

goto:eof

:make_directory
if NOT EXIST %~1\nul mkdir %~1
if NOT EXIST %~1\nul call:failure -4 "Could not find source path %SOURCE%\%~1"
if "%failure%" neq "0" goto:eof
goto:eof

:failure
echo.
cd
echo ERROR: %~2
echo.

set failure=%~1

goto:eof

:done_with_error

exit /b %failure%
goto:eof

:done

echo.
echo Success: chromium Synchronization ready.
echo.
