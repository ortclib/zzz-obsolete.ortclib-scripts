@echo off

setlocal EnableDelayedExpansion
echo Started creating ortc nuget package...

set projectNameForNuget=org.ortc
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
set PROJECTPATH=winrt\projects\ortc-template.csproj
set nugetBasePath=winrt\nuget

set nugetSpec=%nugetBasePath%\package\%nugetName%\%projectNameForNuget%.nuspec
set nugetOutputPath=%nugetBasePath%\..\NugetOutput\%projectNameForNuget%
set nugetTemplateProjectsPath=%nugetBasePath%\templates\%projectNameForNuget%
set nugetPackageVersion=%nugetBasePath%\%projectNameForNuget%.version

set peerCCSourcePath=samples\PeerCC
set peerCCTestPath=winrt\test\PeerCC
set peerCCProjectTemaplePath=winrt\templates\samples\PeerCC

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

::Prepare test environment
set t=

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

if not "%h%"=="" (
	call:showHelp
	goto end
)

if NOT EXIST %nuget% (
	echo Nuget donwload started
	call:downloadNuget
	if "%failure%" neq "0" goto:eof
)

if not %b%==0 (
	set v=%v%-Beta
)

echo New version is %v%
set nugetVersion=%v%
set publishKey=%k%

call:copyFiles %nugetTemplateProjectsPath%\*.* winrt\projects\
if "%failure%" neq "0" goto:endedWithError

::call:buildProjects x86
::if "%failure%" neq "0" goto:eof
call:determineVisualStudioPath
if "%failure%" neq "0" goto:eof

call:build
if "%failure%" neq "0" goto:eof

call:preparePackage
if "%failure%" neq "0" goto:eof

call:makeNuget

del winrt\projects\ortc-template.csproj
del winrt\projects\ortc-lib-sdk-template.vs2015.sln

if not "%publishKey%"=="" (
	call:setNugetApiKey
	if "%failure%" neq "0" goto:endedWithError
)
call:publishNuget
if "%failure%" neq "0" goto:eof

if not "%t%"=="" (
	call:preparePeerCC
	if "%failure%" neq "0" goto:eof
	
	call:makePeerCCPackage
	if "%failure%" neq "0" goto:eof
)
goto:done

:downloadNuget
%powershell_path% "Start-BitsTransfer https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -Destination bin\nuget.exe"

if ERRORLEVEL 1 call:failure %errorlevel% "Could not download nuget.exe"
goto:eof


:buildProjects
call bin\buildORTC.bat Release x86
if ERRORLEVEL 1 call:failure %errorlevel% "ORTC build for X86 Release has failed."

goto:eof

:preparePackage

set nugetTargetPath=%nugetBasePath%\%projectNameForNuget%.targets
set nugetSpecPath=%nugetBasePath%\%projectNameForNuget%.nuspec

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

set sourcex86Path=winrt\Build\x86\Release\%projectNameForNuget%
set sourcex86DllPath=%sourcex86Path%\%projectNameForNuget%.dll
set sourcex86WinmdPath=%sourcex86Path%\%projectNameForNuget%.winmd
set sourcex86PdbPath=%sourcex86Path%\%projectNameForNuget%.pdb

set sourcex64Path=winrt\Build\x64\Release\%projectNameForNuget%
set sourcex64DllPath=%sourcex64Path%\%projectNameForNuget%.dll
set sourcex64WinmdPath=%sourcex64Path%\%projectNameForNuget%.winmd
set sourcex64PdbPath=%sourcex64Path%\%projectNameForNuget%.pdb

set sourcexARMPath=winrt\Build\ARM\Release\%projectNameForNuget%
set sourcexARMDllPath=%sourcexARMPath%\%projectNameForNuget%.dll
set sourcexARMWinmdPath=%sourcexARMPath%\%projectNameForNuget%.winmd
set sourcexARMPdbPath=%sourcexARMPath%\%projectNameForNuget%.pdb

