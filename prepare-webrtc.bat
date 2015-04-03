@echo off
echo.
echo Preparing symbolic links for WebRTC...
echo.

set failure=0
set cdwebrtcdir=0

call:startWebRTC libs\webrtc
if "%failure%" neq "0" goto:done_with_error

set cdwebrtcdir=1

call:dolink . build ..\webrtc-deps\build
if "%failure%" neq "0" goto:done_with_error
call:dolink third_party\yasm\source patched-yasm ..\..\..\..\webrtc-deps\patched-yasm
if "%failure%" neq "0" goto:done_with_error
call:dolink third_party\opus src ..\..\..\webrtc-deps\opus
if "%failure%" neq "0" goto:done_with_error
call:dolink third_party\colorama src ..\..\..\webrtc-deps\colorama
if "%failure%" neq "0" goto:done_with_error
call:dolink third_party libsrtp ..\..\webrtc-deps\libsrtp
if "%failure%" neq "0" goto:done_with_error
call:dolink third_party libvpx ..\..\webrtc-deps\libvpx
if "%failure%" neq "0" goto:done_with_error
call:dolink third_party libyuv ..\..\webrtc-deps\libyuv
if "%failure%" neq "0" goto:done_with_error
call:dolink third_party openmax_dl ..\..\webrtc-deps\openmax
if "%failure%" neq "0" goto:done_with_error
call:dolink third_party libjpeg_turbo ..\..\webrtc-deps\libjpeg_turbo
if "%failure%" neq "0" goto:done_with_error
call:dolink tools gyp ..\..\webrtc-deps\gyp
if "%failure%" neq "0" goto:done_with_error

call:endWebRTC

goto:done

:startWebRTC

if NOT EXIST %~1\nul call:failure -1 "%~1 does not exist!"
if "%failure%" neq "0" goto:eof

pushd %~1

goto:eof

:endWebRTC

popd

goto:eof


:dolink
if NOT EXIST %~1\nul call:failure -1 "%~1 does not exist!"
if "%failure%" neq "0" goto:eof

pushd %~1

IF EXIST .\%~2\nul goto:alreadyexists

IF NOT EXIST %~3\nul call:failure -1 "%~3 does not exist!"
if "%failure%" neq "0" popd
if "%failure%" neq "0" goto:eof

echo In path "%~1" creating symbolic link for "%~2" to "%~3"
mklink /J %~2 %~3
if %errorlevel% neq 0 call:failure %errorlevel% "Could not create symbolic link to %~2 from %~3"
popd
if "%failure%" neq "0" goto:eof

goto:eof

:alreadyexists
popd
goto:eof

:failure
echo.
cd
echo ERROR: %~2
echo.

set failure=%~1

goto:eof

:done_with_error

if "%cdwebrtcdir%" neq "0" popd
set cdwebrtcdir=0

exit /b %failure%
goto:eof

:done

if "%cdwebrtcdir%" neq "0" popd
set cdwebrtcdir=0

echo.
echo Success: WebRTC ready.
echo.
