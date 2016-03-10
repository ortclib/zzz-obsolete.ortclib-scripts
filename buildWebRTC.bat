
::"..\libs\webrtc\webrtcForOrtc.vs2015.sln"
set SOLUTIONPATH=%1
set CONFIGURATION=%2
set PLATFORM=%3

rem call:doBuild
rem if "%failure%" neq "0" goto:eof

call:combineLibs
if "%failure%" neq "0" goto:eof

goto:done

:doBuild
setlocal EnableDelayedExpansion

set PROGFILES=%ProgramFiles%
if not "%ProgramFiles(x86)%" == "" set PROGFILES=%ProgramFiles(x86)%

REM Check if Visual Studio 2015 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 14.0"
if exist %MSVCDIR% (
    goto:build
)

REM Check if Visual Studio 2013 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 12.0"
if exist %MSVCDIR% (
    goto:build
)
goto:eof

:build
call %MSVCDIR%\VC\vcvarsall.bat %PLATFORM%
if ERRORLEVEL 1 call:failure %errorlevel% "Could not setup %PLATFORM% compiler"
	
MSBuild %SOLUTIONPATH% /property:Configuration=%CONFIGURATION% /property:Platform=%PLATFORM%
if %errorlevel% neq 0 call:failure %errorlevel% "Building WebRTC projects has failed"	
goto:eof

:combineLibs
call:setPaths %SOLUTIONPATH%

if NOT EXIST %destinationPath%libs\ (
	mkdir %destinationPath%libs
	if ERRORLEVEL 1 call:failure %errorlevel% "Could not make a directory %destinationPath%libs"
)
copy %libsSourcePath%*.lib %destinationPath%libs
if ERRORLEVEL 1 call:failure %errorlevel% "Failed copying libs to %destinationPath%libs"

copy %libsSourcePath%lib\*.lib %destinationPath%libs
if ERRORLEVEL 1 call:failure %errorlevel% "Failed copying libs to %destinationPath%libs"

lib.exe /OUT:%destinationPath%webrtc.lib %destinationPath%libs\*.lib
if ERRORLEVEL 1 call:failure %errorlevel% "Failed combining libs"

goto:eof

:setPaths
set basePath=%~dp1

if /I "%PLATFORM%"=="x64" (
	set libsSourcePath=%basePath%build\%CONFIGURATION%\
)

if "%PLATFORM%"=="x86" (
	set libsSourcePath=%basePath%build_win10\%CONFIGURATION%\
)

if "%PLATFORM%"=="ARM" (
	set libsSourcePath=%basePath%build_win10_arm\%CONFIGURATION%\
)
echo Source path is %libsSourcePath%

set destinationPath=%basePath%WEBRTC_BUILD\%CONFIGURATION%\%PLATFORM%\

echo Destination path is %destinationPath%
goto :eof

:failure
set FAILURE=%~1
echo.
echo ERROR: %~2
echo.
echo. Failed to build WebRTC lib ...
echo.
goto:eof

:done
echo.
echo WebRTC lib is successfully built.
echo.
