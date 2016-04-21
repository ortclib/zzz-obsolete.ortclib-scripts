@echo off

set projectName=org.ortc.adapter
set nugetName=ORTC.Adapter
set nugetVersion=%1
set publishKey=%2
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

set adapterProjectPath=winrt\projects\api\org.ortc.adapter\org.ortc.adapter
set adapterTempProjectPath=winrt\projects\temp\org.ortc.adapter\org.ortc.adapter


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
	call:publishNuget
	if "%failure%" neq "0" goto:endedWithError
)


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

:publishNuget

%nuget% setapikey %publishKey%

%nuget% push %nugetOutputPath%\%nugetName%.%nugetVersion%.nupkg
if ERRORLEVEL 1 call:failure %errorlevel% "Failed creating the %nugetName% nuget package"
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
echo.
echo Success: ORTC nuget package is created.
echo.