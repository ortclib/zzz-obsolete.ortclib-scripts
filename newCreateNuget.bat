@ECHO off

setlocal EnableDelayedExpansion
ECHO Started creating ortc nuget package...

SET projectNameOrtc=org.ortc
SET projectNameWebRtc=webrtc_winrt_api
SET nugetOrtcName=Ortc
SET nugetWebRtcName=WebRtc
SET nugetVersion=
SET publishKey=
SET failure=0
SET powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
SET PROGFILES=%ProgramFiles%
IF NOT "%ProgramFiles(x86)%" == "" SET PROGFILES=%ProgramFiles(x86)%
SET MSVCDIR="%PROGFILES%\Microsoft Visual Studio 14.0"
SET nuget=bin\nuget.exe
SET SolutionPath=""
SET SolutionPathOrtc=ortc\windows\solutions\Ortc.Nuget.sln
SET SolutionPathWebRtc=webrtc\windows\solutions\WebRtc.Nuget.sln
SET PROJECTPATH=winrt\projects\ortc-template.csproj
SET nugetOrtcBasePath=ortc\windows\nuget
SET nugetWebRtcBasePath=webrtc\windows\nuget
SET OrtcWebRtcSolutionPath=webrtc\xplatform\webrtc\webrtcForOrtc.vs2015.sln
SET WinrtWebRtcSolutionPath=webrtc\xplatform\webrtc\webrtcLib.sln
SET WebRtcSolutionPath=""
::SET nugetSpec=%nugetBasePath%\package\%nugetName%\%projectNameForNuget%.nuspec
::SET nugetOutputPath=%nugetBasePath%\..\NugetOutput\%projectNameForNuget%
::SET nugetTemplateProjectsPath=%nugetBasePath%\templates\%projectNameForNuget%
SET nugetOutputPath=""
SET nugetPackageVersion=""
SET nugetName=""
SET nugetPath=""
SET nugetSpec=""
::SET nugetPackageVersion=%nugetBasePath%\%projectNameForNuget%.version

SET peerCCSourcePath=samples\PeerCC
SET peerCCTestPath=winrt\test\PeerCC
SET peerCCProjectTemaplePath=winrt\templates\samples\PeerCC

SET nugetVersion=%2


SET ortcAvailable=0

::targets
SET generate_Ortc_Nuget=0
SET generate_WebRtc_Nuget=0

::input arguments
SET supportedInputArguments=;target;version;key;beta;destination;publish;help;
SET target=all
SET version=1.0.0
SET key=
SET beta=1
SET destination=d:\myNugetPackages
SET publish=0
SET help=0

::build variables
set msVS_Path=""
set msVS_Version=""
set x86BuildCompilerOption=amd64_x86
set x64BuildCompilerOption=amd64
set armBuildCompilerOption=amd64_arm
set currentBuildCompilerOption=amd64

::Version
SET v=1.0.0

::Api key for publishing
SET k=

::PreRelease flag
SET b=0

::Destination nuget storage
SET s=

::Publish flag
SET p=

::Prepare test environment
SET t=