rmdir /s /q %nugetPath%\%nugetName%\

call:createFolder %nugetPath%\%nugetName%
if "%failure%" neq "0" goto:eof

call::copyFiles %sourcexARMDllPath% %nugetRuntimesARMPath%
if "%failure%" neq "0" goto:eof

call::copyFiles %sourcex64DllPath% %nugetRuntimesx64Path%
if "%failure%" neq "0" goto:eof

call::copyFiles %sourcex86DllPath% %nugetRuntimesx86Path%
if "%failure%" neq "0" goto:eof

if /I "%projectNameForNuget%" == "org.ortc" (
	call::copyFiles %sourcex86WinmdPath% %nugetLibUAPPath%
	if "%failure%" neq "0" goto:eof
)

call::copyFiles %nugetTargetPath% %nugetBuildNativePath%
if "%failure%" neq "0" goto:eof

call:copyFiles %nugetSpecPath% %nugetPath%\%nugetName%
if "%failure%" neq "0" goto:eof

::echo %nugetPath%\%nugetName%\%nugetName%.nuspec
::%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %nugetPath%\%nugetName%\%nugetName%.nuspec "<version></version>" "<version>%nugetVersion%</version>" %nugetPath%\%nugetName%\%nugetName%.nuspec
::echo Replaced text

call:setNugetVersion
if "%failure%" neq "0" goto:eof
goto:eof

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

:build

if exist %MSVCDIR% (
	call %MSVCDIR%\VC\vcvarsall.bat amd64
	if ERRORLEVEL 1 call:failure %errorlevel% "Could not setup compiler for  %PLATFORM%"
	
	::MSBuild %SOLUTIONPATH% /property:Configuration=%CONFIGURATION% /property:Platform=%PLATFORM% /m
	MSBuild %PROJECTPATH% /t:Build /m
	if ERRORLEVEL 1 call:failure %errorlevel% "Building ORTC projects for %PLATFORM% %CONFIGURATION% has failed"
) else (
	call:failure 2 "Could not compile because proper version of Visual Studio is not found"
)
goto:eof
:setNugetVersion
echo version %nugetVersion%
echo %nugetPath%\%nugetName%\%projectNameForNuget%.nuspec
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %nugetPath%\%nugetName%\%projectNameForNuget%.nuspec "<version></version>" "<version>%nugetVersion%</version>" %nugetPath%\%nugetName%\%projectNameForNuget%.nuspec
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
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

:setNugetApiKey
%nuget% setapikey %publishKey%
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
goto:eof

:publishNuget
if not "%p%"=="" (
	if not "%s%"=="" (
		%nuget% push %nugetOutputPath%\%nugetName%\%nugetName%.%nugetVersion%.nupkg -s %s%
	) else (
		%nuget% push %nugetOutputPath%\%nugetName%\%nugetName%.%nugetVersion%.nupkg
	)
)
if ERRORLEVEL 1 call:failure %errorlevel% "Failed publishing the %nugetName% nuget package"

goto:eof

:preparePeerCC

rmdir /s /q %peerCCTestPath%
call:createFolder %peerCCTestPath%
::Xcopy  /S /I /E %peerCCSourcePath%\*.* %peerCCTestPath%\
Xcopy  /S /I /Y %peerCCSourcePath%\PeerConnectionClient_UsingORTCNuget.Win10 %peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10
Xcopy  /S /I /Y %peerCCSourcePath%\PeerConnectionClient.Win10.Shared %peerCCTestPath%\PeerConnectionClient.Win10.Shared
Xcopy  /S /I /Y %peerCCSourcePath%\PeerConnectionClient.Shared %peerCCTestPath%\PeerConnectionClient.Shared
Xcopy  /S /I /Y %peerCCSourcePath%\PeerConnectionClient_UsingORTCNuget.vs2015.sln %peerCCTestPath%\

