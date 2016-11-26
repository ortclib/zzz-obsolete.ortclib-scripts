@ECHO off

SETLOCAL EnableDelayedExpansion

set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
SET supportedInputArguments=;sample;nuget;version;nugetVersion;destination;publish;help;logLevel;
SET sample=""
SET nuget=""
SET version=""
SET nugetVersion=""
SET destination=Publish
SET publish=0
SET help=0
SET logLevel=2

SET target=""
SET nonSdk=Ortc
SET peerCCSourcePath=common\windows\samples\PeerCC\Client

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
)
IF /I "%sdk%" == "webrtc" SET sdk=WebRtc

IF /I "%sample%" == "peercc" (
	SET sample=PeerCC
	CALL:publishPeerCC
)
IF /I "%sample%" == "chatterbox" CALL:publishChatterBox


GOTO:done

:publishPeerCC

SET projectTemplates=%sdk%\windows\templates\samples\PeerCC
SET packageManifest=Package.%sdk%.appxmanifest
SET peerCCPublishingPath=%destination%\%sdk%\%sample%

echo !peerCCPublishingPath!
CALL:createFolder !peerCCPublishingPath!
Xcopy  /S /I /Y %peerCCSourcePath% !peerCCPublishingPath!

DEL /s /q /f !peerCCPublishingPath!\Package.%nonSdk%.appxmanifest > NUL
DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj > NUL
DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj.user > NUL
DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%_TemporaryKey.pfx > NUL

call:copyFiles !projectTemplates!\project.json !peerCCPublishingPath!
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 !peerCCPublishingPath!\project.json "Nuget.Version" "%nugetVersion%" !peerCCPublishingPath!\project.json

echo !peerCCPublishingPath\!packageManifest!

call:copyFiles !projectTemplates!\!packageManifest! !peerCCPublishingPath!
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 !peerCCPublishingPath!\!packageManifest! "App.Version" "%nugetVersion%" !peerCCPublishingPath!\!packageManifest!

GOTO:EOF

:publishChatterBox
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
	if ERRORLEVEL 1 CALL:failure %errorlevel% "Could not copy a %1"
) else (
	CALL:failure 1 "Could not copy a %1"
)
GOTO:EOF
:done