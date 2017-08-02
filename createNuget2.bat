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
SET nugetOrtcXamarinName=Ortc.Xamarin
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
SET iOSOrtcLibSourcePath=ortc\apple\libs\libORtc.dylib
SET OrtcWebRtcOutputPath=webrtc\xplatform\webrtc\WEBRTC_BUILD\ortc\Release
SET OrtcWebRtcSolutionPath=webrtc\xplatform\webrtc\webrtcForOrtc.vs2015.sln
SET OrtcWebRtcWin32SolutionPath=webrtc\xplatform\webrtc\webrtcForOrtc.Win32.vs2015.sln
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
SET nugetOrtcXamarinTemplateProjectPath=%nugetOrtcBasePath%\templates\Ortc.Xamarin.Nuget.sln
SET nugetOrtcCoreXamarinTemplateProjectPath=%nugetOrtcBasePath%\templates\Ortc.Core.Xamarin.Nuget.sln
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
SET supportedInputArguments=;target;version;key;prerelease;destination;publish;publishDestination;help;logLevel;pack;packDestination;xamarin;
SET target=""
SET version=1.0.0.0
SET key=
SET prerelease=
SET destination=
SET publish=0
SET publishDestination=%CD%\..\Publish
SET help=0
SET logLevel=2
SET pack=0
SET packDestination=..
SET xamarin=1

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
   IF !validArgument!==0 CALL:error "Invalid input argument !nome!. For the list of available arguments and usage examples, please run script with -help option."
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

IF %xamarin% NEQ 1 (
	CALL:generateNugetPackages
) ELSE (
	CALL:generateXamarinNugetPackages
)

IF %publish% EQU 1 (
	CALL:publishNuget
	CALL:publishSamples
)

