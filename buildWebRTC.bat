
::"..\libs\webrtc\webrtcForOrtc.vs2015.sln"
set SOLUTIONPATH=%1
set CONFIGURATION=%2
set PLATFORM=%3

call:doBuild
if "%failure%" neq "0" goto:eof
::set MSBUILDDIR=""

::call:determineMSBUILDDIR

::echo %MSBUILDDIR%

::call %MSBUILDDIR%\MSBuild.exe %SOLUTIONPATH% /property:Configuration=%CONFIGURATION% /property:Platform=%PLATFORM%
::MSBuild ..\libs\webrtc\webrtcForOrtc.vs2015.sln /property:Configuration=Debug /property:Platform=x64
::if %errorlevel% neq 0 call:failure %errorlevel% "Building WebRTC projects has failed"

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

:determineMSBUILDDIR
setlocal EnableDelayedExpansion

set PROGFILES=%ProgramFiles%
if not "%ProgramFiles(x86)%" == "" set PROGFILES=%ProgramFiles(x86)%

REM Check if Visual Studio 2015 is installed
set MSBUILDDIR="%PROGFILES%\MSBuild\14.0\Bin"
if exist %MSBUILDDIR% (
    set COMPILER_VER="2014"
	goto:eof
)

REM Check if Visual Studio 2013 is installed
set MSBUILDDIR="%PROGFILES%\MSBuild\12.0\Bin"
if exist %MSBUILDDIR% (
    set COMPILER_VER="2013"
	goto:eof
)
call:failure 1 "MSBuild is not installed."

goto:eof

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
