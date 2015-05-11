@echo off
echo.
echo Preparing symbolic links for WebRTC...
echo.

set failure=0

if EXIST ..\bin\nul call:failure -1 "Do not run scripts from bin directory!"
if "%failure%" neq "0" goto:done_with_error


call:dolink . build ..\webrtc-deps\build
if "%failure%" neq "0" goto:done_with_error

call:make_directory chromium\src
call:make_directory chromium\src\third_party

call:dolink . chromium\src\third_party\yasm ..\webrtc-deps\chromium\third_party\yasm
if "%failure%" neq "0" goto:done_with_error

call:dolink . chromium\src\third_party\opus ..\webrtc-deps\chromium\third_party\opus
if "%failure%" neq "0" goto:done_with_error

call:dolink . chromium\src\third_party\colorama ..\webrtc-deps\chromium\third_party\colorama
if "%failure%" neq "0" goto:done_with_error

call:dolink . chromium\src\third_party\boringssl ..\webrtc-deps\chromium\third_party\boringssl
if "%failure%" neq "0" goto:done_with_error

call:dolink . chromium\src\third_party\usrsctp ..\webrtc-deps\chromium\third_party\usrsctp
if "%failure%" neq "0" goto:done_with_error

call:dolink . chromium\src\testing ..\webrtc-deps\chromium\testing
if "%failure%" neq "0" goto:done_with_error

rem call:dolink . chromium\src ..\webrtc-deps\chromium
if "%failure%" neq "0" goto:done_with_error

call:dolink . testing chromium\src\testing
if "%failure%" neq "0" goto:done_with_error

call:dolink . tools\protoc_wrapper chromium\src\tools\protoc_wrapper
if "%failure%" neq "0" goto:done_with_error

call:dolink . third_party\yasm chromium\src\third_party\yasm
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\yasm\binaries ..\webrtc-deps\yasm\binaries
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\yasm\source\patched-yasm ..\webrtc-deps\patched-yasm
if "%failure%" neq "0" goto:done_with_error

call:dolink . third_party\opus chromium\src\third_party\opus
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\opus\src ..\webrtc-deps\opus
if "%failure%" neq "0" goto:done_with_error

call:dolink . third_party\colorama chromium\src\third_party\colorama
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\colorama\src ..\webrtc-deps\colorama
if "%failure%" neq "0" goto:done_with_error

call:dolink . third_party\boringssl chromium\src\third_party\boringssl
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\boringssl\src ..\webrtc-deps\boringssl
if "%failure%" neq "0" goto:done_with_error

call:dolink . third_party\usrsctp chromium\src\third_party\usrsctp
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\usrsctp\usrsctplib ..\webrtc-deps\usrsctp
if "%failure%" neq "0" goto:done_with_error

call:dolink . third_party\protobuf chromium\src\third_party\protobuf
if "%failure%" neq "0" goto:done_with_error

call:dolink . third_party\libsrtp ..\webrtc-deps\libsrtp
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\libvpx ..\webrtc-deps\libvpx
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\libyuv ..\webrtc-deps\libyuv
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\openmax_dl ..\webrtc-deps\openmax
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\libjpeg_turbo ..\webrtc-deps\libjpeg_turbo
if "%failure%" neq "0" goto:done_with_error
call:dolink . tools\gyp ..\webrtc-deps\gyp
if "%failure%" neq "0" goto:done_with_error


call:make_directory third_party\jsoncpp
copy ..\..\bin\bogus_jsoncpp.gyp third_party\jsoncpp\jsoncpp.gyp

call:make_directory third_party\expat
copy ..\..\bin\bogus_expat.gyp third_party\expat\expat.gyp

python webrtc\build\gyp_webrtc -Denable_protobuf=0 -Dbuild_with_libjingle=0


goto:done

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

:make_directory
if NOT EXIST %~1\nul mkdir %~1
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

exit /b %failure%
goto:eof

:done

echo.
echo Success: WebRTC ready.
echo.
