:: Name:     prepareWebRtc.bat
:: Purpose:  Prepare webrtc to be buildable
:: Author:   Sergej Jovanovic
:: Email:	 sergej@gnedo.com
:: Revision: September 2016 - initial version

@ECHO off

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
set taskFailed=0

::platforms
SET platform_ARM=0
SET platform_x86=0
SET platform_x64=0
SET platform_win32=0
SET platform_win32_x64=0
::platforms
SET platform_ARM_prepared=0
SET platform_x86_prepared=0
SET platform_x64_prepared=0
SET platform_win32_prepared=0
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
SET errorMessageInvalidArgument="Invalid input argument. For the list of available arguments and usage examples, please run script with -help option."
SET errorMessageInvalidPlatform="Invalid platform name. For the list of available targets and usage examples, please run script with -help option."
SET errorMessageMissingDebuggerTools="Windows SDK is not fully installed. Debugger Tools are missing. Please install standalone Windows SDK version. You can download installer from this link https://developer.microsoft.com/de-de/windows/downloads/sdk-archive"

::path constants
SET baseWebRTCPath=webrtc\xplatform\webrtc
SET webRtcLibsTemplatePath=webrtc\windows\templates\libs\webrtc
SET webRtcx64TemplatePath=webrtc\windows\templates\libs\webrtc\WebRtc.x64.sln
SET webRtcx86TemplatePath=webrtc\windows\templates\libs\webrtc\WebRtc.x86.sln
rem SET webRTCDestinationPath=webrtc\xplatform\webrtc\webrtcLib.sln

SET webRTCGnArgsTemplatePath=..\..\..\webrtc\windows\templates\gns\args.gn

SET stringToUpdateWithSDKVersion='WindowsTargetPlatformVersion', '10.0.10240.0'
SET pythonFilePathToUpdateSDKVersion=webrtc\xplatform\webrtc\tools\gyp\pylib\gyp\generator\msvs.py
ECHO.
CALL:print %info% "Running WebRTC prepare script ..."
CALL:print %info% "================================="
::ECHO.

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

IF /I "%platform%"=="all" (
	SET platform_ARM=0
	SET platform_x64=1
	SET platform_x86=1
	SET platform_win32=1
	SET validInput=1
	SET messageText=Preparing WebRTC development environment for arm, x64, x86 and win32 platforms ...
) ELSE (
	IF /I "%platform%"=="arm" (
		SET platform_ARM=1
		SET validInput=1
	)
	
	IF /I "%platform%"=="x64" (
		SET platform_x64=1
		SET validInput=1
	)

	IF /I "%platform%"=="x86" (
		SET platform_x86=1
		SET validInput=1
	)
	
	IF /I "%platform%"=="win32" (
		SET platform_win32=1
		SET validInput=1
	)
	
	IF /I "%platform%"=="win32_x64" (
		SET platform_win32_x64=1
		SET validInput=1
	)
	
	IF !validInput!==1 (
		SET messageText=Preparing WebRTC development environment for %platform% platform ...
	)
)

:: If input is not valid terminate script execution
IF !validInput!==1 (
	CALL:print %warning% "!messageText!"
) ELSE (
	CALL:error 1 %errorMessageInvalidPlatform%
)
GOTO:EOF

:prepareWebRTC
CALL:print %trace% "Executing prepareWebRTC function"

IF NOT EXIST %baseWebRTCPath% CALL:error 1 "%folderStructureError:"=% %baseWebRTCPath% does not exist!"



PUSHD %baseWebRTCPath% > NUL
CALL:print %trace% "Pushed %baseWebRTCPath% path"

CALL:generateChromiumFolders

CALL:makeJunctionLinks

CALL:updateFolders

CALL:setupDepotTools

CALL:downloadGnBinaries
POPD
CALL:updateSDKVersion
PUSHD %baseWebRTCPath% > NUL

::CALL:gflagsPatchBuild
CALL:generateProjects

POPD
CALL:print %trace% "Popped %baseWebRTCPath% path"

rem CALL:copyTemplates %webRTCTemplatePath% %webRTCDestinationPath%

CALL:done

GOTO:EOF

:generateChromiumFolders
CALL:print %trace% "Executing generateChromiumFolders function"

CALL:makeDirectory chromium\src
CALL:makeDirectory chromium\src\tools
CALL:makeDirectory chromium\src\third_party
CALL:makeDirectory chromium\src\third_party\winsdk_samples
CALL:makeDirectory chromium\src\third_party\libjingle\source\talk\media\testdata\
CALL:makeDirectory third_party
::CALL:makeDirectory third_party\gflags
::CALL:makeDirectory third_party\winsdk_samples
CALL:makeDirectory tools

