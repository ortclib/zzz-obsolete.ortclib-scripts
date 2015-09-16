@echo off
echo.
echo Preparing ortc-lib-sdk...
echo.

set failure=0

if EXIST ..\bin\nul call:failure -1 "Do not run scripts from bin directory!"
if "%failure%" neq "0" goto:eof

call:doprepare libs\webrtc ..\..\bin\prepare-webrtc.bat WebRTC winrt
if "%failure%" neq "0" goto:eof

call:doprepare libs\webrtc ..\..\bin\prepare-webrtc.bat WebRTC win32
if "%failure%" neq "0" goto:eof

call:doprepare libs\curl prepare.bat curl
if "%failure%" neq "0" goto:eof

where perl > NUL 2>&1
if %errorlevel% equ 1 (
	echo.
	echo ================================================================================
	echo.
	echo Warning! Warning! Warning! Warning! Warning! Warning! Warning!
	echo.
	echo Perl is missing.
	echo You need to have installed Perl to build projects properly.
	echo Use the 32-bit perl from Strawberry http://strawberryperl.com/ to avoid possible linking errors and incorrect assember files generation. 
	echo Download URL: http://strawberryperl.com/download/5.22.0.1/strawberry-perl-5.22.0.1-32bit.msi
	echo Make sure that the perl path from Strawberry appears at the beginning of all other perl paths in the PATH 
	echo.
	echo ================================================================================
	echo.
)

goto:done


:doprepare

if NOT EXIST %~1\%~2 call:failure -1 "Did not find %~3 preparation script in %~1\%~2!"
if "%failure%" neq "0" goto:eof

pushd %~1 > NUL
if ERRORLEVEL 1 call:failure %errorlevel% "%~3 preparation failed."
call %~2 %~4%
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
