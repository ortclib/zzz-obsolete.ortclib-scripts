:: Name:      createNuget.bat
:: Purpose:   Creates ORTC and WebRTC nuget packages
:: Author:    Sergej Jovanovic
:: Email:     sergej@gnedo.com
:: Twitter:   @JovanovicSergej
:: Revision:  November 2016 - initial version

@ECHO off

SETLOCAL EnableDelayedExpansion

::projects
SET projectNameOrtc=Org.Ortc
SET projectNameWebRtc=Org.WebRtc
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
SET peerCCPublishingPath=Publish\PeerCC
SET peerCCSourcePath=common\windows\samples\PeerCC\Client
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
SET startTime=0
SET endingTime=0

::targets
SET generate_Ortc_Nuget=0
SET generate_WebRtc_Nuget=0

::input arguments
SET supportedInputArguments=;target;version;key;beta;destination;publish;help;logLevel;
SET target=""
SET version=1.0.0
SET key=
SET beta=1
SET destination=
SET publish=0
SET help=0
SET logLevel=2

::build variables
SET msVS_Path=""
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

SET errorMessageInvalidArgument="Invalid input argument. For the list of available arguments and usage examples, please run script with -help option."

IF "%1"=="" SET help=1

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
   SET validArgument=0
   CALL:checkIfArgumentIsValid !nome! validArgument
   IF !validArgument!==0 CALL:error 1 %errorMessageInvalidArgument%
) ELSE (
	IF NOT "%nome%"=="" (
		SET "%nome%=%1"
	) else (
		CALL:error 1 %errorMessageInvalidArgument%
	)
   SET nome=
)
SHIFT
GOTO parseInputArguments

::===========================================================================
:: Start execution of main flow (if parsing input parameters passed without issues)

:main
SET startTime=%time%

CALL:precheck

CALL:showHelp

ECHO.
CALL:print %info% "Started creating nuget packages ..."
ECHO.

CALL:checkOrtcAvailability

CALL:identifyTarget

CALL:downloadNuget

CALL:generateNugetPackages

IF %publish% EQU 1 (
	CALL:publishNuget
	CALL:publishSamples
)

GOTO:DONE

:precheck
IF NOT "%CD%"=="%CD: =%" CALL:error 1 "Path must not contain folders with spaces in name"
IF EXIST ..\bin\nul (
	CALL:error 1 "Do not run scripts from bin directory!"
	CALL batchTerminator.bat
)
GOTO:EOF

REM Check if entered valid input argument
:checkIfArgumentIsValid
IF "!supportedInputArguments:;%~1;=!" neq "%supportedInputArguments%" (
	::it is valid
	SET %2=1
) ELSE (
	::it is not valid
	SET %2=0
)
GOTO:EOF

:checkOrtcAvailability
CALL:print %trace% "Checking is Ortc available"
IF EXIST ortc\NUL SET ortcAvailable=1
GOTO:EOF

:identifyTarget
CALL:print %trace% "Identifying build targets"
SET validInput=0
SET messageText=

IF "%target%"=="" CALL:error 1 "Target has to be specified. Available targets are Ortc and WebRtc."

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
	CALL:error 1 "Invalid target name provided. Available targets are Ortc and WebRtc."
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
	
	CALL:build !SolutionPathWebRtc! Api\org_WebRtc\Org.WebRtc x86
	CALL:build !SolutionPathWebRtc! Api\org_WebRtc\Org.WebRtc x64
	CALL:build !SolutionPathWebRtc! Api\org_WebRtc\Org.WebRtc arm

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
	CALL bin\buildWebRTC.bat %WebRtcSolutionPath% %CONFIGURATION% %~3 %nugetName% >NUL
)
IF ERRORLEVEL 1 CALL:error 1 "Building %~2 project for %PLATFORM% %CONFIGURATION% has failed"

CALL:print %warning% "Building %~2 for %PLATFORM%"
CALL:print %debug% "Solution: %~1"
CALL:print %debug% "Project: %~2"
CALL:print %debug% "Compiler option: %~3"
CALL:print %debug% "CONFIGURATION: %CONFIGURATION%"

