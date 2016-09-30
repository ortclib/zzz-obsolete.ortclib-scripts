@echo off

setlocal enabledelayedexpansion
set failure=0
set cleanWebrtc_platform=%1
set cleanWebrtc_configuration=%2

set cleanWebrtc_x86=0
set cleanWebrtc_x64=0
set cleanWebrtc_arm=0

set cleanWebrtc_Debug=0
set cleanWebrtc_Release=0

set webrtcPath_x64=libs\webrtc\build_win10_x64\
set webrtcPath_x86=libs\webrtc\build_win10_x86\
set webrtcPath_ARM=libs\webrtc\build_win10_arm\
set webrtcPath=libs\webrtc\WEBRTC_BUILD\
set isEmpty=1

if EXIST ..\bin\nul call:failure -1 "Do not run scripts from bin directory!"
if "%failure%" neq "0" goto:eof

call:checkWebrtcCleanupRequest
call:deleteWebrtc
goto:eof
:checkWebrtcCleanupRequest
call:checkWebrtcPlatformCleanupRequest
call:checkWebrtcConfigurationCleanupRequest
goto:eof

:checkWebrtcPlatformCleanupRequest

if /i "%cleanWebrtc_platform%"=="" (
	echo Webrtc lib will be deleted for all platforms.
	set cleanWebrtc_x86=1
	set cleanWebrtc_x64=1
	set cleanWebrtc_arm=1
	goto:eof
)
	
if /i "%cleanWebrtc_platform%"=="x86" (
	echo Webrtc lib will be deleted for x86 platform.
	set cleanWebrtc_x86=1
	set cleanWebrtc_x64=0
	set cleanWebrtc_arm=0
	goto:eof
)

if /i "%cleanWebrtc_platform%"=="x64" (
	echo Webrtc lib will be deleted for x64 platform.
	set cleanWebrtc_x86=0
	set cleanWebrtc_x64=1
	set cleanWebrtc_arm=0
	goto:eof
)

if /i "%cleanWebrtc_platform%"=="arm" (
	echo Webrtc lib will be deleted for arm platform.
	set cleanWebrtc_x86=0
	set cleanWebrtc_x64=0
	set cleanWebrtc_arm=1
	goto:eof
)

echo Webrtc won't be deleted.
goto:eof


:checkWebrtcConfigurationCleanupRequest
if /I "%cleanWebrtc_configuration%"=="release" (
	set cleanWebrtc_Release=1
	echo Webrtc lib will be deleted for release configuration.
) else (
	if /I "%cleanWebrtc_configuration%"=="debug" (
		set cleanWebrtc_Debug=1
		echo Webrtc lib will be deleted for debug configuration.
	) else (
		set cleanWebrtc_Release=1
		set cleanWebrtc_Debug=1
		echo Webrtc lib will be deleted for all configurations.
	)
)
goto:eof
:deleteWebrtc


echo Cleaning webrtc ...

if "%cleanWebrtc_x86%" equ "1" (
	if "%cleanWebrtc_Debug%" equ "1" (
		if EXIST "%webrtcPath_x86%Debug" rmdir /s /q "%webrtcPath_x86%Debug"
		if EXIST "%webrtcPath%Debug\X86" rmdir /s /q "%webrtcPath%Debug\X86"
	) 
	
	if "%cleanWebrtc_Release%" equ "1" (
	echo birise se "%webrtcPath_x86%Release"
		if EXIST "%webrtcPath_x86%Release" rmdir /s /q "%webrtcPath_x86%Release"
		if EXIST "%webrtcPath%Release\X86" rmdir /s /q "%webrtcPath%Release\X86"
	) 
)

if "%cleanWebrtc_x64%" equ "1" (
	if "%cleanWebrtc_Debug%" equ "1" (
		if EXIST "%webrtcPath_x64%Debug" rmdir /s /q "%webrtcPath_x64%Debug"
		if EXIST "%webrtcPath%Debug\X64" rmdir /s /q "%webrtcPath%Debug\X64"
	) 
	
	if "%cleanWebrtc_Release%" equ "1" (
		if EXIST "%webrtcPath_x64%Release" rmdir /s /q "%webrtcPath_x64%Release"
		if EXIST "%webrtcPath%Release\X64" rmdir /s /q "%webrtcPath%Release\X64"
	)
)

if "%cleanWebrtc_arm%" equ "1" (
	if "%cleanWebrtc_Debug%" equ "1" (
		if EXIST "%webrtcPath_ARM%Debug" rmdir /s /q "%webrtcPath_ARM%Debug"
		if EXIST "%webrtcPath%Debug\ARM" rmdir /s /q "%webrtcPath%Debug\ARM"
	) 
	
	if "%cleanWebrtc_Release%" equ "1" (
		if EXIST "%webrtcPath_ARM%Release" rmdir /s /q "%webrtcPath_ARM%Release"
		if EXIST "%webrtcPath%Release\ARM" rmdir /s /q "%webrtcPath%Release\ARM"
	)
)

call:deleteFolder %webrtcPath%Debug\
call:deleteFolder %webrtcPath%Release\
call:deleteFolder %webrtcPath%
call:deleteFolder %webrtcPath_x86%
call:deleteFolder %webrtcPath_ARM%
goto:eof
:deleteFolder

call:isFolderEmpty %1

if "%isEmpty%" equ "1" (
	echo Deleting %1
	rmdir /s /q %1
)
goto:eof
:isFolderEmpty
set isEmpty=0
if exist %1 (
	for /F %%i in ('dir /b "%1*.*"') do (
		echo %1 is not empty
		::set isEmpty=0
		goto:eof
	)
	set isEmpty=1
	echo %1 is empty
)

goto:eof

:failure
echo.

echo ERROR: %~2

echo.
echo FAILURE: Could not prepare ortc-lib-sdk.

set failure=%~1

goto:eof

:done
echo Finished webrtc cleanup