IF %pack% EQU 1 (
	CALL:makeZipPackage
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

:generateXamarinNugetPackages
CALL:print %warning% "Generating Xamarin nuget packages ..."
 
CALL:determineVisualStudioPath

IF %generate_Ortc_Nuget% EQU 1 (
	CALL:print %warning% "Creating Ortc Xamarin nuget package ..."
	
	CALL:prepareTemplates ortc.xamarin
	
	SET SolutionPathCoreOrtc=!nugetOrtcTemplateProjectDestinationPath!Ortc.Core.Xamarin.Nuget.sln
	SET SolutionPathOrtc=!nugetOrtcTemplateProjectDestinationPath!Ortc.Xamarin.Nuget.sln
	SET WebRtcSolutionPath=%OrtcWebRtcWin32SolutionPath%
	SET nugetName=%nugetOrtcName%
	
	::this will build Org.Ortc.Xamarin.iOS as well
	CALL:build !SolutionPathCoreOrtc! wrappers\Org_Ortc_Xamarin win32
	CALL bin\prepare.bat
	CALL:build !SolutionPathCoreOrtc! wrappers\Org_Ortc_Xamarin win32_x64
	
	CALL:print %trace% "Restoring nuget packages for %~1"
	bin\nuget.exe restore !SolutionPathOrtc!
	IF ERRORLEVEL 1 CALL:error 1 "Failed restoring nuget packages for %~1"

	CALL:setCompilerOption x64

	CALL %msVS_Path%\VC\vcvarsall.bat %currentBuildCompilerOption%
	IF !ERRORLEVEL! EQU 1 CALL:error 1 "Could not setup %~2 compiler"

	IF %logLevel% GEQ %trace% (
		MSBuild !SolutionPathOrtc! /property:Configuration=Release /property:Platform="Any CPU" /nodeReuse:False
	) ELSE (
		MSBuild !SolutionPathOrtc! /property:Configuration=Release /property:Platform="Any CPU" /nodeReuse:False >NUL
	)
	IF ERRORLEVEL 1 CALL:error 1 "Building !SolutionPathOrtc! project for %"Any CPU" Release has failed"

	CALL:preparePackage Ortc.Xamarin
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

SET realplatform=%~3
IF '%~3'=='win32_x64' SET realplatform=x64

IF %logLevel% GEQ %trace% (
	MSBuild %~1 /property:Configuration=%CONFIGURATION% /property:Platform=!realplatform! /nodeReuse:False
) ELSE (
	MSBuild %~1 /property:Configuration=%CONFIGURATION% /property:Platform=!realplatform! /nodeReuse:False >NUL
)

IF ERRORLEVEL 1 CALL:error 1 "Building %~2 project for %PLATFORM% %CONFIGURATION% has failed"
GOTO:EOF

:prepareTemplates

IF /I "%~1"=="webrtc" (
	SET nugetTemplateProjectPath=%nugetWebRtcTemplateProjectPath%
	SET nugetTemplateProjectDestinationPath=%nugetWebRtcTemplateProjectDestinationPath%
) ELSE (
	IF /I "%~1"=="ortc" (
		SET nugetTemplateProjectPath=%nugetOrtcTemplateProjectPath%
		SET nugetTemplateProjectDestinationPath=%nugetOrtcTemplateProjectDestinationPath%
	) ELSE (
		SET nugetTemplateProjectPath=%nugetOrtcXamarinTemplateProjectPath%
		SET nugetTemplateProjectDestinationPath=%nugetOrtcTemplateProjectDestinationPath%
		CALL:copyFiles !nugetOrtcCoreXamarinTemplateProjectPath! !nugetTemplateProjectDestinationPath!
	)
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
SET xamarinNuget=0

IF /I "%~1"=="webrtc" (
	SET projectName=%projectNameWebRtc%
	SET nugetBasePath=%nugetWebRtcBasePath%
	SET nugetName=%nugetWebRtcName%
	SET projectNameForNuget=%projectNameWebRtc%
	SET libSourceBasePath=webrtc\windows\solutions\Build\Output
) ELSE (
	IF /I "%~1"=="ortc" (
		SET projectName=%projectNameOrtc%
		SET nugetBasePath=%nugetOrtcBasePath%
		SET nugetName=%nugetOrtcName%
		SET projectNameForNuget=%projectNameOrtc%
		SET libSourceBasePath=ortc\windows\solutions\Build\Output
	) ELSE (
		SET xamarinNuget=1
		SET projectName=%nugetOrtcXamarinName%
		SET nugetBasePath=%nugetOrtcBasePath%
		SET nugetName=%nugetOrtcXamarinName%
		SET projectNameForNuget=%projectNameOrtc%
		SET libSourceBasePath=ortc\windows\solutions\Build\Output
	)	
)

SET nugetTargetPath=%nugetBasePath%\%nugetName%.targets
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
SET nugetLibNetStandardPath=%nugetLibPath%\netstandard1.1
SET nugetLibXamariniOSPath=%nugetLibPath%\xamarinios
SET nugetLibUAPPath=%nugetLibPath%\uap10.0

SET nugetRuntimesPath=%nugetPath%\%nugetName%\runtimes
SET nugetRuntimesx86Path=%nugetRuntimesPath%\win10-x86\native
SET nugetRuntimesx64Path=%nugetRuntimesPath%\win10-x64\native
SET nugetRuntimesARMPath=%nugetRuntimesPath%\win10-arm\native
SET nugetRuntimesiOSPath=%nugetRuntimesPath%\iOS\native

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
CALL:print %debug% "nugetLibNetStandardPath: !nugetLibNetStandardPath!"
CALL:print %debug% "nugetLibUAPPath: !nugetLibUAPPath!"

CALL:print %debug% "nugetRuntimesPath: !nugetRuntimesPath!"
CALL:print %debug% "nugetRuntimesx86Path: !nugetRuntimesx86Path!"
CALL:print %debug% "nugetRuntimesx64Path: !nugetRuntimesx64Path!"
CALL:print %debug% "nugetRuntimesARMPath: !nugetRuntimesARMPath!"

IF !xamarinNuget! NEQ  1 (
	SET sourcex86Path=%libSourceBasePath%\x86\Release\%projectName%
	SET sourcex86DllPath=%sourcex86Path%\%projectNameForNuget%.dll
	SET sourcex86WinmdPath=%sourcex86Path%\%projectNameForNuget%.winmd
	SET sourcex86PdbPath=%sourcex86Path%\%projectNameForNuget%.pdb
	SET sourcex86PriPath=%sourcex86Path%\%projectNameForNuget%.pri


	SET sourcex86XmlPath=%sourcex86Path%\%projectNameForNuget%.xml

	SET sourcex64Path=%libSourceBasePath%\x64\Release\%projectName%
	SET sourcex64DllPath=%sourcex64Path%\%projectNameForNuget%.dll
	SET sourcex64WinmdPath=%sourcex64Path%\%projectNameForNuget%.winmd
	SET sourcex64PdbPath=%sourcex64Path%\%projectNameForNuget%.pdb
	SET sourcex64PriPath=%sourcex64Path%\%projectNameForNuget%.pri

	SET sourcexARMPath=%libSourceBasePath%\ARM\Release\%projectName%
	SET sourcexARMDllPath=%sourcexARMPath%\%projectNameForNuget%.dll
	SET sourcexARMWinmdPath=%sourcexARMPath%\%projectNameForNuget%.winmd
	SET sourcexARMPdbPath=%sourcexARMPath%\%projectNameForNuget%.pdb
	SET sourcexARMPriPath=%sourcexARMPath%\%projectNameForNuget%.pri

	SET nugetSpec=%nugetPath%\%nugetName%\%projectNameForNuget%.nuspec

	CALL:print %debug% "sourcex86Path: !sourcex86Path!"
	CALL:print %debug% "sourcex86DllPath: !sourcex86DllPath!"
	CALL:print %debug% "sourcex86PriPath: !sourcex86PriPath!"
	CALL:print %debug% "sourcex86WinmdPath: !sourcex86WinmdPath!"
	CALL:print %debug% "sourcex86PdbPath: !sourcex86PdbPath!"

	CALL:print %debug% "sourcex64Path: !sourcex64Path!"
	CALL:print %debug% "sourcex64DllPath: !sourcex64DllPath!"
	CALL:print %debug% "sourcex64PriPath: !sourcex64PriPath!"
	CALL:print %debug% "sourcex64WinmdPath: !sourcex64WinmdPath!"
	CALL:print %debug% "sourcex64PdbPath: !sourcex64PdbPath!"

	CALL:print %debug% "sourcexARMPath: !sourcexARMPath!"
	CALL:print %debug% "sourcexARMDllPath: !sourcexARMDllPath!"
	CALL:print %debug% "sourcexARMPriPath: !sourcexARMPriPath!"
	CALL:print %debug% "sourcexARMWinmdPath: !sourcexARMWinmdPath!"
	CALL:print %debug% "sourcexARMPdbPath: !sourcexARMPdbPath!"
) ELSE (
	SET sourceLibOrtcx86Path=%libSourceBasePath%\x86\Release\ortclib-c
	SET sourceLibOrtcx86DllPath=!sourceLibOrtcx86Path!\libOrtc.dll
	SET sourceLibOrtcx86PdbPath=!sourceLibOrtcx86Path!\libOrtc.pdb
	SET sourceLibOrtcx86PriPath=!sourceLibOrtcx86Path!\libOrtc.pri
	
	SET sourceLibOrtcx64Path=%libSourceBasePath%\x64\Release\ortclib-c
	SET sourceLibOrtcx64DllPath=!sourceLibOrtcx64Path!\libOrtc.dll
	SET sourceLibOrtcx64PdbPath=!sourceLibOrtcx64Path!\libOrtc.pdb
	SET sourceLibOrtcx64PriPath=!sourceLibOrtcx64Path!\libOrtc.pri

	SET sourceOrgOrtcXamarinPath=%libSourceBasePath%%\AnyCPU\Release\Org.Ortc.Xamarin
	SET sourceOrgOrtcXamarinDllPath=!sourceOrgOrtcXamarinPath!\Org.Ortc.dll
	SET sourceOrgOrtcXamarinPdbPath=!sourceOrgOrtcXamarinPath!\Org.Ortc.pdb
	SET sourceOrgOrtcXamarinXmlPath=!sourceOrgOrtcXamarinPath!\Org.Ortc.xml
	
	SET sourceOrgOrtcXamariniOSPath=%libSourceBasePath%%\AnyCPU\Release\Org.Ortc.Xamarin.iOS
	SET sourceOrgOrtcXamariniOSDllPath=!sourceOrgOrtcXamariniOSPath!\Org.Ortc.dll
	SET sourceOrgOrtcXamariniOSPdbPath=!sourceOrgOrtcXamariniOSPath!\Org.Ortc.pdb
	SET sourceOrgOrtcXamariniOSXmlPath=!sourceOrgOrtcXamariniOSPath!\Org.Ortc.xml
	
	SET sourceWebRtcx64Path=%OrtcWebRtcOutputPath%\win32_x64
	SET sourceWebRtcBoringSSLx64Path=!sourceWebRtcx64Path!\boringssl.dll
	SET sourceWebRtcProtoBufLitex64Path=!sourceWebRtcx64Path!\protobuf_lite.dll
	
	SET sourceWebRtcx86Path=%OrtcWebRtcOutputPath%\win32
	SET sourceWebRtcBoringSSLx86Path=!sourceWebRtcx86Path!\boringssl.dll
	SET sourceWebRtcProtoBufLitex86Path=!sourceWebRtcx86Path!\protobuf_lite.dll
	
	SET nugetTargetPath=%nugetBasePath%\Org.Ortc.Xamarin.targets
	SET nugetSpecPath=%nugetBasePath%\Org.Ortc.Xamarin.nuspec
	SET nugetSpec=%nugetPath%\%nugetName%\Org.Ortc.nuspec
	
	CALL:print %debug% "sourceLibOrtcx86Path: !sourceLibOrtcx86Path!"
	CALL:print %debug% "sourceLibOrtcx86DllPath: !sourceLibOrtcx86DllPath!"
	CALL:print %debug% "sourceLibOrtcx86PriPath: !sourceLibOrtcx86PriPath!"
	CALL:print %debug% "sourceLibOrtcx86PdbPath: !sourceLibOrtcx86PdbPath!"

	CALL:print %debug% "sourceLibOrtcx64Path: !sourceLibOrtcx64Path!"
	CALL:print %debug% "sourceLibOrtcx64DllPath: !sourceLibOrtcx64DllPath!"
	CALL:print %debug% "sourceLibOrtcx86PriPath: !sourceLibOrtcx86PriPath!"
	CALL:print %debug% "sourceLibOrtcx64PdbPath: !sourceLibOrtcx64PdbPath!"
)

CALL:print %debug% "nugetSpec: !nugetSpec!"

IF EXIST %nugetPath%\%nugetName%\NUL RMDIR /s /q %nugetPath%\%nugetName%\

CALL:createFolder %nugetPath%\%nugetName%

IF !xamarinNuget! NEQ  1 (
	CALL::copyFiles %sourcex86WinmdPath% %nugetLibUAPPath%
	IF EXIST %sourcex86XmlPath% CALL::copyFiles %sourcex86XmlPath% %nugetLibUAPPath%
	
	CALL::copyFiles %sourcexARMDllPath% %nugetRuntimesARMPath%
	CALL::copyFiles %sourcexARMPriPath% %nugetRuntimesARMPath%

	CALL::copyFiles %sourcex64DllPath% %nugetRuntimesx64Path%
	CALL::copyFiles %sourcex64PriPath% %nugetRuntimesx64Path%

	CALL::copyFiles %sourcex86DllPath% %nugetRuntimesx86Path%
	CALL::copyFiles %sourcex86PriPath% %nugetRuntimesx86Path%
	
	CALL::copyFiles %nugetTargetPath% %nugetBuildNativePath%
	CALL:copyFiles %nugetSpecPath% %nugetPath%\%nugetName%
) ELSE (
	CALL::copyFiles %sourceOrgOrtcXamarinDllPath% %nugetLibNetStandardPath%
	IF EXIST !sourceOrgOrtcXamarinXmlPath! CALL::copyFiles %sourcex86XmlPath% %nugetLibNetStandardPath%
	
	CALL::copyFiles %sourceOrgOrtcXamariniOSDllPath% %nugetLibXamariniOSPath%
	IF EXIST !sourceOrgOrtcXamariniOSXmlPath! CALL::copyFiles %sourcex86XmlPath% %nugetLibXamariniOSPath%
	
	CALL::copyFiles !sourceLibOrtcx86DllPath! %nugetRuntimesx86Path%
::CALL::copyFiles !sourceLibOrtcx86PriPath! %nugetRuntimesx86Path%
	CALL::copyFiles !sourceWebRtcBoringSSLx86Path! %nugetRuntimesx86Path%
	CALL::copyFiles !sourceWebRtcProtoBufLitex86Path! %nugetRuntimesx86Path%

	CALL::copyFiles !sourceLibOrtcx64DllPath! %nugetRuntimesx64Path%
::CALL::copyFiles !sourceLibOrtcx86PriPath! %nugetRuntimesx64Path%
	CALL::copyFiles !sourceWebRtcBoringSSLx64Path! %nugetRuntimesx64Path%
	CALL::copyFiles !sourceWebRtcProtoBufLitex64Path! %nugetRuntimesx64Path%
	
	CALL::copyFiles %nugetTargetPath% %nugetBuildNativePath%
	CALL:copyFiles %nugetSpecPath% %nugetPath%\%nugetName%
	CALL:copyFiles !iOSOrtcLibSourcePath! !nugetRuntimesiOSPath!
	CALL:renameFile %nugetBuildNativePath%\Org.Ortc.Xamarin.targets Org.Ortc.targets
	CALL:renameFile %nugetPath%\%nugetName%\Org.Ortc.Xamarin.nuspec Org.Ortc.nuspec
	
)

CALL:setNugetVersion %nugetSpec%

CALL:makeNuget

GOTO:EOF

:publishSamples

IF %generate_Ortc_Nuget% EQU 1 (
	CALL:print %debug% "Publishing PeerCC.Ortc with nuget version !nugetVersion!..."
	CALL bin\publishSamples -sample peercc -sdk ortc -nugetVersion !nugetVersion! -logLevel %logLevel% -destination %publishDestination%
)

IF %generate_WebRtc_Nuget% EQU 1 (
	CALL:print %debug% "Publishing PeerCC.WebRtc with nuget version !nugetVersion!..."
	CALL bin\publishSamples -sample peercc -sdk webrtc -nugetVersion !nugetVersion! -logLevel %logLevel% -destination %publishDestination%
	
	CALL:print %debug% "Publishing ChatterBox with nuget version !nugetVersion!..."
	CALL bin\publishSamples -sample chatterbox -sdk webrtc -nugetVersion !nugetVersion! -logLevel %logLevel% -destination %publishDestination%
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
		CALL:createFolder %destination%
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
IF "%version%"=="1.0.0.0" (
	IF EXIST %nugetPackageVersion% (
		SET /p version=< %nugetPackageVersion%
		
		CALL:print %debug% "Current Nuget Version is !version!"
		
		FOR /f "tokens=1-4 delims=." %%a IN ("!version!") DO (
			SET /a build=%%d+1
			SET version=%%a.%%b.%%c.!build!
		)
	)
)

IF NOT "%prerelease%"=="" (
	SET nugetVersion=!version!-%prerelease%
) ELSE (
	SET nugetVersion=!version!
)

CALL:print %warning%  "New Nuget Version is !nugetVersion!"
GOTO:EOF

:makeZipPackage
CALL:print %warning%  "Archieving nuget package %nugetVersion%, pdb files and samples"

FOR /f "tokens=2-4 delims=/ " %%a IN ('date /t') DO (SET mydate=%%c-%%a-%%b)
FOR /f "tokens=1-2 delims=/:" %%a IN ("%TIME%") DO (SET mytime=%%a%%b) 

SET zipPackageOutputPath=%packDestination%\
SET outputFolderName=Package_%target%_nuget_%nugetVersion%_%mydate%_%mytime%
SET packageName=!zipPackageOutputPath!!outputFolderName!
SET packageNugetPath=!packageName!\Nuget

SET packagePdbsPath=!packageName!\Pdbs
SET packagePdbsSourceWrapperPath=!target!\windows\solutions\Build\Output\
SET packagePdbsSourcePath=webrtc\xplatform\webrtc\WEBRTC_BUILD\!target!\Release\

SET packageSamplesPath=!packageName!\Samples\
SET peerCCPublishingPath=..\Publish\%target%\PeerCC-Sample
SET ChatterBoxPublishingPath=..\Publish\%target%\ChatterBox-Sample

IF EXIST !packageName!\NUL RMDIR /s /q !packageName!
IF ERRORLEVEL 1 CALL:error 1 "Could not delete a directory !packageName!"

CALL:createFolder !packageName!

::Copy nuget
CALL:createFolder !packageNugetPath!
FOR /R %nugetOutputPath% %%f in (*!nugetVersion!*.nupkg) DO COPY %%f !packageNugetPath! > NUL

::Copy ARM pdb files
CALL:createFolder !packagePdbsPath!\ARM
FOR /R %packagePdbsSourcePath%\ARM\ %%f in (*.pdb) DO COPY %%f !packagePdbsPath!\ARM > NUL
FOR /R %packagePdbsSourceWrapperPath%\ARM\Release\ %%f in (*.pdb) DO COPY %%f !packagePdbsPath!\ARM > NUL

::Copy X64 pdb files
CALL:createFolder !packagePdbsPath!\X64
FOR /R %packagePdbsSourcePath%\X64\ %%f in (*.pdb) DO COPY %%f !packagePdbsPath!\X64 > NUL
FOR /R %packagePdbsSourceWrapperPath%\X64\Release\ %%f in (*.pdb) DO COPY %%f !packagePdbsPath!\X64 > NUL

::Copy X86 pdb files
CALL:createFolder !packagePdbsPath!\X86
FOR /R %packagePdbsSourcePath%\X86\ %%f in (*.pdb) DO COPY %%f !packagePdbsPath!\X86 > NUL
FOR /R %packagePdbsSourceWrapperPath%\X86\Release\ %%f in (*.pdb) DO COPY %%f !packagePdbsPath!\X86 > NUL

::Copy PeerCC sample
IF EXIST %peerCCPublishingPath%\NUL (
	CALL:createFolder !packageSamplesPath!PeerCC-Sample
	XCopy  /S /I /Y %peerCCPublishingPath% !packageSamplesPath!PeerCC-Sample > NUL
	IF ERRORLEVEL 1 CALL:error 1 "Failed copying from %peerCCPublishingPath% to !packageSamplesPath!PeerCC-Sample"
)

::Copy ChatterBox sample
IF EXIST %ChatterBoxPublishingPath%\NUL (
	CALL:createFolder !packageSamplesPath!ChatterBox-Sample
	XCopy  /S /I /Y %ChatterBoxPublishingPath% !packageSamplesPath!ChatterBox-Sample > NUL
	IF ERRORLEVEL 1 CALL:error 1 "Failed copying from %ChatterBoxPublishingPath% to !packageSamplesPath!ChatterBox-Sample"
)

PUSHD !zipPackageOutputPath!
CALL:print %debug%  "Archieving %CD%\!outputFolderName! to %CD%\!outputFolderName!.zip"
CALL:zipFolder %CD%\!outputFolderName!  %CD%\!outputFolderName!.zip
POPD
GOTO:EOF

:zipFolder
echo Set objArgs = WScript.Arguments > _zipIt.vbs
echo InputFolder = objArgs(0) >> _zipIt.vbs
echo ZipFile = objArgs(1) >> _zipIt.vbs
echo CreateObject("Scripting.FileSystemObject").CreateTextFile(ZipFile, True).Write "PK" ^& Chr(5) ^& Chr(6) ^& String(18, vbNullChar) >> _zipIt.vbs
echo Set objShell = CreateObject("Shell.Application") >> _zipIt.vbs
echo Set source = objShell.NameSpace(InputFolder).Items >> _zipIt.vbs
echo objShell.NameSpace(ZipFile).CopyHere(source) >> _zipIt.vbs
@ECHO *******************************************
@ECHO Zipping, please wait..
echo wScript.Sleep 30000 >> _zipIt.vbs
CScript  _zipIt.vbs  %1  %2
del _zipIt.vbs
GOTO:EOF

:simpleCopyFiles
IF EXIST %1 (
	CALL:print %debug% "Copying %1 to %2"
	COPY %1 %2
	IF ERRORLEVEL 1 CALL:error 1 "Could not copy a %1"
) ELSE (
	CALL:error 1 "Could not copy a %1"
)
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

:renameFile
IF EXIST %1 (
	CALL:print %debug% "Renaming %1 to %2"
	REN  %1 %2
	IF ERRORLEVEL 1 CALL:error 1 "Could not rename a %1"
) ELSE (
	CALL:error 1 "Could not rename a %1"
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
ECHO 	[93m-destination[0m	Used for specifying nuget server where package will be published. Default destination is nuget.org
ECHO.
ECHO 	[93m-key[0m		Api key that is used for publishing nuget package on nuget.org. This is used in combination with 
ECHO		publish flag -publish. This will store your API key so that you never need to do this step again on this machine.
ECHO.
ECHO 	[93m-help[0m 		Show script usage
ECHO.
ECHO 	[93m-logLevel[0m	Log level (error=0, info =1, warning=2, debug=3, trace=4)
ECHO.
ECHO  	[93m-prelease[0m 		Version sufix if it is prerelease version (Alpha, Beta ...).
ECHO.
ECHO 	[93m-publish[0m	Publish created nuget package. By default it will be uploaded on nuget.org server. If it is 
ECHO		desired to publish it locally or on some another server, it sholud be used option -destination to specify 
ECHO		destination server
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
ECHO   [93mCreating WebRtc prerelase nuget package with version number 1.0.0.1-Beta[0m
ECHO    bin\createNuget.bat -beta -target WebRtc -version 1.0.0.1
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
IF EXIST !nugetOrtcTemplateProjectDestinationPath!Ortc.Core.Xamarin.Nuget.sln DEL /s /q /f !nugetOrtcTemplateProjectDestinationPath!Ortc.Core.Xamarin.Nuget.sln > NUL
IF EXIST !nugetOrtcTemplateProjectDestinationPath!Ortc.Xamarin.Nuget.sln DEL /s /q /f !nugetOrtcTemplateProjectDestinationPath!Ortc.Xamarin.Nuget.sln > NUL
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