IF %logLevel% GEQ %trace% (
	MSBuild %~1 /property:Configuration=%CONFIGURATION% /property:Platform=%~3 /nodeReuse:False
) ELSE (
	MSBuild %~1 /property:Configuration=%CONFIGURATION% /property:Platform=%~3 /nodeReuse:False >NUL
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
CALL:print %debug% "Creating a package ..."

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
SET nugetOutputPath=%nugetBasePath%\..\NugetOutput
	
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

CALL:print %debug% "nugetTargetPath: !nugetTargetPath!"
CALL:print %debug% "nugetSpecPath: !nugetSpecPath!"
CALL:print %debug% "nugetPackageVersion: !nugetPackageVersion!"
CALL:print %debug% "nugetPath: !nugetPath!"
CALL:print %debug% "nugetOutputPath: !nugetOutputPath!"

CALL:print %debug% "nugetBuildPath: !nugetBuildPath!"
CALL:print %debug% "nugetBuildNativePath: !nugetBuildNativePath!"
CALL:print %debug% "nugetBuildNetCorePath: !nugetBuildNetCorePath!"
CALL:print %debug% "nugetBuildNetCorex86Path: !nugetBuildNetCorex86Path!"
CALL:print %debug% "nugetBuildNetCorex64Path: !nugetBuildNetCorex64Path!"
CALL:print %debug% "nugetBuildNetCoreARMPath: !nugetBuildNetCoreARMPath!"

CALL:print %debug% "nugetLibPath: !nugetLibPath!"
CALL:print %debug% "nugetLibNetCorePath: !nugetLibNetCorePath!"
CALL:print %debug% "nugetLibUAPPath: !nugetLibUAPPath!"

CALL:print %debug% "nugetRuntimesPath: !nugetRuntimesPath!"
CALL:print %debug% "nugetRuntimesx86Path: !nugetRuntimesx86Path!"
CALL:print %debug% "nugetRuntimesx64Path: !nugetRuntimesx64Path!"
CALL:print %debug% "nugetRuntimesARMPath: !nugetRuntimesARMPath!"

CALL:print %debug% "sourcex86Path: !sourcex86Path!"
CALL:print %debug% "sourcex86DllPath: !sourcex86DllPath!"
CALL:print %debug% "sourcex86WinmdPath: !sourcex86WinmdPath!"
CALL:print %debug% "sourcex86PdbPath: !sourcex86PdbPath!"

CALL:print %debug% "sourcex64Path: !sourcex64Path!"
CALL:print %debug% "sourcex64DllPath: !sourcex64DllPath!"
CALL:print %debug% "sourcex64WinmdPath: !sourcex64WinmdPath!"
CALL:print %debug% "sourcex64PdbPath: !sourcex64PdbPath!"

CALL:print %debug% "sourcexARMPath: !sourcexARMPath!"
CALL:print %debug% "sourcexARMDllPath: !sourcexARMDllPath!"
CALL:print %debug% "sourcexARMWinmdPath: !sourcexARMWinmdPath!"
CALL:print %debug% "sourcexARMPdbPath: !sourcexARMPdbPath!"

CALL:print %debug% "nugetSpec: !nugetSpec!"

IF EXIST %nugetPath%\%nugetName%\NUL RMDIR /s /q %nugetPath%\%nugetName%\

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

:publishSamples
IF generate_Ortc_Nuget EQU 1 (
	CALL:print %debug% "Publishing PeerCC.Ortc with nuget version !nugetVersion!..."
	CALL publishSamples -sample peercc -sdk ortc -nugetVersion !nugetVersion! -logLevel %logLevel%
)

IF generate_WebRtc_Nuget EQU 1 (
	CALL:print %debug% "Publishing PeerCC.WebRtc with nuget version !nugetVersion!..."
	CALL publishSamples -sample peercc -sdk webrtc -nugetVersion !nugetVersion! -logLevel %logLevel%
	
	CALL:print %debug% "Publishing ChatterBox with nuget version !nugetVersion!..."
	CALL publishSamples -sample chatterbox -sdk webrtc -nugetVersion !nugetVersion! -logLevel %logLevel%
)
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

IF NOT EXIST %msVS_Path% (
	REM Check if Visual Studio 2013 is installed
	SET msVS_Path="%progfiles%\Microsoft Visual Studio 12.0"
)

IF NOT EXIST %msVS_Path% CALL:error 1 "Visual Studio 2015 or 2013 is not installed"

CALL:print %trace% "Visual Studio path is %msVS_Path%"

GOTO:EOF

:setNugetVersion
CALL:print %debug% "Nuget version: %nugetVersion%"
CALL:print %debug% "Nuspec path: %~1"

%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 %~1 "<version></version>" "<version>%nugetVersion%</version>" %~1
IF ERRORLEVEL 1 CALL:error 1 "Failed creating the %nugetName% nuget package"
GOTO:EOF

:makeNuget

CALL:createFolder %nugetOutputPath%
CALL:print %warning% "Packing a nuget package"
%nuget% pack %nugetSpec% -OutputDirectory %nugetOutputPath%
IF ERRORLEVEL 1 CALL:error 1 "Failed creating the %nugetName% nuget package"

IF EXIST %nugetPath% (
	RMDIR /s /q %nugetPath%
)

GOTO:EOF

:setNugetApiKey
CALL:print %warning% "Setting nuget key"
%nuget% setApiKey %key%
if ERRORLEVEL 1 CALL:error 0 "Failed creating the %nugetName% nuget package"
GOTO:EOF

:publishNuget
IF NOT "%key%"=="" CALL:setNugetApiKey

IF %publish% EQU 1 (
	IF NOT "%destination%"=="" (
		CALL:print %debug% "Nuget package will be pushed to %destination%"
		%nuget% push %nugetOutputPath%\%nugetName%.%nugetVersion%.nupkg -Source %destination%
	) ELSE (
		CALL:print %debug% "Nuget package will be pushed to default location"
		%nuget% push %nugetOutputPath%\%nugetName%.%nugetVersion%.nupkg
	)
)
IF ERRORLEVEL 1 CALL:error 1 "Failed publishing the %nugetName% nuget package"

GOTO:EOF

:determineNugetVersion
IF "%version%"=="1.0.0" (
	IF EXIST %nugetPackageVersion% (
		SET /p version=< %nugetPackageVersion%
		
		CALL:print %debug% "Current Nuget Version is !version!"
		
		FOR /f "tokens=1-3 delims=." %%a IN ("!version!") DO (
			SET /a build=%%c+1
			SET version=%%a.%%b.!build!
		)
	)
)

IF %beta% EQU 1 (
	SET nugetVersion=!version!-Beta
) ELSE (
	SET nugetVersion=!version!
)

CALL:print %warning%  "New Nuget Version is !nugetVersion!"
GOTO:EOF

:copyFiles
IF EXIST %1 (
	CALL:createFolder %2
	CALL:print %debug% "Copying %1 to %2"
	COPY %1 %2
	IF ERRORLEVEL 1 CALL:error 1 "Could not copy a %1"
) ELSE (
	CALL:error 1 "Could not copy a %1"
)
GOTO:EOF

:createFolder
IF NOT EXIST %1 (
	CALL:print %trace% "Creating folder %1"
	MKDIR %1
	IF ERRORLEVEL 1 CALL:error 1 "Could not make a directory %1"
)
GOTO:EOF

:showHelp
IF %help% EQU 0 GOTO:EOF

ECHO.
ECHO    [92mAvailable parameters:[0m
ECHO.
ECHO  	[93m-beta[0m 		Flag for creating prerelase nuget package.
ECHO.
ECHO 	[93m-key[0m		Api key that is used for publishing nuget package on nuget.org. This is used in combination with 
ECHO		publish flag -publish. This will store your API key so that you never need to do this step again on this machine.
ECHO.
ECHO 	[93m-help[0m 		Show script usage
ECHO.
ECHO 	[93m-logLevel[0m	Log level (error=0, info =1, warning=2, debug=3, trace=4)
ECHO.
ECHO 	[93m-publish[0m	Publish created nuget package. By default it will be uploaded on nuget.org server. If it is 
ECHO		desired to publish it locally or on some another server, it sholud be used option -destination to specify 
ECHO		destination server
ECHO.
ECHO 	[93m-destination[0m	Used for specifying nuget server where package will be published. Default destination is nuget.org
ECHO.
ECHO 	[93m-target[0m		Name of the target to generate nuget package. Ortc or WebRtc.
ECHO.
ECHO 	[93m-version[0m	Nuget package version number. If this parameter is not passed it will be used incremented previous version number 
ECHO.
ECHO    [91mGenerated nuget package will be stored in ortc\windows\NugetOutput\ for Ortc and in webrtc\windows\NugetOutput\ for WebRtc.[0m
ECHO.
ECHO    [92mExamples:[0m
ECHO.
ECHO   [93mCreating Ortc nuget package with automated versioning and storing in ortc\windows\NugetOutput\ without publishing it. Log level is debug.[0m
ECHO    bin\createNuget.bat -target Ortc -logLevel 2
ECHO.
ECHO   [93mCreating WebRtc prerelase nuget package with version number 1.0.1-Beta[0m
ECHO    bin\createNuget.bat -beta -target WebRtc -version 1.0.1
ECHO.
ECHO   [93mCreating prerelase Ortc nuget package and publish it to locally nuget storage[0m
ECHO    bin\createNuget.bat -target Ortc -beta -publish -destination [path to local nuget storage]
ECHO.
ECHO.
ECHO   [93mCreating prerelase WebRtc nuget package and publish it to nuget.org[0m
ECHO    bin\createNuget.bat -target WebRtc -beta -publish -key [nuget.org api key]
ECHO.
CALL bin\batchTerminator.bat

GOTO:EOF

REM Print logger message. First argument is log level, and second one is the message
:print
SET logType=%1
SET logMessage=%~2

IF %logLevel% GEQ  %logType% (
	IF %logType%==0 ECHO [91m%logMessage%[0m
	IF %logType%==1 ECHO [92m%logMessage%[0m
	IF %logType%==2 ECHO [93m%logMessage%[0m
	IF %logType%==3 ECHO %logMessage%
	IF %logType%==4 ECHO %logMessage%
)

GOTO:EOF

:cleanup
IF EXIST !nugetWebRtcTemplateProjectDestinationPath!WebRtc.Nuget.sln DEL /s /q /f !nugetWebRtcTemplateProjectDestinationPath!WebRtc.Nuget.sln > NUL
IF EXIST !nugetOrtcTemplateProjectDestinationPath!Ortc.Nuget.sln DEL /s /q /f !nugetOrtcTemplateProjectDestinationPath!Ortc.Nuget.sln > NUL

GOTO:EOF

REM Print the error message and terminate further execution if error is critical.Firt argument is critical error flag (1 for critical). Second is error message
:error
SET criticalError=%~1
SET errorMessage=%~2

IF %criticalError%==0 (
	ECHO.
	CALL:print %warning% "WARNING: %errorMessage%"
	ECHO.
) ELSE (
	ECHO.
	CALL:print %error% "CRITICAL ERROR: %errorMessage%"
	ECHO.
	ECHO.
	CALL:print %error% "FAILURE: Creating nuget package has failed!"
	ECHO.
	CALL:cleanup
	SET endTime=%time%
	CALL:showTime
	::terminate batch execution
	CALL bin\batchTerminator.bat
)
GOTO:EOF

:showTime

SET options="tokens=1-4 delims=:.,"
FOR /f %options% %%a in ("%startTime%") do SET start_h=%%a&SET /a start_m=100%%b %% 100&SET /a start_s=100%%c %% 100&SET /a start_ms=100%%d %% 100
FOR /f %options% %%a in ("%endTime%") do SET end_h=%%a&SET /a end_m=100%%b %% 100&SET /a end_s=100%%c %% 100&SET /a end_ms=100%%d %% 100

SET /a hours=%end_h%-%start_h%
SET /a mins=%end_m%-%start_m%
SET /a secs=%end_s%-%start_s%
SET /a ms=%end_ms%-%start_ms%
IF %ms% lss 0 SET /a secs = %secs% - 1 & SET /a ms = 100%ms%
IF %secs% lss 0 SET /a mins = %mins% - 1 & SET /a secs = 60%secs%
IF %mins% lss 0 SET /a hours = %hours% - 1 & SET /a mins = 60%mins%
IF %hours% lss 0 SET /a hours = 24%hours%

SET /a totalsecs = %hours%*3600 + %mins%*60 + %secs% 

IF 1%ms% lss 100 SET ms=0%ms%
IF %secs% lss 10 SET secs=0%secs%
IF %mins% lss 10 SET mins=0%mins%
IF %hours% lss 10 SET hours=0%hours%

:: mission accomplished
ECHO [93mTotal execution time: %hours%:%mins%:%secs% (%totalsecs%s total)[0m

GOTO:EOF

:done
CALL:cleanup

ECHO %version%>%nugetPackageVersion%
ECHO.
CALL:print %info% "Success:  Nuget package is created."
ECHO.
SET endTime=%time%
CALL:showTime
:end