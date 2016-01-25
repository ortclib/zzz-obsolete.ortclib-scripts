@echo off
echo==============================================================================
echo.
echo Preparing symbolic links for WebRTC...
echo.
echo.

set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe

set PLATFORM=%~1
echo Platform is "%PLATFORM%"
echo
if EXIST ..\bin\nul call:failure -1 "Do not run scripts from bin directory!"
if "%failure%" neq "0" goto:done_with_error

where python > NUL 2>&1
if ERRORLEVEL 1 call:install_python
if "%failure%" NEQ "0" goto:eof

where python > NUL 2>&1
if ERRORLEVEL 1 call:setup_python
if "%failure%" neq "0" goto:done_with_error

rem where perl > NUL 2>&1
rem if ERRORLEVEL 1 call:install_perl
rem if "%failure%" NEQ "0" goto:eof

rem where perl > NUL 2>&1
rem if ERRORLEVEL 1 call:setup_perl
rem if "%failure%" neq "0" goto:done_with_error

call:dolink . build ..\webrtc-deps\chromium\build
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

call:dolink . chromium\src\third_party\libvpx_new ..\webrtc-deps\chromium\third_party\libvpx_new
if "%failure%" neq "0" goto:done_with_error

call:dolink . chromium\src\third_party\libvpx_new\source\libvpx ..\webrtc-deps\libvpx
if "%failure%" neq "0" goto:done_with_error

call:dolink . chromium\src\testing ..\webrtc-deps\chromium\testing
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
call:dolink . third_party\libvpx_new .\chromium\src\third_party\libvpx_new
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\libyuv ..\webrtc-deps\libyuv
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\openmax_dl ..\webrtc-deps\openmax
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\libjpeg_turbo ..\webrtc-deps\libjpeg_turbo
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\jsoncpp chromium\src\third_party\jsoncpp
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\gflags\src ..\webrtc-deps\gflags
if "%failure%" neq "0" goto:done_with_error
call:dolink . third_party\winsdk_samples\src ..\webrtc-deps\winsdk_samples_v71
if "%failure%" neq "0" goto:done_with_error
call:dolink . tools\gyp ..\webrtc-deps\gyp
if "%failure%" neq "0" goto:done_with_error
call:dolink . tools\clang ..\webrtc-deps\chromium\tools\clang
if "%failure%" neq "0" goto:done_with_error
call:dolink . testing\gtest ..\webrtc-deps\googletest
if "%failure%" neq "0" goto:done_with_error
call:dolink . testing\gmock ..\webrtc-deps\gmock
if "%failure%" neq "0" goto:done_with_error

call:make_directory third_party\expat
copy ..\..\bin\bogus_expat.gyp third_party\expat\expat.gyp

set DEPOT_TOOLS_WIN_TOOLCHAIN=0

if /I "%PLATFORM%"=="win32" (
	echo.
	echo Generating Win32 projects
	echo.
	set GYP_DEFINES=component=shared_library
	set GYP_GENERATORS=ninja,msvs-ninja
	python webrtc/build/gyp_webrtc -Goutput_dir=build_win32 -G msvs_version=2013
)

if /I "%PLATFORM%"=="winrt" (
	echo.
	echo Generating winRT and winRT_Phone projects
	echo.
	set GYP_DEFINES=
	set GYP_GENERATORS=msvs-winrt
	python webrtc\build\gyp_webrtc -Mwin -Mwin_phone
)

if %errorlevel% neq 0 call:failure %errorlevel% "Could not generate projects for WebRTC"
if "%failure%" neq "0" goto:done_with_error



goto:done

:setup_python

if NOT EXIST C:\Python27\nul call:failure -1 "Could not locate python path"
if "%failure%" neq "0" goto:eof

call:set_path "C:\Python27"

rem setx PATH "%PATH%;C:\Python27" /m
rem set PATH=%PATH%;C:\Python27

goto:eof

:install_python

echo Installing Python

call:download https://www.python.org/ftp/python/2.7.6/python-2.7.6.msi  python-2.7.6.msi
if "%FAILURE%" NEQ "0" (
	echo "Failed downloading python."
	goto:eof
) else (
	start "Python install" /wait msiexec /i python-2.7.6.msi /quiet
	if %errorlevel% neq 0 call:failure %errorlevel% "Could not install python."
	echo "Deleting downloaded file."
	del python-2.7.6.msi
)
goto:eof

:setup_perl

if NOT EXIST \Strawberry\c\bin\nul call:failure -1 "Could not locate perl path"
if "%failure%" neq "0" goto:eof

if NOT EXIST \Strawberry\perl\site\bin\nul call:failure -1 "Could not locate perl path"
if "%failure%" neq "0" goto:eof

if NOT EXIST \Strawberry\perl\bin\nul call:failure -1 "Could not locate perl path"
if "%failure%" neq "0" goto:eof

call:set_path "C:\Strawberry\c\bin"
rem setx PATH "%PATH%;C:\Strawberry\c\bin"
rem set PATH=%PATH%;C:\Strawberry\c\bin

