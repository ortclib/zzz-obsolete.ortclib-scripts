:: Name:     newCreateNuget.bat
:: Purpose:  Creates ORTC and WebRTC nuget packages
:: Author:   Sergej Jovanovic
:: Email:	 sergej@gnedo.com
:: Revision: November 2016 - initial version

@ECHO off

SETLOCAL EnableDelayedExpansion

::projects
SET projectNameOrtc=org.ortc
SET projectNameWebRtc=webrtc_winrt_api
SET nugetOrtcName=Ortc
SET nugetWebRtcName=WebRtc

::paths
SET powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
SET PROGFILES=%ProgramFiles%
IF NOT "%ProgramFiles(x86)%" == "" SET PROGFILES=%ProgramFiles(x86)%
SET MSVCDIR="%PROGFILES%\Microsoft Visual Studio 14.0"
SET nuget=bin\nuget.exe
SET SolutionPath=""
SET SolutionPathOrtc=ortc\windows\solutions\Ortc.sln
SET SolutionPathWebRtc=webrtc\windows\solutions\WebRtc.sln
SET nugetOrtcBasePath=ortc\windows\nuget
SET nugetWebRtcBasePath=webrtc\windows\nuget
SET OrtcWebRtcSolutionPath=webrtc\xplatform\webrtc\webrtcForOrtc.vs2015.sln
SET WinrtWebRtcSolutionPath=webrtc\xplatform\webrtc\webrtcLib.sln
SET WebRtcSolutionPath=""
SET nugetOutputPath=""
SET nugetPath=""
SET nugetSpec=""
SET nugetExecutableDestinationPath=bin\nuget.exe

::nuget
SET nugetVersion=
SET publishKey=
SET nugetPackageVersion=""
SET nugetName=""
SET nugetOrtcTemplateProjectPath=%nugetOrtcBasePath%\templates\Ortc.Nuget.sln
SET nugetOrtcTemplateProjectDestinationPath=ortc\windows\solutions\
SET nugetWebRtcTemplateProjectPath=%nugetWebRtcBasePath%\templates\WebRtc.Nuget.sln
SET nugetWebRtcTemplateProjectDestinationPath=webrtc\windows\solutions\

::urls
SET nugetDownloadUrl=https://dist.nuget.org/win-x86-commandline/latest/nuget.exe

::helpers
SET failure=0
SET ortcAvailable=0

::targets
SET generate_Ortc_Nuget=0
SET generate_WebRtc_Nuget=0

::input arguments
SET supportedInputArguments=;target;version;key;beta;destination;publish;help;logLevel;
SET target=all
SET version=1.0.0
SET key=
SET beta=1
SET destination=d:\myNugetPackages
SET publish=0
SET help=0
SET logLevel=2

::build variables
SET msVS_Path=""
SET msVS_Version=""
SET x86BuildCompilerOption=amd64_x86
SET x64BuildCompilerOption=amd64
SET armBuildCompilerOption=amd64_arm
SET currentBuildCompilerOption=amd64

::log levels
SET globalLogLevel=2											
SET error=0														
SET info=1														
SET warning=2													
SET debug=3														
SET trace=4	

ECHO.
CALL:print %info% "Started creating nuget packages ..."
ECHO.

:parseInputArguments
IF "%1"=="" (
	IF NOT "%nome%"=="" (
		SET "%nome%=1"
		SET nome=""
	) ELSE (
		GOTO:main
	)
)

SET aux=%1
IF "%aux:~0,1%"=="-" (
	IF NOT "%nome%"=="" (
		SET "%nome%=1"
	)
   SET nome=%aux:~1,250%
) ELSE (
   SET "%nome%=%1"
   SET nome=
)

SHIFT
GOTO parseInputArguments

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
CALL:print %trace% "Checking is Ortc available"
IF EXIST ortc\NUL SET ortcAvailable=1
GOTO:EOF

:identifyTarget
CALL:print %trace% "Identifying build targets"
SET validInput=0
SET messageText=

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
		SET messageText=Generating %target% nuget package ...
	)
)

:: If input is not valid terminate script execution
IF !validInput!==1 (
	CALL:print %warning% "!messageText!"
) ELSE (
	CALL:error 1 %errorMessageInvalidTarget%
)
GOTO:EOF

