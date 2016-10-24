@echo off
::"..\libs\webrtc\webrtcForOrtc.vs2015.sln"
setlocal EnableDelayedExpansion

set SOLUTIONPATH=%1
set CONFIGURATION=%2
set PLATFORM=%3
set SOFTWARE_PLATFORM=%4
set MSVCDIR=""
set failure=0
set x86BuildCompilerOption=amd64_x86
set x64BuildCompilerOption=amd64
set armBuildCompilerOption=amd64_arm
set currentBuildCompilerOption=amd64

echo Webrtc build is started. It will take couple of minutes.
echo Working ...


call:determineVisualStudioPath

call:setCompilerOption

call:build
if "%failure%" neq "0" goto:eof

call:combineLibs
if "%failure%" neq "0" goto:eof

call:moveLibs
if "%failure%" neq "0" goto:eof

goto:done

:determineVisualStudioPath
set PROGFILES=%ProgramFiles%
if not "%ProgramFiles(x86)%" == "" set PROGFILES=%ProgramFiles(x86)%

REM Check if Visual Studio 2015 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 14.0"

if not exist %MSVCDIR% (
	REM Check if Visual Studio 2013 is installed
	set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 12.0"
)

echo Visual Studio path is %MSVCDIR%
goto:eof
:setCompilerOption

reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set CPU=x86 || set CPU=x64
echo CPU arhitecture is %CPU%

if %CPU% == x86 (
	set x86BuildCompilerOption=x86
	set x64BuildCompilerOption=x86_amd64
	set armBuildCompilerOption=x86_arm
)

if %PLATFORM%==x86 (
	set currentBuildCompilerOption=%x86BuildCompilerOption%
) else (
	if %PLATFORM%==ARM (
		set currentBuildCompilerOption=%armBuildCompilerOption%
	) else (
		set currentBuildCompilerOption=%x64BuildCompilerOption%
	)
)

echo Selected compiler option is %currentBuildCompilerOption%

goto:eof


:build

if exist %MSVCDIR% (
	call %MSVCDIR%\VC\vcvarsall.bat %currentBuildCompilerOption%
	if ERRORLEVEL 1 call:failure %errorlevel% "Could not setup compiler for  %PLATFORM%"
	
	MSBuild %SOLUTIONPATH% /property:Configuration=%CONFIGURATION% /property:Platform=%PLATFORM% /m
	if ERRORLEVEL 1 call:failure %errorlevel% "Building WebRTC projects has failed"
) else (
	call:failure 2 "Could not compile because proper version of Visual Studio is not found"
)
goto:eof

:combineLibs
call:setPaths %SOLUTIONPATH%

if NOT EXIST %destinationPath% (
	mkdir %destinationPath%
	if ERRORLEVEL 1 call:failure %errorlevel% "Could not make a directory %destinationPath%libs"
)

if "%failure%"=="0" (
	echo %MSVCDIR%
	%MSVCDIR%\VC\Bin\lib.exe /OUT:%destinationPath%webrtc.lib %libsSourcePath%\*.lib %libsSourcePath%\lib\*.lib
	if ERRORLEVEL 1 call:failure %errorlevel% "Failed combining libs"
)

echo All WebRTC libs for %PLATFORM% %CONFIGURATION% are combined in one lib.
goto:eof

:moveLibs

IF NOT EXIST %libsSourcePathDestianation%NUL (
	MKDIR %libsSourcePathDestianation%
	echo %trace% "Created folder %libsSourcePathDestianation%"
)
echo started
echo %libsSourcePath%
echo %libsSourcePathDestianation%%CONFIGURATION%
MOVE %libsSourcePath% %libsSourcePathDestianation%%CONFIGURATION%
echo finished
GOTO:EOF

:setPaths
set basePath=%~dp1

if /I "%PLATFORM%"=="x64" (
	set libsSourcePath=%basePath%build_win10_x64\%CONFIGURATION%
	set libsSourcePathDestianation=%basePath%build_win10_x64\%SOFTWARE_PLATFORM%\
)

if /I "%PLATFORM%"=="x86" (
	set libsSourcePath=%basePath%build_win10_x86\%CONFIGURATION%
	set libsSourcePathDestianation=%basePath%build_win10_x86\%SOFTWARE_PLATFORM%\
)

if /I "%PLATFORM%"=="ARM" (
	set libsSourcePath=%basePath%build_win10_arm\%CONFIGURATION%
	set libsSourcePathDestianation=%basePath%build_win10_arm\%SOFTWARE_PLATFORM%\
)
echo Source path is %libsSourcePath%

set destinationPath=%basePath%WEBRTC_BUILD\%SOFTWARE_PLATFORM%\%CONFIGURATION%\%PLATFORM%\

echo Destination path is %destinationPath%
goto :eof

:failure
set failure=%~1
echo.
echo ERROR: %~2
echo.
echo. Failed to build WebRTC lib ...
echo.
goto:eof

:done
echo.
echo WebRTC lib for %PLATFORM% %CONFIGURATION% is successfully built.
echo.
