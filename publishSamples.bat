:: Name:      publishSamples.bat
:: Purpose:   Publishes ChatterBox and PeerCC sample applications
:: Author:    Sergej Jovanovic
:: Email:     sergej@gnedo.com
:: Twitter:   @JovanovicSergej
:: Revision:  November 2016 - initial version

@ECHO off

SETLOCAL EnableDelayedExpansion

set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
SET supportedInputArguments=;sample;sdk;version;nugetVersion;destination;publish;help;logLevel;comment;
SET sample=""
SET sdk=""
SET version=1.0.0.0
SET nugetVersion=""
SET destination=%CD%\..\Publish
SET publish=0
SET help=0
SET logLevel=2
SET comment="Update"

SET marked=0
SET target=""
SET nonSdk=Ortc
SET peerCCSourcePath=common\windows\samples\PeerCC\Client
SET chatterBoxSourcePath=%CD%\common\windows\samples\ChatterBox

SET peerCCOrtcURL="https://github.com/ortclib/PeerCC-Sample.git"
SET peerCCWebRtcURL="https://github.com/webrtc-uwp/PeerCC-Sample.git"
SET chatterBoxWebRtcURL="https://github.com/webrtc-uwp/ChatterBox-Sample.git"
SET sampleURL=

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

:main
CALL:precheck
CALL:showHelp

ECHO.
CALL:print %info% "Started sample publishing ..."
ECHO.

IF /I "%sdk%" == "ortc" (
	SET sdk=Ortc
	SET nonSdk=WebRtc
	SET sampleURL=%peerCCOrtcURL%
)

IF /I "%sdk%" == "webrtc" (
	SET sdk=WebRtc
	SET nonSdk=Ortc
	SET sampleURL=%peerCCWebRtcURL%
)

IF /I "%sample%" == "peercc" (
	SET sample=PeerCC
	CALL:publishPeerCC
)

IF /I "%sample%" == "chatterbox" (
	SET sampleURL=%chatterBoxWebRtcURL%
	SET sample=ChatterBox
	CALL:publishChatterBox
)

GOTO:done

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

:publishPeerCC
CALL:print %warning% "Publishing PeerCC.!sdk! ..."

SET projectTemplates=%sdk%\windows\templates\samples\PeerCC
SET packageManifest=Package.%sdk%.appxmanifest
SET peerCCPublishingPath=%destination%\%sdk%\%sample%-Sample

IF EXIST !peerCCPublishingPath! (
	CALL:print %debug% "Deleting !peerCCPublishingPath! ..."
	RMDIR /s /q !peerCCPublishingPath! > NUL
)

CALL:createFolder %destination%\%sdk%
CALL:cloneRepo %destination%\%sdk% !sampleURL!
CALL:cleanRepo !peerCCPublishingPath!

CALL:print %debug% "Copying %peerCCSourcePath% to !peerCCPublishingPath! ..."
IF %logLevel% GEQ %trace% (
	Xcopy  /S /I /Y %peerCCSourcePath% !peerCCPublishingPath!
) ELSE (
	Xcopy  /S /I /Y %peerCCSourcePath% !peerCCPublishingPath! > NUL
)
IF ERRORLEVEL 1 CALL:error 1 "Failed copying %peerCCSourcePath% to !peerCCPublishingPath!"

CALL:print %debug% "Cleaning  %nonSdk% related files ..."
IF EXIST !peerCCPublishingPath!\%nonSdk%-Required RMDIR /s /q !peerCCPublishingPath!\%nonSdk%-Required > NUL
IF EXIST !peerCCPublishingPath!\Package.%nonSdk%.appxmanifest DEL /s /q /f !peerCCPublishingPath!\Package.%nonSdk%.appxmanifest > NUL
IF EXIST !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj > NUL
IF EXIST !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj.user DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj.user > NUL
IF EXIST !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%_TemporaryKey.pfx DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%_TemporaryKey.pfx > NUL