:downloadNuget
IF NOT EXIST %nuget% (
	CALL:print %debug% "Downloading nuget.exe"
	%powershell_path% "Start-BitsTransfer %nugetDownloadUrl% -Destination %nugetExecutableDestinationPath%"
	
	IF ERRORLEVEL 1 CALL:error 1 "Could not download nuget.exe"
)
GOTO:EOF

:generateNugetPackages
CALL:print %warning% "Generating nuget packages ..."
 
CALL:determineVisualStudioPath

IF %generate_Ortc_Nuget% EQU 1 (
	CALL:print %warning% "Creating Ortc nuget package ..."
	
	CALL:prepareTemplates ortc
	
	SET SolutionPathOrtc=!nugetOrtcTemplateProjectDestinationPath!Ortc.Nuget.sln
	SET WebRtcSolutionPath=%OrtcWebRtcSolutionPath%
	SET nugetName=%nugetOrtcName%
	
	CALL:build !SolutionPathOrtc! Api\org_Ortc\org_ortc x86
	CALL:build !SolutionPathOrtc! Api\org_Ortc\org_ortc x64
	CALL:build !SolutionPathOrtc! Api\org_Ortc\org_ortc arm
	
	CALL:preparePackage Ortc
)

IF %generate_WebRtc_Nuget% EQU 1 (
	CALL:print %warning% "Creating WebRtc nuget package ..."

	CALL:prepareTemplates webrtc
	
	SET SolutionPathWebRtc=!nugetWebRtcTemplateProjectDestinationPath!WebRtc.Nuget.sln
	SET WebRtcSolutionPath=%WinrtWebRtcSolutionPath%
	SET nugetName=%nugetWebRtcName%
	
	CALL:build !SolutionPathWebRtc! Api\org_WebRtc\webrtc_winrt_api x86
	CALL:build !SolutionPathWebRtc! Api\org_WebRtc\webrtc_winrt_api x64
	CALL:build !SolutionPathWebRtc! Api\org_WebRtc\webrtc_winrt_api arm

	CALL:preparePackage WebRtc
)
GOTO:EOF

:build

SET CONFIGURATION=Release
CALL:setCompilerOption %~3

CALL %msVS_Path%\VC\vcvarsall.bat %currentBuildCompilerOption%
IF !ERRORLEVEL! EQU 1 CALL:error 1 "Could not setup %~2 compiler"

CALL:print %warning% "Building WebRtc for %PLATFORM%"
CALL:print %trace% "Solution: %~1"
CALL:print %trace% "Project: %~2"
CALL:print %trace% "Compiler option: %~3"
CALL:print %trace% "CONFIGURATION: %CONFIGURATION%"
CALL:print %trace% "PLATFORM: %PLATFORM%"

IF %logLevel% GEQ %trace% (
	CALL bin\buildWebRTC.bat %WebRtcSolutionPath% %CONFIGURATION% %~3 %nugetName%
) ELSE (
	CALL bin\buildWebRTC.bat %WebRtcSolutionPath% %CONFIGURATION% %~3 %nugetName%  >NUL
)
IF ERRORLEVEL 1 CALL:error 1 "Building %~2 project for %PLATFORM% %CONFIGURATION% has failed"

CALL:print %warning% "Building %~2 for %PLATFORM%"
CALL:print %trace% "Solution: %~1"
CALL:print %trace% "Project: %~2"
CALL:print %trace% "Compiler option: %~3"
CALL:print %trace% "CONFIGURATION: %CONFIGURATION%"
pause
IF %logLevel% GEQ %trace% (
	MSBuild %~1 /t:%~2 /property:Configuration=%CONFIGURATION% /property:Platform=%~3 /nodeReuse:False
) ELSE (
	MSBuild %~1 /t:%~2 /property:Configuration=%CONFIGURATION% /property:Platform=%~3 /nodeReuse:False >NUL
)

::MSBuild %~1 /property:Configuration=%CONFIGURATION% /property:Platform=%~3 /m

IF ERRORLEVEL 1 CALL:error 1 "Building %~2 project for %PLATFORM% %CONFIGURATION% has failed"
GOTO:EOF

:prepareTemplates

