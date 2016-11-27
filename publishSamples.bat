@ECHO off

SETLOCAL EnableDelayedExpansion

set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
SET supportedInputArguments=;sample;nuget;version;nugetVersion;destination;publish;help;logLevel;
SET sample=""
SET nuget=""
SET version=1.0.0.0
SET nugetVersion=""
SET destination=Publish
SET publish=0
SET help=0
SET logLevel=2

SET target=""
SET nonSdk=Ortc
SET peerCCSourcePath=common\windows\samples\PeerCC\Client
SET chatterBoxSourcePath=common\windows\samples\ChatterBox

SET peerCCOrtcURL="https://github.com/webrtc-uwp/PeerCC-Sample.git"
SET sampleURL=TEST

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
SET peerCCPublishingPath=%destination%\%sdk%\%sample%-Sample

echo !peerCCPublishingPath!
RMDIR /s /q !peerCCPublishingPath!
PAUSE
CALL:createFolder %destination%\%sdk%
CALL:cloneRepo %destination%\%sdk% !sampleURL!
PAUSE
Xcopy  /S /I /Y %peerCCSourcePath% !peerCCPublishingPath!

DEL /s /q /f !peerCCPublishingPath!\Package.%nonSdk%.appxmanifest > NUL
DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj > NUL
DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%.csproj.user > NUL
DEL /s /q /f !peerCCPublishingPath!\PeerConnectionClient.%nonSdk%_TemporaryKey.pfx > NUL

call:copyFiles !projectTemplates!\project.json !peerCCPublishingPath!
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 !peerCCPublishingPath!\project.json "Nuget.Version" "%nugetVersion%" !peerCCPublishingPath!\project.json

echo !peerCCPublishingPath\!packageManifest!

call:copyFiles !projectTemplates!\!packageManifest! !peerCCPublishingPath!
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 !peerCCPublishingPath!\!packageManifest! "App.Version" "%version%" !peerCCPublishingPath!\!packageManifest!

call:copyFiles !projectTemplates!\PeerConnectionClient.%sdk%.csproj !peerCCPublishingPath!
call:copyFiles !projectTemplates!\AssemblyInfo.cs !peerCCPublishingPath!\Properties

CALL:publishRepo !peerCCPublishingPath!
GOTO:EOF

:publishChatterBox
SET projectTemplates=%sdk%\windows\templates\samples\ChatterBox
SET samplePublishingPath=%destination%\%sdk%\%sample%

echo !samplePublishingPath!
CALL:createFolder !samplePublishingPath!
Xcopy  /S /I /Y %chatterBoxSourcePath% !samplePublishingPath!

call:copyFiles !projectTemplates!\ChatterBox.Background\project.json !samplePublishingPath!\ChatterBox.Background
%powershell_path% -ExecutionPolicy ByPass -File bin\TextReplaceInFile.ps1 !samplePublishingPath!\ChatterBox.Background\project.json "Nuget.Version" "%nugetVersion%" !samplePublishingPath!\ChatterBox.Background\project.json

call:copyFiles !projectTemplates!\ChatterBox.Background\ChatterBox.Background.csproj !samplePublishingPath!\ChatterBox.Background
GOTO:EOF

:cloneRepo
ECHO %~1
ECHO %~2
PAUSE
PUSHD %1
git clone %2
POPD
GOTO:EOF

:publishRepo
echo push repo %1
pause
PUSHD %1
git add .
git commit -am "References nuget version !nugetVersion!"
git push
POPD
pause
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