CALL:copyFiles !projectTemplates!\project.json !peerCCPublishingPath!
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 !peerCCPublishingPath!\project.json "Nuget.Version" "%nugetVersion%" !peerCCPublishingPath!\project.json
IF ERRORLEVEL 1 CALL:error 1 "Failed setting nuget version for PeerCC"

CALL:copyFiles !projectTemplates!\!packageManifest! !peerCCPublishingPath!
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 !peerCCPublishingPath!\!packageManifest! "App.Version" "%version%" !peerCCPublishingPath!\!packageManifest!
IF ERRORLEVEL 1 CALL:error 1 "Failed setting app version for PeerCC"

CALL:copyFiles !projectTemplates!\PeerConnectionClient.%sdk%.csproj !peerCCPublishingPath!
 
CALL:copyFiles !projectTemplates!\AssemblyInfo.cs !peerCCPublishingPath!\Properties

IF %publish% EQU 1 CALL:publishRepo !peerCCPublishingPath!
GOTO:EOF

:publishChatterBox
CALL:print %warning% "Publishing ChatterBox for !sdk! ..."

SET projectTemplates=%sdk%\windows\templates\samples\ChatterBox
SET samplePublishingPath=%destination%\%sdk%\%sample%-Sample

IF EXIST !samplePublishingPath! (
	CALL:print %debug% "Deleting !samplePublishingPath! ..."
	RMDIR /s /q !samplePublishingPath! > NUL
)

CALL:createFolder %destination%\%sdk%
CALL:cloneRepo %destination%\%sdk% !sampleURL!
CALL:cleanRepo !samplePublishingPath!

PUSHD %chatterBoxSourcePath%
CALL:print %debug% "Copying %chatterBoxSourcePath% to !samplePublishingPath! ..."

for /d %%i in (!CD!\*.*) do (

	if /i not "%%~ni"==".git" (
		CALL:print %trace% "Copying %%~nxi to !samplePublishingPath!\%%~nxi ..."
		CALL:copyFolder %%~nxi !samplePublishingPath!\%%~nxi > NUL
	)
)

for %%i in (.\*.*) do (
	if /i not "%%~nxi"==".git" (
		CALL:print %trace% "Copying %%~nxi to !samplePublishingPath! ..."
		CALL:copyFiles %%~nxi !samplePublishingPath! > NUL
	)
)

popd
IF ERRORLEVEL 1 CALL:error 1 "Failed copying %chatterBoxSourcePath% to !samplePublishingPath!"

CALL:copyFiles !projectTemplates!\ChatterBox.Background\project.json !samplePublishingPath!\ChatterBox.Background
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 !samplePublishingPath!\ChatterBox.Background\project.json "Nuget.Version" "%nugetVersion%" !samplePublishingPath!\ChatterBox.Background\project.json
IF ERRORLEVEL 1 CALL:error 1 "Failed setting nuget version for ChatterBox"

CALL:copyFiles !projectTemplates!\ChatterBox.Background\ChatterBox.Background.csproj !samplePublishingPath!\ChatterBox.Background

IF %publish% EQU 1 CALL:publishRepo !samplePublishingPath!
GOTO:EOF

:cloneRepo
CALL:print %warning% "Cloning %~2 to %~1 ..."

PUSHD %1
IF %logLevel% GEQ %trace% (
	git clone %2
) ELSE (
	git clone %2 > NUL
)
IF ERRORLEVEL 1 CALL:error 1 "Failed cloning from %2"
POPD
GOTO:EOF

:publishRepo
SET comment="References nuget version !nugetVersion!"
CALL:print %warning% "Commiting %1 with commit message !comment!..."

PUSHD %1
git add .
git commit -am !comment!
git push
IF ERRORLEVEL 1 CALL:error 1 "Pushing on github has failed"
POPD

GOTO:EOF

:cleanRepo