GOTO:EOF

:makeJunctionLinks
CALL:print %trace% "Executing makeJunctionLinks function"

CALL:makeLink . buildtools ..\buildtools
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
CALL:makeLink . chromium\src\third_party\libvpx ..\chromium-pruned\third_party\libvpx
CALL:makeLink . chromium\src\third_party\libvpx\source\libvpx ..\libvpx
CALL:makeLink . chromium\src\testing ..\chromium-pruned\testing
CALL:makeLink . testing chromium\src\testing
CALL:makeLink . tools\protoc_wrapper chromium\src\tools\protoc_wrapper
CALL:makeLink . third_party\yasm chromium\src\third_party\yasm
CALL:makeLink . third_party\yasm\binaries ..\yasm\binaries
CALL:makeLink . third_party\yasm\source\patched-yasm ..\yasm\patched-yasm
CALL:makeLink . third_party\opus chromium\src\third_party\opus
CALL:makeLink . third_party\opus\src ..\opus
::CALL:makeLink . third_party\colorama chromium\src\third_party\colorama
::CALL:makeLink . third_party\colorama\src ..\webrtc-deps\colorama
CALL:makeLink . third_party\boringssl chromium\src\third_party\boringssl
CALL:makeLink . third_party\boringssl\src ..\boringssl
CALL:makeLink . third_party\usrsctp chromium\src\third_party\usrsctp
CALL:makeLink . third_party\usrsctp\usrsctplib ..\usrsctp
CALL:makeLink . third_party\protobuf chromium\src\third_party\protobuf
CALL:makeLink . chromium\src\third_party\expat ..\chromium-pruned\third_party\expat
CALL:makeLink . third_party\expat chromium\src\third_party\expat
CALL:makeLink . third_party\libsrtp ..\libsrtp
CALL:makeLink . third_party\libvpx .\chromium\src\third_party\libvpx
CALL:makeLink . third_party\libyuv ..\libyuv
CALL:makeLink . third_party\openmax_dl ..\openmax
CALL:makeLink . third_party\libjpeg_turbo ..\libjpeg_turbo
CALL:makeLink . third_party\jsoncpp chromium\src\third_party\jsoncpp
CALL:makeLink . third_party\winuwp_compat ..\..\windows\third_party\winuwp_compat
CALL:makeLink . third_party\winuwp_h264 ..\..\windows\third_party\winuwp_h264
CALL:makeLink . third_party\gflags ..\gflags-build
CALL:makeLink . third_party\gflags\src ..\gflags
CALL:makeLink . third_party\winsdk_samples ..\winsdk_samples_v71
CALL:makeLink . tools\gyp ..\gyp
CALL:makeLink . tools\clang ..\chromium-pruned\tools\clang
CALL:makeLink . testing\gtest ..\googletest
CALL:makeLink . testing\gmock ..\googlemock

GOTO:EOF

:updateFolders

::XCopy  /S /I /Y ..\gflags-build third_party\gflags > NUL
::IF !errorlevel! NEQ 0 CALL:error 1 "Missing gn files for gflags"

COPY ..\chromium-pruned\third_party\BUILD.gn third_party\BUILD.gn 
COPY ..\chromium-pruned\third_party\DEPS third_party\DEPS 
COPY ..\chromium-pruned\third_party\OWNERS third_party\OWNERS 
COPY ..\chromium-pruned\third_party\PRESUBMIT.py third_party\PRESUBMIT.py 
GOTO:EOF

:setupDepotTools

PUSHD ..\depot_tools > NUL
set DepotToolsPath=%cd%
POPD > NUL

set CHECKSEMIPATH=%path:~-1%

WHERE gn.bat > NUL 2>&1
IF !ERRORLEVEL! EQU 1 (
    IF "%CHECKSEMIPATH%"==";" (
		set "PATH=%PATH%%DepotToolsPath%"
    ) ELSE (
		set "PATH=%PATH%;%DepotToolsPath%"
    )
)

GOTO:EOF

:downloadGnBinaries

IF NOT EXIST gn.exe CALL python %DepotToolsPath%\download_from_google_storage.py -b chromium-gn -s buildtools\win\gn.exe.sha1
IF !errorlevel! NEQ 0 CALL:error 1 "Failed downloading gn.exe"

