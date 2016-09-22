@ECHO off
ECHO.
ECHO Running prepare script ...
ECHO.

SETLOCAL enabledelayedexpansion

SET supportedInputArguments=;platform;help;
SET targetEnvironemnt=%1
SET prepare_ORTC_Environemnt=0
SET prepare_WebRTC_Environemnt=0
SET validInput=0
SET failure=0

::input arguments
SET platform=all
SET help=0

::predefined messages
SET errorMessageInvalidArgument="Invalid input parameters. If you want to prepare environment for both webrtc and ortc run this script without arguments, otherwise put just the name of desired framework."
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

::Determine targeted platforms
CALL:identifyTargetedPlatforms
echo hihihi

GOTO:EOF

REM Based on input arguments determine targeted platforms
:identifyTargetedPlatforms
SET messageText=
IF /I "%platform%"=="all" (
	SET prepare_ORTC_Environemnt=1
	SET prepare_WebRTC_Environemnt=1
	SET validInput=1
	SET messageText=Preparing webRTC and ORTC development environment ...
) ELSE (
	IF /I "%platform%"=="webrtc" (
		SET prepare_WebRTC_Environemnt=1
		SET validInput=1
	)
	IF /I "%platform%"=="ortc" (
		SET prepare_ORTC_Environemnt=1
		SET validInput=1
	)

	IF !validInput!==1 (
		SET messageText=Preparing %platform% development environment ...
	)
)

:: If input is not valid terminate script execution
IF !validInput!==1 (
	ECHO !messageText!
) ELSE (
	CALL:error 1 "Invalid input parameters. If you want to prepare environment for both webrtc and ortc run this script without arguments, otherwise put just the name of desired framework."
)
GOTO:EOF
:checkIfArgumentIsValid
if "!supportedInputArguments:;%~1;=!" neq "%supportedInputArguments%" (
	::it is valid
	set %2=1
) else (
	::it is not valid
	set %2=0
)
GOTO:EOF
:error
SET criticalError=%~1
SET errorMessage=%~2
echo.
if %criticalError%==0 (
	echo [103;94mWARNING: %errorMessage%[0m
) else (
	echo [101;93mCRITICAL ERROR: %errorMessage%[0m
	echo.
	echo.
	echo [101;93mPreparing environment has failed![0m
	echo.
	::terminate batch execution
	call bin\batchTerminator.bat
)

goto:eof