IF NOT EXIST %~1\ GOTO:EOF
CALL:print %debug% "Removing cloned files %~1"
for /d %%i in (%~1\*.*) do (
	set marked=0
  CALL:isMarked %%~nxi
	
	IF !marked! equ 0 (
		CALL:print %trace% "Deleting %%~i"
		rd /s /q %%~i
	)
)

for %%i in (%~1\*.*) do (
	set marked=0
  CALL:isMarked %%~nxi
	IF !marked! equ 0 (
		CALL:print %trace% "Deleting %%~i"
		DEL /s /q /f %%~i > NUL
	)
)
GOTO:EOF

:isMarked
if /i "%~1"=="Server" set marked=1
if /i "%~1"==".git" set marked=1
if /i "%~1"=="README.md" set marked=1
if /i "%~1"==".gitignore" set marked=1
GOTO:EOF


:createFolder
IF NOT EXIST %1 (
	CALL:print %debug% "Creating folder %1"
	MKDIR %1
	IF ERRORLEVEL 1 CALL:error 1 "Could not make a directory %1"
)
GOTO:EOF

:copyFiles
if EXIST %1 (
	CALL:createFolder %2
	CALL:print %debug% Copying %1 to %2
	copy %1 %2 > NUL
	IF ERRORLEVEL 1 CALL:error 1 "Could not copy a %1"
) else (
	CALL:error 1 "Could not copy a %1"
)
GOTO:EOF

:copyFolder
if EXIST %1 (
	CALL:createFolder %2
	CALL:print %debug% Copying %1 to %2
	Xcopy  /S /I /Y %1 %2
	IF ERRORLEVEL 1 CALL:error 1 "Could not copy a %1"
) else (
	CALL:error 1 "Could not copy a %1"
)
GOTO:EOF

:showHelp

IF %help% EQU 0 GOTO:EOF

ECHO.
ECHO    [92mAvailable parameters:[0m
ECHO.
ECHO  	[93m-destination[0m 		Local path which will be used for sample publishing. Path MUST NOT BE INSIDE sdk folder and its subfolders. Default path is ..\Publishing
ECHO.
ECHO 	[93m-help[0m 		Show script usage
ECHO.
ECHO 	[93m-logLevel[0m	Log level (error=0, info =1, warning=2, debug=3, trace=4)
ECHO.
ECHO 	[93m-publish[0m 	Flag wether sample should be automattically pushed on github 
ECHO.
ECHO 	[93m-nugetVersion[0m	Nuget version number that will be referenced by sample app
ECHO.
ECHO 	[93m-sample[0m		Name of a sample app that will be published. ChatterBox or PeerCC
ECHO.
ECHO 	[93m-sdk[0m		Sdk that will reference sample app. WebRtc or Ortc
ECHO.
ECHO 	[93m-version[0m	Sample app version number
ECHO.
ECHO    [91m Published sample appe will be stored in [destination path]\[sdk]\[sample repo folder]\ i.e. Default location for ChatterBox app will be ..\Publish\WebRtc\ChatterBox-Sample.[0m
ECHO.
ECHO    [92mExamples:[0m
ECHO.
ECHO   [93mPublishing PeerCC.WebRtc that references WebRtc 1.2.0 nuget package directly pushing to github.[0m
ECHO    bin\publishSamples.bat -sample peercc -sdk webrtc -nugetVersion 1.2.0 -publish 
ECHO.
ECHO   [93mublishing ChatterBox that references WebRtc 1.2.0 nuget package without pushing to github.[0m
ECHO    bin\publishSamples.bat -sample chatterbox -sdk webrtc -nugetVersion 1.2.0
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
	CALL:print %error% "FAILURE: Publishing sample has failed!"
	ECHO.
	POPD
	::terminate batch execution
	CALL bin\batchTerminator.bat
)
GOTO:EOF

:done
ECHO.
CALL:print %info% "Success:  Sample published successfully"
ECHO.
 