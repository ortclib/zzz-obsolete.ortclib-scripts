@echo off
setlocal EnableExtensions EnableDelayedExpansion
set projectName=org.ortc.adapter
set nugetName=ORTC.Adapter
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
set adapterProjectPath=winrt\projects\api\org.ortc.adapter\org.ortc.adapter
set adapterTempProjectPath=winrt\projects\temp\org.ortc.adapter\org.ortc.adapter
set peerCCSourcePath=samples\PeerCC
set peerCCTestPath=winrt\test\PeerCC
set peerCCProjectTemaplePath=winrt\templates\samples\PeerCC
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

::Script usage
set h=

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
call:copyFiles %adapterProjectPath%\*.* %adapterTempProjectPath%\
if "%failure%" neq "0" goto:endedWithError

call:copyFiles %nugetTemplateProjectsPath%\*.* %adapterTempProjectPath%\
if "%failure%" neq "0" goto:endedWithError

call:copyFiles %nugetSpec% %adapterTempProjectPath%\
if "%failure%" neq "0" goto:endedWithError

call:setNugetVersion
if "%failure%" neq "0" goto:endedWithError

call:restoreNugetDependencies
if "%failure%" neq "0" goto:endedWithError

call:createNuget
if "%failure%" neq "0" goto:endedWithError

rmdir /s /q winrt\projects\temp

if not "%publishKey%"=="" (
	call:setNugetApiKey
	if "%failure%" neq "0" goto:endedWithError
)
call:publishNuget
if "%failure%" neq "0" goto:eof
::rmdir /s /q winrt\projects\temp

if not "%t%"=="" (
	call:preparePeerCC
	if "%failure%" neq "0" goto:eof
)
goto:done

:downloadNuget
%powershell_path% "Start-BitsTransfer https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -Destination bin\nuget.exe"

if ERRORLEVEL 1 call:failure %errorlevel% "Could not download nuget.exe"
goto:eof

:setNugetVersion

%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %adapterTempProjectPath%\%projectName%.nuspec "<version></version>" "<version>%nugetVersion%</version>" %adapterTempProjectPath%\%projectName%.nuspec
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
goto:eof

:restoreNugetDependencies
%nuget% restore %adapterTempProjectPath%\project.json
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
goto:eof

:createNuget
call:createFolder %nugetOutputPath%
%nuget% pack %adapterTempProjectPath%\%projectName%.csproj -Build -Version %nugetVersion% -OutputDirectory %nugetOutputPath% -Properties Configuration=Release -Properties Platform=AnyCPU
if ERRORLEVEL 1 (
	call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
) else (
	echo Nuget package is created
)
goto:eof

:setNugetApiKey
%nuget% setapikey %publishKey%
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
goto:eof

:publishNuget
if not "%p%"=="" (
	if not "%s%"=="" (
		%nuget% push %nugetOutputPath%\%nugetName%.%nugetVersion%.nupkg -s %s%
	) else (
		%nuget% push %nugetOutputPath%\%nugetName%.%nugetVersion%.nupkg
	)
)
if ERRORLEVEL 1 call:failure %errorlevel% "Failed publishing the %nugetName% nuget package"

goto:eof

:preparePeerCC

rmdir /s /q %peerCCTestPath%
::call:createFolder %peerCCTestPath%
call:copyFiles %peerCCSourcePath%\PeerConnectionClient_UsingORTCNuget.Win10 %peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10
call:copyFiles %peerCCSourcePath%\PeerConnectionClient.Win10.Shared %peerCCTestPath%\PeerConnectionClient.Win10.Shared
call:copyFiles %peerCCSourcePath%\PeerConnectionClient.Shared %peerCCTestPath%\PeerConnectionClient.Shared
call:copyFiles %peerCCSourcePath%\PeerConnectionClient_UsingORTCNuget.vs2015.sln %peerCCTestPath%\

echo peerCCProjectTemaplePath = %peerCCProjectTemaplePath%
call:copyFiles %peerCCProjectTemaplePath%\project.json %peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10\project.json "ORTC.Adapter.Version" "%nugetVersion%" %peerCCTestPath%\PeerConnectionClient_UsingORTCNuget.Win10\project.json

goto:eof


:copyFiles
if EXIST %1 (
	call:createFolder %2
	echo Copying %1 to %2
	xcopy /s /e /y %1 %2
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

:cleanTempFolder
echo Cleaning...
rmdir /s /q winrt\projects\temp
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
echo bin\generateAdapterNuget.bat
echo.
echo Creating prerelase nuget package with version number 1.0.1-Beta
echo bin\generateAdapterNuget.bat -b
echo.
echo Creating prerelase nuget package and publish it to locally nuget storage
echo bin\generateAdapterNuget.bat -b -p -s [path to local nuget storage]
echo.

goto:eof
:failure
echo.
echo ERROR: %~2
echo.
::echo FAILURE: Could not create a nuget package.
set failure=%~1
goto:eof

:endedWithError
call::cleanTempFolder
goto:end

:done
echo %v%>%nugetPackageVersion%
echo.
echo Success: ORTC nuget package is created.
echo.
:end