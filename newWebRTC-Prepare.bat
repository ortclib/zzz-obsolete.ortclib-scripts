:: Name:     newWebRTC-Prepare.bat
:: Purpose:  Prepare webrtc to be buildable
:: Author:   Sergej Jovanovic
:: Email:	 sergej@gnedo.com
:: Revision: September 2016 - initial version

@ECHO off

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
set taskFailed=0

::platfroms
SET platform_ARM=1
SET platfrom_x86=1
SET platfrom_x64=1

::log variables
SET globalLogLevel=2											

SET error=0														
SET info=1														
SET warning=2													
SET debug=3														
SET trace=4	

::input arguments
SET supportedInputArguments=;platform;help;logLevel;diagnostic;					
SET platform=all
SET help=0
SET logLevel=2
SET diagnostic=0

::predefined messages
SET folderStructureError="WebRTC invalid folder structure."

::path constants
SET baseWebRTCPath=webrtc\xplatform\webrtc

ECHO.
CALL:print %info% "Running WebRTC prepare script ..."
ECHO.

:parseInputArguments
IF "%1"=="" (
	IF NOT "%nome%"=="" (
		SET "%nome%=1"
		SET nome=""
		
	) ELSE (
		GOTO:main
	)
)
SET aux=%1
IF "%aux:~0,1%"=="-" (
	IF NOT "%nome%"=="" (
		SET "%nome%=1"
	)
   SET nome=%aux:~1,250%
   SET validArgument=0
   CALL:checkIfArgumentIsValid !nome! validArgument
   IF !validArgument!==0 CALL:error 1 %errorMessageInvalidArgument%
) ELSE (
	IF NOT "%nome%"=="" (
		SET "%nome%=%1"
	) else (
		CALL:error 1 %errorMessageInvalidArgument%
	)
   SET nome=
)

SHIFT
GOTO parseInputArguments

::===========================================================================
:: Start execution of main flow (if parsing input parameters passed without issues)

:main

CALL:identifyPlatform

CALL:prepareWebRTC

GOTO:EOF

::===========================================================================

REM check if entered valid input argument
:checkIfArgumentIsValid
IF "!supportedInputArguments:;%~1;=!" neq "%supportedInputArguments%" (
	::it is valid
	SET %2=1
) ELSE (
	::it is not valid
	SET %2=0
)
GOTO:EOF

REM Based on input arguments determine targeted platforms (x64, x86 or ARM)
:identifyPlatform
SET validInput=0
SET messageText=

IF /I "%platfrom%"=="all" (
	SET platform_ARM=1
	SET platform_x64=1
	SET platform_x86=1
	SET validInput=1
	SET messageText=Preparing development environment for ARM, x64 and x86 platforms ...
) ELSE (
	IF /I "%platfrom%"=="arm" (
		SET platform_ARM=1
		SET validInput=1
	)
	
	IF /I "%platfrom%"=="x64" (
		SET platform_x64=1
		SET validInput=1
	)

	IF /I "%platfrom%"=="x86" (
		SET platform_x86=1
		SET validInput=1
	)
	
	IF !validInput!==1 (
		SET messageText=Preparing development environment for %platfrom% platform...
	)
)

:prepareWebRTC

IF NOT EXIST %baseWebRTCPath% CALL:error 1 "%folderStructureError:"=% %baseWebRTCPath% does not exist!"

PUSHD %baseWebRTCPath% > NUL

CALL:generateChromiumFolders

CALL:makeJunctionLinks

CALL:generateProjects

popd

GOTO:EOF

:generateChromiumFolders

CALL:makeDirectory chromium\src
CALL:makeDirectory chromium\src\tools
CALL:makeDirectory chromium\src\third_party
CALL:makeDirectory chromium\src\third_party\libjingle\source\talk\media\testdata\

GOTO:EOF

:makeJunctionLinks