IF /I "%~1"=="webrtc" (
	SET nugetTemplateProjectPath=%nugetWebRtcTemplateProjectPath%
	SET nugetTemplateProjectDestinationPath=%nugetWebRtcTemplateProjectDestinationPath%
) ELSE (
	SET nugetTemplateProjectPath=%nugetOrtcTemplateProjectPath%
	SET nugetTemplateProjectDestinationPath=%nugetOrtcTemplateProjectDestinationPath%
)

CALL:copyFiles !nugetTemplateProjectPath! !nugetTemplateProjectDestinationPath! 
	
GOTO:EOF

:preparePackage
CALL:print %trace% "Creating a package ..."
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
CALL:print %trace% "Determining compiler options ..."
REG Query "HKLM\Hardware\Description\System\CentralProcessor\0" | FIND /i "x86" > NUL && SET CPU=x86 || SET CPU=x64

CALL:print %trace% "CPU arhitecture is %CPU%"

IF /I %CPU% == x86 (
	SET x86BuildCompilerOption=x86
	SET x64BuildCompilerOption=x86_amd64
	SET armBuildCompilerOption=x86_arm
)

IF /I %~1==x86 (
	SET currentBuildCompilerOption=%x86BuildCompilerOption%
) ELSE (
	IF /I %~1==ARM (
		SET currentBuildCompilerOption=%armBuildCompilerOption%
	) ELSE (
		SET currentBuildCompilerOption=%x64BuildCompilerOption%
	)
)

CALL:print %trace% "Selected compiler option is %currentBuildCompilerOption%"

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

:setNugetVersion
ECHO version %version%
ECHO Nuspec: %~1
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %~1 "<version></version>" "<version>%version%</version>" %~1
if ERRORLEVEL 1 CALL:error 1 "Failed creating the %nugetName% nuget package"
GOTO:EOF

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

GOTO:EOF

:setNugetApiKey
%nuget% setapikey %publishKey%
if ERRORLEVEL 1 CALL:error 0 "Failed creating the %nugetName% nuget package"
GOTO:EOF

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

GOTO:EOF

:determineNugetVersion
IF EXIST %nugetPackageVersion% (
	SET /p version=< %nugetPackageVersion%
)

ECHO Current Nuget Version is !version!
FOR /f "tokens=1-3 delims=." %%a IN ("!version!") DO (
  SET /a build=%%c+1
  SET version=%%a.%%b.!build!
)

IF %beta% EQU 1 (
	SET nugetVersion=!version!-Beta
) ELSE (
	SET nugetVersion=!version!
)

ECHO New Nuget Version is !nugetVersion!
GOTO:EOF

:copyFiles
IF EXIST %1 (
	CALL:createFolder %2
	ECHO Copying %1 to %2
	COPY %1 %2
	IF ERRORLEVEL 1 CALL:error 1 "Could not copy a %1"
) else (
	CALL:error 1 "Could not copy a %1"
)
GOTO:EOF

:createFolder
IF NOT EXIST %1 (
	MKDIR %1
	IF ERRORLEVEL 1 CALL:error 1 "Could not make a directory %1"
)
GOTO:EOF

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

GOTO:EOF

REM Print logger message. First argument is log level, and second one is the message
:print
SET logType=%1
SET logMessage=%~2

if %logLevel% GEQ  %logType% (
	if %logType%==0 ECHO [91m%logMessage%[0m
	if %logType%==1 ECHO [92m%logMessage%[0m
	if %logType%==2 ECHO [93m%logMessage%[0m
	if %logType%==3 ECHO %logMessage%
	if %logType%==4 ECHO %logMessage%
)

GOTO:EOF

:cleanup
IF EXIST !nugetWebRtcTemplateProjectDestinationPath!Ortc.Nuget.sln DEL /s /q /f !nugetWebRtcTemplateProjectDestinationPath!Ortc.Nuget.sln > NUL
IF EXIST !nugetOrtcTemplateProjectDestinationPath!WebRtc.Nuget.sln DEL /s /q /f !nugetOrtcTemplateProjectDestinationPath!WebRtc.Nuget.sln > NUL

GOTO:EOF

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
	ECHO "FAILURE: Creating nuget package has failed!"
	ECHO.
	CALL:cleanup
	::terminate batch execution
	CALL bin\batchTerminator.bat
)
GOTO:EOF

:done
CALL:cleanup
echo %version%
echo %nugetPackageVersion%
echo %version%>%nugetPackageVersion%
echo.
echo Success:  Nuget package is created.
echo.
:end