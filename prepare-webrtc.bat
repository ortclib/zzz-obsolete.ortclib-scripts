@echo off
echo.
echo Preparing symbolic links for WebRTC...
echo.

set failure=0

set TARGET=%~1
iF /I "%TARGET%"=="phone" set TARGET=phone
iF /I NOT "%TARGET%"=="phone" set TARGET=desktop

echo WebRTC target is %TARGET%...

if EXIST ..\bin\nul call:failure -1 "Do not run scripts from bin directory!"
if "%failure%" neq "0" goto:done_with_error

where python > NUL 2>&1
if ERRORLEVEL 1 call:setup_python
if "%failure%" neq "0" goto:done_with_error

where python > NUL 2>&1
if ERRORLEVEL 1 call:failure %errorlevel% "Could not locate python for windows"
if "%FAILURE%" NEQ "0" goto:eof

call:dolink . build ..\webrtc-deps\build
if "%failure%" neq "0" goto:done_with_error

call:make_directory chromium\src
call:make_directory chromium\src\third_party
call:make_directory chromium\src\tools

call:dolink . chromium\src\third_party\jsoncpp ..\webrtc-deps\chromium\third_party\jsoncpp
if "%failure%" neq "0" goto:done_with_error

call:dolink . chromium\src\third_party\jsoncpp\source ..\webrtc-deps\jsoncpp
if "%failure%" neq "0" goto:done_with_error

call:dolink . chromium\src\tools\protoc_wrapper ..\webrtc-deps\chromium\tools\protoc_wrapper
if "%failure%" neq "0" goto:done_with_error

call:dolink . chromium\src\third_party\protobuf ..\webrtc-deps\chromium\third_party\protobuf
if "%failure%" neq "0" goto:done_with_error

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

call:dolink . third_party\protobuf chromium\src\third_party\protobuf
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
call:dolink . third_party\jsoncpp chromium\src\third_party\jsoncpp
if "%failure%" neq "0" goto:done_with_error
call:dolink . tools\gyp ..\webrtc-deps\gyp
if "%failure%" neq "0" goto:done_with_error
call:dolink . testing\gtest ..\webrtc-deps\gtest
if "%failure%" neq "0" goto:done_with_error


call:make_directory third_party\expat
copy ..\..\bin\bogus_expat.gyp third_party\expat\expat.gyp

set DEPOT_TOOLS_WIN_TOOLCHAIN=0
set GYP_GENERATORS=msvs-winrt

iF /I "%TARGET%"=="phone" python webrtc\build\gyp_webrtc -Dbuild_with_libjingle=0 -Dwinrt_platform=win_phone
iF /I NOT "%TARGET%"=="phone" python webrtc\build\gyp_webrtc -Dbuild_with_libjingle=0

if %errorlevel% neq 0 call:failure %errorlevel% "Could not generate projects for WebRTC"
if "%failure%" neq "0" goto:done_with_error

goto:done

:setup_python

if NOT EXIST \Python27\nul call:failure -1 "Could not locate python path"
if "%failure%" neq "0" goto:eof

set PATH=%PATH%;\Python27

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