echo peerCCProjectTemaplePath = %peerCCProjectTemaplePath%
call:copyFiles %peerCCProjectTemaplePath%\project.json %peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10\project.json "ORTC.Version" "%nugetVersion%" %peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10\project.json

goto:eof

:makePeerCCPackage
%nuget% restore %peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10\project.json

if exist %MSVCDIR% (
	call %MSVCDIR%\VC\vcvarsall.bat
	if ERRORLEVEL 1 call:failure %errorlevel% "Could not setup compiler for  %PLATFORM%"
	
	::MSBuild %SOLUTIONPATH% /property:Configuration=%CONFIGURATION% /property:Platform=%PLATFORM% /m
	MSBuild %peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.vs2015.sln  /p:Configuration=Release;Platform="Any CPU";AppxBundle=Always;AppxBundlePlatforms="x86|x64|ARM"
	if ERRORLEVEL 1 call:failure %errorlevel% "Building ORTC projects for %PLATFORM% %CONFIGURATION% has failed"
) else (
	call:failure 2 "Could not compile because proper version of Visual Studio is not found"
)

set ABS_PATH=%CD%

if exist "%peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10\AppPackages\PeerConnectionClient_UsingORTCNuGet.Win10_9.9.9.9_Test\" (
	call:zipfile "%ABS_PATH%\%peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10\AppPackages\PeerConnectionClient_UsingORTCNuGet.Win10_9.9.9.9_Test\" "%ABS_PATH%\%peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10\PeerConnectionClient_%nugetVersion%.zip"
)
goto:eof

:zipfile 
set vbs="%temp%\_.vbs"
if exist %vbs% del /f /q %vbs%
echo %1
echo %2
>%vbs%  echo InputFolder = WScript.Arguments(0)
>>%vbs% echo ZipFile = WScript.Arguments(1)
>>%vbs% echo CreateObject("Scripting.FileSystemObject").CreateTextFile(ZipFile, True).Write "PK" ^& Chr(5) ^& Chr(6) ^& String(18, vbNullChar)
>>%vbs% echo set objShell = CreateObject("Shell.Application")
>>%vbs% echo Set source = objShell.NameSpace(InputFolder).Items
>>%vbs% echo objShell.NameSpace(ZipFile).CopyHere(source)
>>%vbs% echo wScript.Sleep 2000
cscript //nologo %vbs% %1 %2
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

:showHelp
echo Available commands:
echo.
echo -b 	Flag for creating prerelase nuget package.
echo.
echo -k	Api key that is used for publishing nuget package on nuget.org. This is used in combination with 
echo		publish flag -p. This will store your API key so that you never need to do this step again on this machine.
echo.
echo -h 	Show script usage
echo.
echo -p	Publish created nuget package. By default it will be uploaded on nuget.org server. If it is 
echo		desired to publish it locally or on some another server, it sholud be used option -s to specify 
echo		destination server
echo.
echo -s	Used for specifying nuget server where package will be published
echo.
echo -t	Flag that initiates setting up test environment for newly published nuget package
echo.
echo -v	Nuget package version number
echo.
echo Generated nuget package will be stored in winrt\NugetOutput\org.ortc.Adapter
echo Examples:
echo.
echo Creating nuget package with version number 1.0.1
echo bin\createNuget.bat
echo.
echo Creating prerelase nuget package with version number 1.0.1-Beta
echo bin\createNuget.bat -b
echo.
echo Creating prerelase nuget package and publish it to locally nuget storage
echo bin\createNuget.bat -b -p -s [path to local nuget storage]
echo.

goto:eof
:failure
echo.

echo ERROR: %~2

echo.
echo FAILURE: Could not create a nuget package.

set failure=%~1

goto:eof

:done
echo %v%
echo %nugetPackageVersion%
echo %v%>%nugetPackageVersion%
echo.
echo Success: ORTC nuget package is created.
echo.
:end