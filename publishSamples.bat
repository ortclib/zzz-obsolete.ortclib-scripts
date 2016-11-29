@ECHO off

SETLOCAL EnableDelayedExpansion

set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
SET supportedInputArguments=;sample;nuget;version;nugetVersion;destination;publish;help;logLevel;comment;
SET sample=""
SET nuget=""
SET version=1.0.0.0
SET nugetVersion=""
SET destination=..\Publish
SET publish=0
SET help=0
SET logLevel=2
SET comment="Update"

SET marked=0
SET target=""
SET nonSdk=Ortc
SET peerCCSourcePath=common\windows\samples\PeerCC\Client
SET chatterBoxSourcePath=common\windows\samples\ChatterBox

SET peerCCOrtcURL="https://github.com/ortclib/PeerCC-Sample.git"
SET peerCCWebRtcURL="https://github.com/webrtc-uwp/PeerCC-Sample.git"
SET chatterBoxWebRtcURL="https://github.com/webrtc-uwp/ChatterBox-Sample.git"
SET sampleURL=

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

:main

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

:publishPeerCC

SET projectTemplates=%sdk%\windows\templates\samples\PeerCC
SET packageManifest=Package.%sdk%.appxmanifest
SET peerCCPublishingPath=%destination%\%sdk%\%sample%-Sample

echo !peerCCPublishingPath!
IF EXIST !peerCCPublishingPath! RMDIR /s /q !peerCCPublishingPath!

CALL:createFolder %destination%\%sdk%
CALL:cloneRepo %destination%\%sdk% !sampleURL!

CALL:cleanRepo !peerCCPublishingPath!

Xcopy  /S /I /Y %peerCCSourcePath% !peerCCPublishingPath!
IF ERRORLEVEL 1 CALL:error 1 "Failed copying %peerCCSourcePath% to !peerCCPublishingPath!"

IF EXIST !peerCCPublishingPath!\%nonSdk%-Required RMDIR /s /q !peerCCPublishingPath!\%nonSdk%-Required
IF EXIST !peerCCPublishingPath!\Package.%nonSdk%.appxmanifest DEL /s /q /f !peerCCPublishingPath!\Package.%nonSdk%.appxmanifest > NUL
IF EXIST !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj > NUL
IF EXIST !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj.user DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj.user > NUL
IF EXIST !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%_TemporaryKey.pfx DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%_TemporaryKey.pfx > NUL

call:copyFiles !projectTemplates!\project.json !peerCCPublishingPath!
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 !peerCCPublishingPath!\project.json "Nuget.Version" "%nugetVersion%" !peerCCPublishingPath!\project.json
IF ERRORLEVEL 1 CALL:error 1 "Failed setting nuget version for PeerCC"

call:copyFiles !projectTemplates!\!packageManifest! !peerCCPublishingPath!
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 !peerCCPublishingPath!\!packageManifest! "App.Version" "%version%" !peerCCPublishingPath!\!packageManifest!
IF ERRORLEVEL 1 CALL:error 1 "Failed setting app version for PeerCC"

call:copyFiles !projectTemplates!\PeerConnectionClient.%sdk%.csproj !peerCCPublishingPath!
 
call:copyFiles !projectTemplates!\AssemblyInfo.cs !peerCCPublishingPath!\Properties

IF %publish% EQU 1 CALL:publishRepo !peerCCPublishingPath!
GOTO:EOF

:publishChatterBox
SET projectTemplates=%sdk%\windows\templates\samples\ChatterBox
SET samplePublishingPath=%destination%\%sdk%\%sample%-Sample

IF EXIST !samplePublishingPath! RMDIR /s /q !samplePublishingPath!

CALL:createFolder %destination%\%sdk%
CALL:cloneRepo %destination%\%sdk% !sampleURL!

CALL:cleanRepo !samplePublishingPath!

Xcopy  /S /I /Y %chatterBoxSourcePath% !samplePublishingPath!
IF ERRORLEVEL 1 CALL:error 1 "Failed copying %chatterBoxSourcePath% to !samplePublishingPath!"

call:copyFiles !projectTemplates!\ChatterBox.Background\project.json !samplePublishingPath!\ChatterBox.Background
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 !samplePublishingPath!\ChatterBox.Background\project.json "Nuget.Version" "%nugetVersion%" !samplePublishingPath!\ChatterBox.Background\project.json
IF ERRORLEVEL 1 CALL:error 1 "Failed setting nuget version for ChatterBox"

call:copyFiles !projectTemplates!\ChatterBox.Background\ChatterBox.Background.csproj !samplePublishingPath!\ChatterBox.Background
pause
IF %publish% EQU 1 CALL:publishRepo !samplePublishingPath!
GOTO:EOF

:cloneRepo
ECHO %~1
ECHO %~2

PUSHD %1
git clone %2
IF ERRORLEVEL 1 CALL:error 1 "Failed cloning from %2"
POPD
GOTO:EOF

:publishRepo
SET comment="References nuget version !nugetVersion!"
echo push repo %1 with commit message !comment!
pause
PUSHD %1
git add .
git commit -am !comment!
git push
IF ERRORLEVEL 1 CALL:error 1 "Pushing on github has failed"
POPD

GOTO:EOF

:cleanRepo
echo clean
IF NOT EXIST %~1\ GOTO:EOF
echo %~1
for /d %%i in (%~1\*.*) do (
	set marked=0
  CALL:isMarked %%~nxi
	
	IF !marked! equ 0 (
		echo deleting %%~i
		rd /s /q %%~i
	)
)
echo %~1
for %%i in (%~1\*.*) do (
	set marked=0
  CALL:isMarked %%~nxi
	IF !marked! equ 0 (
		echo deleting %%~i
		DEL /s /q /f %%~i
	)
)
GOTO:EOF

:isMarked
if /i "%~1"=="Server" set marked=1
if /i "%~1"==".git" set marked=1
if /i "%~1"=="README.md" set marked=1
GOTO:EOF


:createFolder
IF NOT EXIST %1 (
	echo "Creating folder %1"
	MKDIR %1
	IF ERRORLEVEL 1 CALL:error 1 "Could not make a directory %1"
)
GOTO:EOF

:copyFiles
if EXIST %1 (
	CALL:createFolder %2
	echo Copying %1 to %2
	copy %1 %2
	IF ERRORLEVEL 1 CALL:error 1 "Could not copy a %1"
) else (
	CALL:error 1 "Could not copy a %1"
)
GOTO:EOF

REM Print the error message and terminate further execution if error is critical.Firt argument is critical error flag (1 for critical). Second is error message
:error
SET criticalError=%~1
SET errorMessage=%~2

IF %criticalError%==0 (
	ECHO.
	echo "WARNING: %errorMessage%"
	ECHO.
) ELSE (
	ECHO.
	echo "CRITICAL ERROR: %errorMessage%"
	ECHO.
	ECHO.
	echo "FAILURE: Publishing samples has failed!"
	ECHO.
	POPD
	::terminate batch execution
	CALL bin\batchTerminator.bat
)
GOTO:EOF

:done
echo Sample published successfully