call:set_path "C:\Strawberry\perl\site\bin"
rem setx PATH "%PATH%;C:\Strawberry\perl\site\bin"
rem set PATH=%PATH%;C:\Strawberry\perl\site\bin

call:set_path "C:\Strawberry\perl\bin"
rem setx PATH "%PATH%;C:\Strawberry\perl\bin"
rem set PATH=%PATH%;C:\Strawberry\perl\bin
goto:eof

:install_perl

echo Installing Perl

call:download http://strawberryperl.com/download/5.22.0.1/strawberry-perl-5.22.0.1-32bit.msi  strawberry-perl-5.22.0.1-32bit.msi
if "%FAILURE%" NEQ "0" (
	echo "Failed downloading perl."
	goto:eof
) else (
	echo Started instalation
	start "Perl install" /wait msiexec /i strawberry-perl-5.22.0.1-32bit.msi /quiet
	echo Instalation finished
	
	if %errorlevel% neq 0 call:failure %errorlevel% "Could not install python."
	echo "Deleting downloaded file."
	del strawberry-perl-5.22.0.1-32bit.msi
)
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
	
:download
if EXIST %~2 goto:eof

%powershell_path% "Start-BitsTransfer %~1 -Destination %~2"
if ERRORLEVEL 1 call:failure %errorlevel% "Could not download %~2"
if "%FAILURE%" NEQ "0" goto:eof
echo.
echo Downloaded %~1
echo.
goto:eof
:set_path
if "%~1"=="" exit /b 2
if not defined path exit /b 2
echo called method with paramter %~1
::
:: Determine if function was called while delayed expansion was enabled
setlocal
set "NotDelayed=!"
::
:: Prepare to safely parse PATH into individual paths
setlocal DisableDelayedExpansion
set "var=%path:"=""%"
set "var=%var:^=^^%"
set "var=%var:&=^&%"
set "var=%var:|=^|%"
set "var=%var:<=^<%"
set "var=%var:>=^>%"
set "var=%var:;=^;^;%"
set var=%var:""="%
set "var=%var:"=""Q%"
set "var=%var:;;="S"S%"
set "var=%var:^;^;=;%"
set "var=%var:""="%"
setlocal EnableDelayedExpansion
set "var=!var:"Q=!"
set "var=!var:"S"S=";"!"
::
:: Remove quotes from pathVar and abort if it becomes empty
rem set "new=!%~1:"^=!"
set new=%~1

if not defined new exit /b 2
::
:: Determine if pathVar is fully qualified
echo("!new!"|findstr /i /r /c:^"^^\"[a-zA-Z]:[\\/][^\\/]" ^
                           /c:^"^^\"[\\][\\]" >nul ^
  && set "abs=1" || set "abs=0"
::
:: For each path in PATH, check if path is fully qualified and then
:: do proper comparison with pathVar. Exit if a match is found.
:: Delayed expansion must be disabled when expanding FOR variables
:: just in case the value contains !
for %%A in ("!new!\") do for %%B in ("!var!") do (
  if "!!"=="" setlocal disableDelayedExpansion
  for %%C in ("%%~B\") do (
    echo(%%B|findstr /i /r /c:^"^^\"[a-zA-Z]:[\\/][^\\/]" ^
                           /c:^"^^\"[\\][\\]" >nul ^
      && (if %abs%==1 if /i "%%~sA"=="%%~sC" exit /b 0) ^
      || (if %abs%==0 if /i %%A==%%C exit /b 0)
  )
)
::
:: Build the modified PATH, enclosing the added path in quotes
:: only if it contains ;
setlocal enableDelayedExpansion
if "!new:;=!" neq "!new!" set new="!new!"
if /i "%~2"=="/B" (set "rtn=!new!;!path!") else set "rtn=!path!;!new!"
::
:: rtn now contains the modified PATH. We need to safely pass the
:: value accross the ENDLOCAL barrier
::
:: Make rtn safe for assignment using normal expansion by replacing
:: % and " with not yet defined FOR variables
set "rtn=!rtn:%%=%%A!"
set "rtn=!rtn:"=%%B!"
::
:: Escape ^ and ! if function was called while delayed expansion was enabled.
:: The trailing ! in the second assignment is critical and must not be removed.
if not defined NotDelayed set "rtn=!rtn:^=^^^^!"
if not defined NotDelayed set "rtn=%rtn:!=^^^!%" !
::
:: Pass the rtn value accross the ENDLOCAL barrier using FOR variables to
:: restore the % and " characters. Again the trailing ! is critical.
for /f "usebackq tokens=1,2" %%A in ('%%^ ^"') do (
  endlocal & endlocal & endlocal & endlocal & endlocal
  set "path=%rtn%" !
)
Powershell.exe -NoProfile -ExecutionPolicy Bypass -command "[Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::User)"
goto:eof
:set_path4

for /F "tokens=2* delims= " %%f IN ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path ^| findstr /i path') do set OLD_SYSTEM_PATH=%%g
setx.exe PATH ";%OLD_SYSTEM_PATH%;%~1"
set PATH=%OLD_SYSTEM_PATH%;%~1
 rem setx PATH "%PATH%;%~1"
 rem set PATH=%PATH%;%~1
 echo "%~1 added to path"
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