IF NOT EXIST clang-format.exe CALL python %DepotToolsPath%\download_from_google_storage.py -b chromium-clang-format -s buildtools\win\clang-format.exe.sha1
IF !errorlevel! NEQ 0 CALL:error 1 "Failed downloading clang-format.exe"
GOTO:EOF

:gflagsPatchBuild

echo PATCHING GFLAGS...

set gflagsWindowsFolder=..\..\windows\third_party\winuwp_compat\gflags
set gflagsIgnore=.gitignore
set gflagsPatchFileName=patch_892576179b45861b53e04a112996a738309cf364.diff
set gflagsPatchFileNameApplied=%gflagsPatchFileName%.applied

IF NOT EXIST third_party\gflags\%gflagsIgnore% COPY %gflagsWindowsFolder%\%gflagsIgnore% third_party\gflags
IF NOT EXIST third_party\gflags\%gflagsPatchFileName% COPY %gflagsWindowsFolder%\%gflagsPatchFileName% third_party\gflags

IF NOT EXIST ..\gflags-build\%gflagsPatchFileNameApplied% (
	PUSHD ..\gflags-build > NUL
	git apply %gflagsPatchFileName%
	IF !ERRORLEVEL! NEQ 0 (
		set FailureGitApply=1
    )
	POPD > NUL
    IF !FailureGitApply! EQU 1 (
    	CALL:error 1 "Could not generate apply patch to webrtc\third_party\gflags using %gflagsWindowsFolder%\%gflagsPatchFileName%"
    )
)
IF NOT EXIST third_party\gflags\%gflagsPatchFileNameApplied% COPY %gflagsWindowsFolder%\%gflagsPatchFileName% third_party\gflags\%gflagsPatchFileNameApplied%

GOTO:EOF

:generateProjectsForPlatform

set IsDebugTarget=true
IF "%~3"=="release" (
	set IsDebugTarget=false
)
IF "%~3"=="debug" (
	set IsDebugTarget=true
)

SET outputPath=out\%~1_%~2_%~3
SET webRTCGnArgsDestinationPath=!outputPath!\args.gn
CALL:makeDirectory !outputPath!
CALL:copyTemplates %webRTCGnArgsTemplatePath% !webRTCGnArgsDestinationPath!

%powershell_path% -ExecutionPolicy ByPass -File ..\..\..\bin\TextReplaceInFile.ps1 !webRTCGnArgsDestinationPath! "-target_os-" "%~1" !webRTCGnArgsDestinationPath!
IF ERRORLEVEL 1 CALL:error 1 "Failed updating gn arguments for platfrom %~1"


%powershell_path% -ExecutionPolicy ByPass -File ..\..\..\bin\TextReplaceInFile.ps1 !webRTCGnArgsDestinationPath! "-target_cpu-" "%2" !webRTCGnArgsDestinationPath!
IF ERRORLEVEL 1 CALL:error 1 "Failed updating gn arguments for CPU %~2"

%powershell_path% -ExecutionPolicy ByPass -File ..\..\..\bin\TextReplaceInFile.ps1 !webRTCGnArgsDestinationPath! "-is_debug-" "%IsDebugTarget%" !webRTCGnArgsDestinationPath!
IF ERRORLEVEL 1 CALL:error 1 "Failed updating gn arguments for debug/release %IsDebugTarget%"

IF %logLevel% GEQ %trace% (
	CALL GN gen !outputPath! --ide="vs2015"
) ELSE (
	CALL GN gen !outputPath! --ide="vs2015" >NUL
)
IF !errorlevel! NEQ 0 CALL:error 1 "Could not generate WebRTC projects for %1 platform, %2 CPU"

%powershell_path% -ExecutionPolicy ByPass -File ..\..\..\bin\RecurseReplaceInFiles.ps1 !outputPath! *.vcxproj "call ninja.exe" "call %DepotToolsPath%\ninja.exe"

IF EXIST ..\..\..\%webRtcLibsTemplatePath%\WebRtc.%~2.sln CALL:copyTemplates ..\..\..\%webRtcLibsTemplatePath%\WebRtc.%~2.sln !outputPath!\WebRtc.sln
GOTO:EOF


:generateProjects
CALL:print %trace% "Executing generateProjects function"

SET DEPOT_TOOLS_WIN_TOOLCHAIN=0

IF %platform_ARM% EQU 1 (
	CALL:print %warning% "Generating WebRTC projects for arm platform ..."
	SET platform_ARM_prepared=1
	CALL:generateProjectsForPlatform winuwp_10 arm debug
	CALL:generateProjectsForPlatform winuwp_10 arm release
	SET platform_ARM_prepared=2
)

