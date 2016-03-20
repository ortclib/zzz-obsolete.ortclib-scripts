@echo off

echo Started creating ortc nuget package...

set failure=0
set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
set PROGFILES=%ProgramFiles%
if not "%ProgramFiles(x86)%" == "" set PROGFILES=%ProgramFiles(x86)%
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 14.0"
set nuget=bin\nuget.exe
set SOLUTIONPATH=winrt\projects\ortc-lib-sdk-win.vs2015.sln
set nugetBasePath=winrt\nuget
set nugetPath=%nugetBasePath%\package
set nugetSpec=%nugetPath%\org.ortc.nuspec
set nugetOutputPath=%nugetBasePath%\Output

if NOT EXIST %nuget% (
	echo Nuget donwload started
	call:downloadNuget
	if "%failure%" neq "0" goto:eof
)

if NOT EXIST %MSVCDIR% (
    set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 12.0"
)

if NOT EXIST %MSVCDIR% (
    call:failure 1 "Microsoft Visual Studio 12.0 or 14.0 is not installed."	
	goto:eof
)

::call:buildProjects x86
::if "%failure%" neq "0" goto:eof
	
::call:buildProjects x64
::if "%failure%" neq "0" goto:eof
	
::call:buildProjects ARM
::if "%failure%" neq "0" goto:eof

call:preparePackage
if "%failure%" neq "0" goto:eof

call:makeNuget

goto:eof

:downloadNuget
%powershell_path% "Start-BitsTransfer https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -Destination bin\nuget.exe"

if ERRORLEVEL 1 call:failure %errorlevel% "Could not download nuget.exe"
goto:eof

:buildProjects
call %MSVCDIR%\VC\vcvarsall.bat %1
if ERRORLEVEL 1 call:failure %errorlevel% "Could not setup %1 compiler"
	
MSBuild %SOLUTIONPATH% /t:api\org_ortc\org_ortc /property:Configuration=Release /property:Platform=%1
if %errorlevel% neq 0 call:failure %errorlevel% "Building org.ortc projects has failed"	

goto:eof

:preparePackage

set nugetTargetPath=%nugetBasePath%\org.ortc.targets
set nugetSpecPath=%nugetBasePath%\org.ortc.nuspec

set nugetBuildPath=%nugetPath%\build
set nugetBuildNativePath=%nugetBuildPath%\native
set nugetBuildNetCorePath=%nugetBuildPath%\netcore45
set nugetBuildNetCorex86Path=%nugetBuildNetCorePath%\x86
set nugetBuildNetCorex64Path=%nugetBuildNetCorePath%\x64
set nugetBuildNetCoreARMPath=%nugetBuildNetCorePath%\arm

set nugetLibPath=%nugetPath%\lib
set nugetLibNetCorePath=%nugetLibPath%\netcore45
set nugetLibUAPPath=%nugetLibPath%\uap10.0

set nugetRuntimesPath=%nugetPath%\runtimes
set nugetRuntimesx86Path=%nugetRuntimesPath%\win10-x86\native
set nugetRuntimesx64Path=%nugetRuntimesPath%\win10-x64\native
set nugetRuntimesARMPath=%nugetRuntimesPath%\win10-arm\native

set sourcex86Path=winrt\Build\x86\Release\org.ortc
set sourcex86DllPath=%sourcex86Path%\org.ortc.dll
set sourcex86WinmdPath=%sourcex86Path%\org.ortc.winmd
set sourcex86PdbPath=%sourcex86Path%\org.ortc.pdb

set sourcex64Path=winrt\Build\x64\Release\org.ortc
set sourcex64DllPath=%sourcex64Path%\org.ortc.dll
set sourcex64WinmdPath=%sourcex64Path%\org.ortc.winmd
set sourcex64PdbPath=%sourcex64Path%\org.ortc.pdb

set sourcexARMPath=winrt\Build\ARM\Release\org.ortc
set sourcexARMDllPath=%sourcexARMPath%\org.ortc.dll
set sourcexARMWinmdPath=%sourcexARMPath%\org.ortc.winmd
set sourcexARMPdbPath=%sourcexARMPath%\org.ortc.pdb


call:createFolder %nugetPath%
if "%failure%" neq "0" goto:eof

call::copyFiles %sourcexARMDllPath% %nugetRuntimesARMPath%
if "%failure%" neq "0" goto:eof

call::copyFiles %sourcex64DllPath% %nugetRuntimesx64Path%
if "%failure%" neq "0" goto:eof

call::copyFiles %sourcex86DllPath% %nugetRuntimesx86Path%
if "%failure%" neq "0" goto:eof

call::copyFiles %sourcex86WinmdPath% %nugetLibUAPPath%
if "%failure%" neq "0" goto:eof

call::copyFiles %nugetTargetPath% %nugetBuildNativePath%
if "%failure%" neq "0" goto:eof

call:copyFiles %nugetSpecPath% %nugetPath%
if "%failure%" neq "0" goto:eof

goto:eof

:makeNuget
call:createFolder %nugetOutputPath%
if "%failure%" neq "0" goto:eof

%nuget% pack %nugetSpec% -OutputDirectory %nugetOutputPath%
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the org.ortc nuget package"

goto:eof
:copyFiles
if EXIST %1 (
	call:createFolder %2
	echo Copying %1 to %2
	copy %1 %2
	if ERRORLEVEL 1 call:failure %errorlevel% "Could not copy a %1"
) else (
	call:failure 1 "Could not copy a %1"
)
goto:eof

:createFolder
if NOT EXIST %1 (
	mkdir %1
	if ERRORLEVEL 1 call:failure %errorlevel% "Could not make a directory %1"
)
goto:eof
:failure
echo.

echo ERROR: %~2

echo.
echo FAILURE: Could not create a nuget package.

set failure=%~1

goto:eof

:done
echo.
echo Success: ORTC nuget package is created.
echo.