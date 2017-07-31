@echo off
setlocal EnableDelayedExpansion

set CONFIGURATION=%1
set PLATFORM=%2
set SOLUTIONPATH=winuwp\projects\ortc-lib-sdk-win.vs2015.sln
set PROJECTPATH=winuwp\projects\ortc-template.csproj
set MSVCDIR=""
set failure=0
set x86BuildCompilerOption=amd64_x86
set x64BuildCompilerOption=amd64
set armBuildCompilerOption=amd64_arm
set currentBuildCompilerOption=amd64

echo ORTC build is started. It will take couple of minutes.
echo Working ...

call:determineVisualStudioPath
if "%failure%" neq "0" goto:eof

call:setCompilerOption
if "%failure%" neq "0" goto:eof

call:build
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
	
	::MSBuild %SOLUTIONPATH% /property:Configuration=%CONFIGURATION% /property:Platform=%PLATFORM% /m
	MSBuild %PROJECTPATH% /t:Build /m
	if ERRORLEVEL 1 call:failure %errorlevel% "Building ORTC projects for %PLATFORM% %CONFIGURATION% has failed"
) else (
	call:failure 2 "Could not compile because proper version of Visual Studio is not found"
)
goto:eof


:failure
set failure=%~1
echo.
echo ERROR: %~2
echo.
echo. Failed to build ORTC lib for %PLATFORM% %CONFIGURATION%...
echo.
goto:eof

:done
echo.
echo ORTC lib for %PLATFORM% %CONFIGURATION% is successfully built.
echo.