IF %platform_x64% EQU 1 (
	CALL:print %warning% "Generating WebRTC projects for x64 platform ..."
	SET platform_x64_prepared=1
	CALL:generateProjectsForPlatform winuwp_10 x64 debug
	CALL:generateProjectsForPlatform winuwp_10 x64 release
	SET platform_x64_prepared=2
)

IF %platform_x86% EQU 1 (
	CALL:print %warning% "Generating WebRTC projects for x86 platform ..."
	SET platform_x86_prepared=1
	CALL:generateProjectsForPlatform winuwp_10 x86 debug
	CALL:generateProjectsForPlatform winuwp_10 x86 release
	SET platform_x86_prepared=2
)

IF %platform_win32% EQU 1 (
	CALL:print %warning% "Generating WebRTC projects for win32 platform ..."
	SET platform_win32_prepared=1
	CALL:generateProjectsForPlatform win x86 debug
	CALL:generateProjectsForPlatform win x86 release
	SET platform_win32_prepared=2
)

IF %platform_win32_x64% EQU 1 (
	CALL:print %warning% "Generating WebRTC projects for win32 x64 platform ..."
	SET platform_win32_prepared=1
	CALL:generateProjectsForPlatform win x64 debug
	CALL:generateProjectsForPlatform win x64 release
	SET platform_win32_prepared=2
)

GOTO:EOF

:makeDirectory
IF NOT EXIST %~1\NUL (
	MKDIR %~1
	CALL:print %trace% "Created folder %~1"
) ELSE (
	CALL:print %trace% "%~1 folder already exists"
)
GOTO:EOF

:makeLink
IF NOT EXIST %~1\NUL CALL:error 1 "%folderStructureError:"=% %~1 does not exist!"

PUSHD %~1
IF EXIST .\%~2\NUL GOTO:alreadyexists
IF NOT EXIST %~3\NUL CALL:error 1 "%folderStructureError:"=% %~3 does not exist!"

CALL:print %trace% In path "%~1" creating symbolic link for "%~2" to "%~3"

IF %logLevel% GEQ %trace% (
	MKLINK /J %~2 %~3
) ELSE (
	MKLINK /J %~2 %~3  >NUL
)

IF %ERRORLEVEL% NEQ 0 CALL:ERROR 1 "COULD NOT CREATE SYMBOLIC LINK TO %~2 FROM %~3"

:alreadyexists
POPD

GOTO:EOF

:determineWindowsSDK
SET windowsSDKPath="Program Files (x86)\Windows Kits\10\Lib\"
SET windowsSDKFullPath=C:\!windowsSDKPath!

IF DEFINED USE_WIN_SDK_FULL_PATH SET windowsSDKFullPath=!USE_WIN_SDK_FULL_PATH! && GOTO parseSDKPath
IF DEFINED USE_WIN_SDK SET windowsSDKVersion=!USE_WIN_SDK! && GOTO setVersion
FOR %%p IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
	IF EXIST %%p:\!windowsSDKPath! (
		SET windowsSDKFullPath=%%p:\!windowsSDKPath!
		GOTO determineVersion
	)
)

:parseSDKPath
IF EXIST !windowsSDKFullPath! (
	FOR %%A IN ("!windowsSDKFullPath!") DO (
		SET windowsSDKVersion=%%~nxA
	)
) ELSE (
	CALL:ERROR 1 "Invalid Windows SDK path"
)
GOTO setVersion

:determineVersion
IF EXIST !windowsSDKFullPath! (
	PUSHD !windowsSDKFullPath!
	FOR /F "delims=" %%a in ('dir /ad /b /on') do (
		FOR /f "tokens=1-3 delims=[.] " %%i IN ("%%a") DO (SET v1=%%k)
		IF !v1! LSS 15063 SET windowsSDKVersion=%%a
	)
	POPD
) ELSE (
	CALL:ERROR 1 "Invalid Windows SDK path"
)

:setVersion
IF NOT "!windowsSDKVersion!"=="" (
	FOR /f "tokens=1-3 delims=[.] " %%i IN ("!windowsSDKVersion!") DO (SET v=%%i.%%j.%%k)
) ELSE (
	CALL:ERROR 1 "Supported Windows SDK is not present. Latest supported Win SDK is 10.0.14393.0"
)

IF NOT EXIST !windowsSDKFullPath!..\Debuggers\x64\cdb.exe CALL:ERROR 1 %errorMessageMissingDebuggerTools%
IF NOT EXIST !windowsSDKFullPath!..\Debuggers\x86\cdb.exe CALL:ERROR 1 %errorMessageMissingDebuggerTools%
GOTO:EOF

