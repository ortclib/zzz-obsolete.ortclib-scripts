:: Name:     newPrepare.bat
:: Purpose:  Prepare development environment for ORTC and WebRTC
:: Author:   Sergej Jovanovic
:: Email:	 sergej@gnedo.com
:: Revision: September 2016 - initial version

@ECHO off

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

::targeted platforms
SET prepare_ORTC_Environemnt=0
SET prepare_WebRTC_Environemnt=0

::log variables
SET globalLogLevel=2											

SET error=0														
SET info=1														
SET warning=2													
SET debug=3														
SET trace=4														

::input arguments
SET supportedInputArguments=;platform;help;						
SET platform=all
SET help=0

::predefined messages
SET errorMessageInvalidArgument="Invalid input parameter. For the list of available parameters and usage examples, please run script with -help option."
SET errorMessageInvalidPlatform="Invalid platform name. For the list of available platforms and usage examples, please run script with -help option."

ECHO.
CALL:print %info% "Running prepare script ..."
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

::Finish script execution
CALL:done

GOTO:EOF

REM Based on input arguments determine targeted platforms
:identifyTargetedPlatforms
SET validInput=0
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
	CALL:print %info% "!messageText!"
) ELSE (
	CALL:error 1 %errorMessageInvalidPlatform%
)
GOTO:EOF

:checkIfArgumentIsValid
IF "!supportedInputArguments:;%~1;=!" neq "%supportedInputArguments%" (
	::it is valid
	SET %2=1
) ELSE (
	::it is not valid
	SET %2=0
)
GOTO:EOF

:print
SET logType=%1
SET logMessage=%~2

if %globalLogLevel% GEQ  %logType% (
	if %logType%==0 ECHO [91m%logMessage%[0m
	if %logType%==1 ECHO [92m%logMessage%[0m
	if %logType%==2 ECHO [93m%logMessage%[0m
)

GOTO:EOF

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
	CALL:print %error% "FAILURE:Preparing environment has failed!"
	ECHO.
	::terminate batch execution
	CALL bin\batchTerminator.bat
)
GOTO:EOF

:done
ECHO.
CALL:print %info% "Success: Development environment is set."
ECHO. 
