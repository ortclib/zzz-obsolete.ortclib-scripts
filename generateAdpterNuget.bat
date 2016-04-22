@echo off
setlocal EnableDelayedExpansion
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
if "%failure%" neq "0" goto:endedWithError
rmdir /s /q winrt\projects\temp

goto:done
:setNugetVersion
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %adapterTempProjectPath%\%projectName%.nuspec "<version></version>" "<version>%nugetVersion%</version>" %adapterTempProjectPath%\%projectName%.nuspec
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
goto:eof

:restoreNugetDependencies
%nuget% restore %adapterTempProjectPath%\project.json
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
goto:eof

:createNuget
%nuget% pack %adapterTempProjectPath%\%projectName%.csproj -Build -Version %nugetVersion% -OutputDirectory %nugetOutputPath% -Properties Configuration=Release -Properties Platform=AnyCPU
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
goto:eof

:setNugetApiKey
%nuget% setapikey %publishKey%
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
goto:eof

:publishNuget
if not "%p%"=="" (
	if not %s%=="" (
		%nuget% push %nugetOutputPath%\%nugetName%.%nugetVersion%.nupkg -s %s%
	) else (
		%nuget% push %nugetOutputPath%\%nugetName%.%nugetVersion%.nupkg
	)
	if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
)

goto:eof

:createFolder
if NOT EXIST %1 (
	mkdir %1
	if ERRORLEVEL 1 call:failure %errorlevel% "Could not make a directory %1"
)
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

:cleanTempFolder
echo Cleaning...
rmdir /s /q winrt\projects\temp
goto:eof

:failure
echo.
echo ERROR: %~2
echo.
echo FAILURE: Could not create a nuget package.
set failure=%~1
goto:eof

:endedWithError
call::cleanTempFolder
goto:eof

:done
echo %v%>%nugetPackageVersion%
echo.
echo Success: ORTC nuget package is created.
echo.