CALL:makeLink . build ..\chromium-pruned\build
CALL:makeLink . chromium\src\third_party\jsoncpp ..\chromium-pruned\third_party\jsoncpp
CALL:makeLink . chromium\src\third_party\jsoncpp\source ..\jsoncpp
CALL:makeLink . chromium\src\tools\protoc_wrapper ..\chromium-pruned\tools\protoc_wrapper
CALL:makeLink . chromium\src\third_party\protobuf ..\chromium-pruned\third_party\protobuf
CALL:makeLink . chromium\src\third_party\yasm ..\chromium-pruned\third_party\yasm
CALL:makeLink . chromium\src\third_party\opus ..\chromium-pruned\third_party\opus
::CALL:makeLink . chromium\src\third_party\colorama ..\chromium-pruned\third_party\colorama
CALL:makeLink . chromium\src\third_party\boringssl ..\chromium-pruned\third_party\boringssl
CALL:makeLink . chromium\src\third_party\usrsctp ..\chromium-pruned\third_party\usrsctp
CALL:makeLink . chromium\src\third_party\libvpx_new ..\chromium-pruned\third_party\libvpx_new
CALL:makeLink . chromium\src\third_party\libvpx_new\source\libvpx ..\libvpx
CALL:makeLink . chromium\src\testing ..\chromium-pruned\testing
CALL:makeLink . testing chromium\src\testing
CALL:makeLink . tools\protoc_wrapper chromium\src\tools\protoc_wrapper
CALL:makeLink . third_party\protobuf chromium\src\third_party\protobuf
CALL:makeLink . third_party\yasm chromium\src\third_party\yasm
CALL:makeLink . third_party\yasm\binaries ..\yasm\binaries
CALL:makeLink . third_party\yasm\source\patched-yasm ..\patched-yasm
CALL:makeLink . third_party\opus chromium\src\third_party\opus
CALL:makeLink . third_party\opus\src ..\opus
::CALL:makeLink . third_party\colorama chromium\src\third_party\colorama
::CALL:makeLink . third_party\colorama\src ..\webrtc-deps\colorama
CALL:makeLink . third_party\boringssl chromium\src\third_party\boringssl
CALL:makeLink . third_party\boringssl\src ..\boringssl
CALL:makeLink . third_party\usrsctp chromium\src\third_party\usrsctp
CALL:makeLink . third_party\usrsctp\usrsctplib ..\usrsctp
CALL:makeLink . third_party\protobuf chromium\src\third_party\protobuf
CALL:makeLink . third_party\libsrtp ..\libsrtp
CALL:makeLink . third_party\libvpx_new .\chromium\src\third_party\libvpx_new
CALL:makeLink . third_party\libyuv ..\libyuv
CALL:makeLink . third_party\openmax_dl ..\openmax
CALL:makeLink . third_party\libjpeg_turbo ..\libjpeg_turbo
CALL:makeLink . third_party\jsoncpp chromium\src\third_party\jsoncpp
CALL:makeLink . third_party\gflags\src ..\gflags
::CALL:makeLink . third_party\winsdk_samples\src ..\winsdk_samples_v71
CALL:makeLink . tools\gyp ..\gyp
CALL:makeLink . tools\clang ..\chromium-pruned\tools\clang
CALL:makeLink . testing\gtest ..\googletest
CALL:makeLink . testing\gmock ..\googlemock
GOTO:EOF

:generateProjects
SET DEPOT_TOOLS_WIN_TOOLCHAIN=0


IF %platform_ARM% EQU 1(
	ECHO.
	CALL:print 2 Generating WebRTC projects for ARM platfrom
	ECHO.
	SET GYP_DEFINES=
	SET GYP_GENERATORS=msvs-winrt
	PYTHON webrtc\build\gyp_webrtc -Dwinrt_platform=win10 -Dtarget_arch=arm
	IF %errorlevel% NEQ 0 CALL:error 1 "Could not generate WebRTC projects for ARM platfrom"
)

IF %platform_x64% EQU 1(
	ECHO.
	CALL:print 2 Generating WebRTC projects for x64 platfrom
	ECHO.
	SET GYP_DEFINES=
	SET GYP_GENERATORS=msvs-winrt
	PYTHON webrtc\build\gyp_webrtc -Dwinrt_platform=win10 -Dtarget_arch=x64
	IF %errorlevel% NEQ 0 CALL:error 1 "Could not generate WebRTC projects for x64 platfrom"
)

IF %platform_x86% EQU 1(
	ECHO.
	CALL:print 2 Generating WebRTC projects for x86 platfrom
	ECHO.
	SET GYP_DEFINES=
	SET GYP_GENERATORS=msvs-winrt
	PYTHON webrtc\build\gyp_webrtc -Dwinrt_platform=win10
	IF %errorlevel% NEQ 0 CALL:error 1 "Could not generate WebRTC projects for x86 platfrom"
)
GOTO:EOF

:makeDirectory
IF NOT EXIST %~1\NUL MKDIR %~1
GOTO:EOF

:makeLink
IF NOT EXIST %~1\NUL CALL:error 1 "%folderStructureError:"=% %~1 does not exist!"

PUSHD %~1

IF EXIST .\%~2\NUL GOTO:alreadyexists
IF NOT EXIST %~3\NUL CALL:error 1 "%folderStructureError:"=% %~3 does not exist!"

CALL:print %trace% In path "%~1" creating symbolic link for "%~2" to "%~3"

MKLINK /J %~2 %~3
IF %ERRORLEVEL% NEQ 0 CALL:ERROR 1 "COULD NOT CREATE SYMBOLIC LINK TO %~2 FROM %~3"

POPD

GOTO:EOF

:print
SET logType=%1
SET logMessage=%~2

if %logLevel% GEQ  %logType% (
	if %logType%==0 ECHO [91m%logMessage%[0m
	if %logType%==1 ECHO [92m%logMessage%[0m
	if %logType%==2 ECHO [93m%logMessage%[0m
	if %logType%==3 ECHO [95m%logMessage%[0m
)

GOTO:EOF

:error
SET criticalError=%~1
SET errorMessage=%~2

IF %criticalError%==0 (
	ECHO.
	CALL:print %warning% "WARNING: %errorMessage%"
	ECHO.
) ELSE (
	ECHO.
	CALL:print %error% "CRITICAL ERROR: %errorMessage%"
	ECHO.
	ECHO.
	CALL:print %error% "FAILURE:Preparing environment has failed!"
	ECHO.
	::terminate batch execution
	CALL bin\batchTerminator.bat
)
GOTO:EOF

:done
ECHO.
CALL:print %info% "Success: Development environment is set."
ECHO. 