:parseInputArguments
if "%1"=="" (
	if not "%nome%"=="" (
		set "%nome%=1"
		set nome=""
	) else (
		goto:main
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
goto parseInputArguments

::===========================================================================
:: Start execution of main flow (if parsing input parameters passed without issues)

:main

::CALL:showHelp

CALL:checkOrtcAvailability

CALL:identifyTarget

CALL:downloadNuget

CALL:generateNugetPackages

GOTO:DONE

:checkOrtcAvailability
IF EXIST ortc\NUL SET ortcAvailable=1
GOTO:EOF

:identifyTarget
SET validInput=0
SET messageText=
echo "%target%"
IF /I "%target%"=="all" (
	SET generate_Ortc_Nuget=%ortcAvailable%
	SET generate_WebRtc_Nuget=1
	SET validInput=1
	IF !prepare_ORTC_Environemnt! EQU 1 (
		SET messageText=Generating WebRtc and Ortc nuget packages ...
	) ELSE (
		SET messageText=Generating WebRtc nuget package ...
		)
) ELSE (
	IF /I "%target%"=="webrtc" (
		SET generate_WebRtc_Nuget=1
		SET validInput=1
	)
	IF /I "%target%"=="ortc" (
	IF %ortcAvailable% EQU 0 CALL:ERROR 1 "ORTC is not available!"
		SET generate_Ortc_Nuget=1
		SET validInput=1
	)

	IF !validInput!==1 (
		SET messageText=Preparing %target% development environment ...
	)
)

:: If input is not valid terminate script execution
IF !validInput!==1 (
	CALL:error 0 %warning% "!messageText!"
) ELSE (
	CALL:error 1 %errorMessageInvalidTarget%
)

GOTO:EOF
:downloadNuget
if NOT EXIST %nuget% (
	echo Nuget donwload started
	%powershell_path% "Start-BitsTransfer https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -Destination bin\nuget.exe"
	
	IF ERRORLEVEL 1 CALL:error 1 "Could not download nuget.exe"
)
GOTO:EOF

:preparePackage

SET nugetTargetPath=""
SET nugetSpecPath=""
SET nugetBasePath=""
SET projectName=""
SET libSourceBasePath=""
SET projectNameForNuget=""

IF /I "%~1"=="ortc" (
	SET projectName=%projectNameOrtc%
	SET nugetBasePath=%nugetOrtcBasePath%
	SET nugetName=%nugetOrtcName%
	SET projectNameForNuget=%projectNameOrtc%
	SET libSourceBasePath=ortc\windows\solutions\Build\Output
) ELSE (
	SET projectName=%projectNameWebRtc%
	SET nugetBasePath=%nugetWebRtcBasePath%
	SET nugetName=%nugetWebRtcName%
	SET projectNameForNuget=%projectNameWebRtc%
	SET libSourceBasePath=webrtc\windows\solutions\Build\Output
)

SET nugetTargetPath=%nugetBasePath%\%projectName%.targets
SET nugetSpecPath=%nugetBasePath%\%projectName%.nuspec
SET nugetPackageVersion=%nugetBasePath%\%projectName%.version
SET nugetPath=%nugetBasePath%\package
SET nugetOutputPath=%nugetBasePath%\..\NugetOutput\%nugetName%
	echo determine
CALL:determineNugetVersion
	
SET nugetBuildPath=%nugetPath%\%nugetName%\build
SET nugetBuildNativePath=%nugetBuildPath%\native
SET nugetBuildNetCorePath=%nugetBuildPath%\netcore45
SET nugetBuildNetCorex86Path=%nugetBuildNetCorePath%\x86
SET nugetBuildNetCorex64Path=%nugetBuildNetCorePath%\x64
SET nugetBuildNetCoreARMPath=%nugetBuildNetCorePath%\arm

SET nugetLibPath=%nugetPath%\%nugetName%\lib
SET nugetLibNetCorePath=%nugetLibPath%\netcore45
SET nugetLibUAPPath=%nugetLibPath%\uap10.0

SET nugetRuntimesPath=%nugetPath%\%nugetName%\runtimes
SET nugetRuntimesx86Path=%nugetRuntimesPath%\win10-x86\native
SET nugetRuntimesx64Path=%nugetRuntimesPath%\win10-x64\native
SET nugetRuntimesARMPath=%nugetRuntimesPath%\win10-arm\native

SET sourcex86Path=%libSourceBasePath%\x86\Release\%projectName%
SET sourcex86DllPath=%sourcex86Path%\%projectNameForNuget%.dll
SET sourcex86WinmdPath=%sourcex86Path%\%projectNameForNuget%.winmd
SET sourcex86PdbPath=%sourcex86Path%\%projectNameForNuget%.pdb

SET sourcex64Path=%libSourceBasePath%\x64\Release\%projectName%
SET sourcex64DllPath=%sourcex64Path%\%projectNameForNuget%.dll
SET sourcex64WinmdPath=%sourcex64Path%\%projectNameForNuget%.winmd
SET sourcex64PdbPath=%sourcex64Path%\%projectNameForNuget%.pdb

SET sourcexARMPath=%libSourceBasePath%\ARM\Release\%projectName%
SET sourcexARMDllPath=%sourcexARMPath%\%projectNameForNuget%.dll
SET sourcexARMWinmdPath=%sourcexARMPath%\%projectNameForNuget%.winmd
SET sourcexARMPdbPath=%sourcexARMPath%\%projectNameForNuget%.pdb
SET nugetSpec=%nugetPath%\%nugetName%\%projectNameForNuget%.nuspec
RMDIR /s /q %nugetPath%\%nugetName%\

CALL:createFolder %nugetPath%\%nugetName%

CALL::copyFiles %sourcexARMDllPath% %nugetRuntimesARMPath%

CALL::copyFiles %sourcex64DllPath% %nugetRuntimesx64Path%

CALL::copyFiles %sourcex86DllPath% %nugetRuntimesx86Path%

CALL::copyFiles %sourcex86WinmdPath% %nugetLibUAPPath%

CALL::copyFiles %nugetTargetPath% %nugetBuildNativePath%

CALL:copyFiles %nugetSpecPath% %nugetPath%\%nugetName%

CALL:setNugetVersion %nugetSpec%

CALL:makeNuget

GOTO:EOF


:setCompilerOption

REG Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && SET CPU=x86 || SET CPU=x64

echo CPU arhitecture is %CPU%

if %CPU% == x86 (
	set x86BuildCompilerOption=x86
	set x64BuildCompilerOption=x86_amd64
	set armBuildCompilerOption=x86_arm
)

if %~1%==x86 (
	set currentBuildCompilerOption=%x86BuildCompilerOption%
) else (
	if %~1%==ARM (
		set currentBuildCompilerOption=%armBuildCompilerOption%
	) else (
		set currentBuildCompilerOption=%x64BuildCompilerOption%
	)
)

echo Selected compiler option is %currentBuildCompilerOption%

GOTO:EOF

:determineVisualStudioPath

SET progfiles=%ProgramFiles%
IF NOT "%ProgramFiles(x86)%" == "" SET progfiles=%ProgramFiles(x86)%

REM Check if Visual Studio 2015 is installed
SET msVS_Path="%progfiles%\Microsoft Visual Studio 14.0"
SET msVS_Version=14

IF NOT EXIST %msVS_Path% (
	REM Check if Visual Studio 2013 is installed
	SET msVS_Path="%progfiles%\Microsoft Visual Studio 12.0"
	SET msVS_Version=12
)

IF NOT EXIST %msVS_Path% CALL:error 1 "Visual Studio 2015 or 2013 is not installed"

ECHO "Visual Studio path is %msVS_Path%"

GOTO:EOF

:generateNugetPackages
ECHO Generating nuget packages...
CALL:determineVisualStudioPath

IF %generate_Ortc_Nuget% EQU 1 (
	ECHO Creating Ortc nuget package ...
	SET WebRtcSolutionPath=%OrtcWebRtcSolutionPath%
	SET nugetName=%nugetOrtcName%
	CALL:build %SolutionPathOrtc% %projectNameOrtc% x86
	CALL:build %SolutionPathOrtc% %projectNameOrtc% x64
	CALL:build %SolutionPathOrtc% %projectNameOrtc% arm
	
	CALL:preparePackage Ortc
)

IF %generate_WebRtc_Nuget% EQU 1 (
	ECHO Creating WebRtc nuget package ...
	SET WebRtcSolutionPath=%WinrtWebRtcSolutionPath%
	SET nugetName=%nugetWebRtcName%
	CALL:build %SolutionPathWebRtc% %projectNameWebRtc% x86
	CALL:build %SolutionPathWebRtc% %projectNameWebRtc% x64
	CALL:build %SolutionPathWebRtc% %projectNameWebRtc% arm

	CALL:preparePackage WebRtc
)

GOTO:EOF

:build

SET CONFIGURATION=Release
CALL:setCompilerOption %~3
echo %msVS_Path%
echo %currentBuildCompilerOption%
::CALL %msVS_Path%\VC\vcvarsall.bat %currentBuildCompilerOption%
CALL %msVS_Path%\VC\vcvarsall.bat %currentBuildCompilerOption%
IF !ERRORLEVEL! EQU 1 CALL:error 1 "Could not setup %~2 compiler"

echo solution: %~1
echo project: %~2
echo compiler option: %~3
echo CONFIGURATION: %CONFIGURATION%
echo PLATFORM: %PLATFORM%
call bin\buildWebRTC.bat %WebRtcSolutionPath% %CONFIGURATION% %~3 %nugetName%
if ERRORLEVEL 1 CALL:error 1 "Building %~2 project for %PLATFORM% %CONFIGURATION% has failed"

::MSBuild %~1 /t:%~2 /property:Configuration=%CONFIGURATION% /property:Platform=%~3
MSBuild %~1 /property:Configuration=%CONFIGURATION% /property:Platform=%~3 /m

if ERRORLEVEL 1 CALL:error 1 "Building %~2 project for %PLATFORM% %CONFIGURATION% has failed"
GOTO:EOF

:setNugetVersion
ECHO version %version%
ECHO Nuspec: %~1
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %~1 "<version></version>" "<version>%version%</version>" %~1
if ERRORLEVEL 1 CALL:error 1 "Failed creating the %nugetName% nuget package"
goto:eof

:makeNuget

IF EXIST %nugetOutputPath%\%nugetName%\ (
	RMDIR /s /q %nugetOutputPath%\%nugetName%\
)
CALL:createFolder %nugetOutputPath%\%nugetName%

%nuget% pack %nugetSpec% -OutputDirectory %nugetOutputPath%\%nugetName%
IF ERRORLEVEL 1 CALL:error 1 "Failed creating the %nugetName% nuget package"

IF EXIST %nugetPath% (
	RMDIR /s /q %nugetPath%
)

goto:eof

:setNugetApiKey
%nuget% setapikey %publishKey%
if ERRORLEVEL 1 CALL:error 0 "Failed creating the %nugetName% nuget package"
goto:eof

:publishNuget
IF NOT "%key%"=="" CALL:setNugetApiKey

IF %platform% EQU 1 (
	IF NOT "%destination%"=="" (
		%nuget% push %nugetOutputPath%\%nugetName%\%nugetName%.%nugetVersion%.nupkg -s %destination%
	) ELSE (
		%nuget% push %nugetOutputPath%\%nugetName%\%nugetName%.%nugetVersion%.nupkg
	)
)
IF ERRORLEVEL 1 CALL:error 1 "Failed publishing the %nugetName% nuget package"

goto:eof

:determineNugetVersion
IF EXIST %nugetPackageVersion% (
	SET /p version=< %nugetPackageVersion%
)

ECHO Current Nuget Version is !version!
FOR /f "tokens=1-3 delims=." %%a IN ("!version!") DO (
  SET /a build=%%c+1
  SET version=%%a.%%b.!build!
)

IF BETA EQU 1 SET version=!version!-Beta

ECHO New Nuget Version is !version!
GOTO:EOF

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
IF EXIST %1 (
	CALL:createFolder %2
	ECHO Copying %1 to %2
	COPY %1 %2
	IF ERRORLEVEL 1 CALL:error 1 "Could not copy a %1"
) else (
	CALL:error 1 "Could not copy a %1"
)
goto:eof

:createFolder
IF NOT EXIST %1 (
	MKDIR %1
	IF ERRORLEVEL 1 CALL:error 1 "Could not make a directory %1"
)
goto:eof

:showHelp
IF NOT %help% EQU 0 GOTO:EOF

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
REM Print the error message and terminate further execution if error is critical.Firt argument is critical error flag (1 for critical). Second is error message
:error
SET criticalError=%~1
SET errorMessage=%~2

IF %criticalError%==0 (
	ECHO.
	ECHO "WARNING: %errorMessage%"
	ECHO.
) ELSE (
	ECHO.
	ECHO "CRITICAL ERROR: %errorMessage%"
	ECHO.
	ECHO.
	ECHO "FAILURE:Preparing environment has failed!"
	ECHO.
	::terminate batch execution
	CALL bin\batchTerminator.bat
)
GOTO:EOF

:done
echo %v%
echo %nugetPackageVersion%
echo %v%>%nugetPackageVersion%
echo.
echo Success: ORTC nuget package is created.
echo.
:end