:makeFileLink
IF NOT EXIST %~1 CALL:error 1 "%folderStructureError:"=% %~1 does not exist!"

echo %cd%
PUSHD %~1
IF EXIST .\%~2 GOTO:alreadyexists
IF NOT EXIST %~3 CALL:error 1 "%folderStructureError:"=% %~3 does not exist!"

IF %logLevel% GEQ %trace% (
	MKLINK /J %~2 %~3
) ELSE (
	MKLINK /J %~2 %~3  >NUL
)

CALL:print %trace% In path "%~1" creating symbolic link for "%~2" to "%~3"

IF %ERRORLEVEL% NEQ 0 CALL:ERROR 1 "COULD NOT CREATE SYMBOLIC LINK TO %~2 FROM %~3"

:alreadyexists
POPD

GOTO:EOF

:updateSDKVersion

CALL:determineWindowsSDK

IF NOT "!v!"=="" (
	CALL:print %warning% "!v! SDK version will be used"
	SET SDKVersionString=%stringToUpdateWithSDKVersion:10.0.10240=!v!%
	%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %pythonFilePathToUpdateSDKVersion% "%stringToUpdateWithSDKVersion%" "!SDKVersionString!" %pythonFilePathToUpdateSDKVersion%
	IF ERRORLEVEL 1 CALL:error 0 "Failed to set newer SDK version"
)
GOTO:EOF

:resetSDKVersion
IF NOT "!SDKVersionString!"=="" (
	%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %pythonFilePathToUpdateSDKVersion% "!SDKVersionString!" "%stringToUpdateWithSDKVersion%" %pythonFilePathToUpdateSDKVersion%
	IF ERRORLEVEL 1 CALL:error 0 "Failed to reset newer SDK version"
)
GOTO:EOF

:summary
SET logLevel=%trace%
CALL:print %trace% "=======   WebRTC prepare script summary   ======="
CALL:print %trace% "=======   platform   =========   result   ======="

IF %platform_ARM_prepared% EQU 2 (
	CALL:print %info% "            arm                 prepared"
) ELSE (
	IF %platform_ARM_prepared% EQU 1 (
		CALL:print %error% "            arm                  failed"
	) ELSE (
		CALL:print %warning% "            arm                 not run"
	)
)

IF %platform_x64_prepared% EQU 2 (
	CALL:print %info% "            x64                 prepared"
) ELSE (
	IF %platform_x64_prepared% EQU 1 (
		CALL:print %error% "            x64                  failed"
	) ELSE (
		CALL:print %warning% "            x64                 not run"
	)
)

IF %platform_x86_prepared% EQU 2 (
	CALL:print %info% "            x86                 prepared"
) ELSE (
	IF %platform_x86_prepared% EQU 1 (
		CALL:print %error% "            x86                  failed"
	) ELSE (
		CALL:print %warning% "            x86                 not run"
	)
)

IF %platform_win32_prepared% EQU 2 (
	CALL:print %info% "            win32               prepared"
) ELSE (
	IF %platform_win32_prepared% EQU 1 (
		CALL:print %error% "            win32                failed"
	) ELSE (
		CALL:print %warning% "            win32               not run"
	)
)
CALL:print %trace% "================================================="
ECHO.
GOTO:EOF

REM Copy all ORTC template required to set developer environment
:copyTemplates

IF NOT EXIST %~1 CALL:error 1 "%folderStructureError:"=% %~1 does not exist!"

COPY %~1 %~2 >NUL

CALL:print %trace% Copied file %~1 to %~2

IF %ERRORLEVEL% NEQ 0 CALL:error 1 "%folderStructureError:"=% Unable to copy WebRTC template solution file"

GOTO:EOF

:print
SET logType=%1
SET logMessage=%~2

if %logLevel% GEQ  %logType% (
	if %logType%==0 ECHO [91m%logMessage%[0m
	if %logType%==1 ECHO [92m%logMessage%[0m
	if %logType%==2 ECHO [93m%logMessage%[0m
	if %logType%==3 ECHO [95m%logMessage%[0m
	if %logType%==4 ECHO %logMessage%
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
	CALL:print %error% "FAILURE:Preparing WebRTC development environment has failed.	"
	POPD
	CALL:resetSDKVersion
	CALL:summary
	::terminate batch execution
	CALL bin\batchTerminator.bat
)
GOTO:EOF

:done
ECHO.
CALL:print %info% "Success: WebRTC development environment is prepared."
CALL:resetSDKVersion
CALL:summary 
