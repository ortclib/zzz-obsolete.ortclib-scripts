@echo off

setlocal EnableDelayedExpansion
echo Started creating ortc nuget package...

set projectName=org.ortc
set nugetName=ORTC
set nugetVersion=
set publishKey=
set failure=0
set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
set PROGFILES=%ProgramFiles%
if not "%ProgramFiles(x86)%" == "" set PROGFILES=%ProgramFiles(x86)%
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 14.0"
set nuget=bin\nuget.exe
set SOLUTIONPATH=winrt\projects\ortc-lib-sdk-win.vs2015.sln
set nugetBasePath=winrt\nuget

set nugetSpec=%nugetBasePath%\%projectName%.nuspec
set nugetOutputPath=%nugetBasePath%\..\NugetOutput\%projectName%
set nugetTemplateProjectsPath=%nugetBasePath%\templates\%projectName%
set nugetPackageVersion=%nugetBasePath%\%projectName%.version


set nugetVersion=%2

set nugetPath=%nugetBasePath%\package


::Version
set v=1.0.0

::Api key for publishing
set k=

::PreRelease flag
set b=0

::Destination nuget storage
set s=

::Publish flag
set p=

if exist %nugetPackageVersion% (
	set /p v=< %nugetPackageVersion%
)

echo Current Version is %v%
for /f "tokens=1-3 delims=." %%a in ("%v%") do (
  set /a build=%%c+1
  set v=%%a.%%b.!build!
)

:initial
if "%1"=="" (
	if not "%nome%"=="" (
		set "%nome%=1"
		set nome=""
	) else (
		goto:proceed
	)
)
::echo              %1
set aux=%1
if "%aux:~0,1%"=="-" (
	if not "%nome%"=="" (
		set "%nome%=1"
	)
   set nome=%aux:~1,250%
) else (
   set "%nome%=%1"
   set nome=
)

shift
goto initial

:proceed

if not %b%==0 (
	set v=%v%-Beta
)
echo New version is %v%
set nugetVersion=%v%
set publishKey=%k%

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

call:buildProjects x86
if "%failure%" neq "0" goto:eof
	
call:buildProjects x64
if "%failure%" neq "0" goto:eof
	
call:buildProjects ARM
if "%failure%" neq "0" goto:eof

call:preparePackage
if "%failure%" neq "0" goto:eof

call:makeNuget

goto:eof

:downloadNuget
%powershell_path% "Start-BitsTransfer https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -Destination bin\nuget.exe"

if ERRORLEVEL 1 call:failure %errorlevel% "Could not download nuget.exe"
goto:eof

:buildProjects
call buildORTC.bat Release x86
if ERRORLEVEL 1 call:failure %errorlevel% "ORTC build failed."

if "%failure%" neq "0" goto:eof

call buildORTC.bat Release x64
if ERRORLEVEL 1 call:failure %errorlevel% "ORTC build failed."

if "%failure%" neq "0" goto:eof

call buildORTC.bat Release ARM
if ERRORLEVEL 1 call:failure %errorlevel% "ORTC build failed."
goto:eof

:preparePackage

set nugetTargetPath=%nugetBasePath%\%nugetName%.targets
set nugetSpecPath=%nugetBasePath%\%nugetName%.nuspec

set nugetBuildPath=%nugetPath%\%nugetName%\build
set nugetBuildNativePath=%nugetBuildPath%\native
set nugetBuildNetCorePath=%nugetBuildPath%\netcore45
set nugetBuildNetCorex86Path=%nugetBuildNetCorePath%\x86
set nugetBuildNetCorex64Path=%nugetBuildNetCorePath%\x64
set nugetBuildNetCoreARMPath=%nugetBuildNetCorePath%\arm

set nugetLibPath=%nugetPath%\%nugetName%\lib
set nugetLibNetCorePath=%nugetLibPath%\netcore45
set nugetLibUAPPath=%nugetLibPath%\uap10.0

set nugetRuntimesPath=%nugetPath%\%nugetName%\runtimes
set nugetRuntimesx86Path=%nugetRuntimesPath%\win10-x86\native
set nugetRuntimesx64Path=%nugetRuntimesPath%\win10-x64\native
set nugetRuntimesARMPath=%nugetRuntimesPath%\win10-arm\native

set sourcex86Path=winrt\Build\x86\Release\%nugetName%
set sourcex86DllPath=%sourcex86Path%\%nugetName%.dll
set sourcex86WinmdPath=%sourcex86Path%\%nugetName%.winmd
set sourcex86PdbPath=%sourcex86Path%\%nugetName%.pdb

set sourcex64Path=winrt\Build\x64\Release\%nugetName%
set sourcex64DllPath=%sourcex64Path%\%nugetName%.dll
set sourcex64WinmdPath=%sourcex64Path%\%nugetName%.winmd
set sourcex64PdbPath=%sourcex64Path%\%nugetName%.pdb

set sourcexARMPath=winrt\Build\ARM\Release\%nugetName%
set sourcexARMDllPath=%sourcexARMPath%\%nugetName%.dll
set sourcexARMWinmdPath=%sourcexARMPath%\%nugetName%.winmd
set sourcexARMPdbPath=%sourcexARMPath%\%nugetName%.pdb

rmdir /s /q %nugetPath%\%nugetName%\

call:createFolder %nugetPath%\%nugetName%
if "%failure%" neq "0" goto:eof

call::copyFiles %sourcexARMDllPath% %nugetRuntimesARMPath%
if "%failure%" neq "0" goto:eof

call::copyFiles %sourcex64DllPath% %nugetRuntimesx64Path%
if "%failure%" neq "0" goto:eof

call::copyFiles %sourcex86DllPath% %nugetRuntimesx86Path%
if "%failure%" neq "0" goto:eof

if /I "%nugetName%" == "org.ortc" (
	call::copyFiles %sourcex86WinmdPath% %nugetLibUAPPath%
	if "%failure%" neq "0" goto:eof
)

call::copyFiles %nugetTargetPath% %nugetBuildNativePath%
if "%failure%" neq "0" goto:eof

call:copyFiles %nugetSpecPath% %nugetPath%\%nugetName%
if "%failure%" neq "0" goto:eof

echo %nugetPath%\%nugetName%\%nugetName%.nuspec
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %nugetPath%\%nugetName%\%nugetName%.nuspec "<version></version>" "<version>%nugetVersion%</version>" %nugetPath%\%nugetName%\%nugetName%.nuspec
echo Replaced text
goto:eof

:makeNuget

if exist %nugetOutputPath%\%nugetName%\ (
	rmdir /s /q %nugetOutputPath%\%nugetName%\
)
call:createFolder %nugetOutputPath%\%nugetName%
if "%failure%" neq "0" goto:eof

%nuget% pack %nugetSpec% -OutputDirectory %nugetOutputPath%\%nugetName%
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"

if exist %nugetPath% (
	rmdir /s /q %nugetPath%
)

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