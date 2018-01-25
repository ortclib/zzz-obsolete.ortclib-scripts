@ECHO OFF
SETLOCAL EnableDelayedExpansion


::input arguments
SET supportedInputArguments=;all;events;idl;
SET all=0
SET events=0
SET idl=0

::log levels
SET logLevel=2							
SET error=0														
SET info=1														
SET warning=2													
SET debug=3														
SET trace=4	

SET outPath=webrtc\xplatform\webrtc\out
SET idlFlagPath=webrtc\xplatform\webrtc\ortc\idl.flg
SET flgsPath=webrtc\xplatform\webrtc\ortc

ECHO.
CALL:print %info% "Running cleanup script ..."
CALL:print %info% "================================="

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
IF %all% EQU 1 SET events=1 && SET idl=1

IF %events% EQU 1 CALL:cleanEvents
IF %idl% EQU 1 CALL:cleanidls
IF %all% EQU 1 CALL:cleanWebRtcOut

GOTO:done

:cleanWebRtcOut
IF EXIST %outPath% RD /S /Q %outPath% > NUL
GOTO:EOF

:cleanEvents

  DEL %flgsPath%\*_eventsCompiled.flg /a /s
  
GOTO:EOF

:cleanidls

  DEL %idlFlagPath%
  
GOTO:EOF

:cleanup
IF EXIST %solutionPath% DEL /s /q /f %solutionPath% > NUL
FOR /D /R ortc\xplatform %%X IN (*IntermediateTemp*) DO RD /S /Q "%%X" > NUL

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
	CALL:print %error% "FAILURE: Eventing preparations has failed!"
	ECHO.
	CALL %~dp0\batchTerminator.bat
)
GOTO:EOF

:done
ECHO.
CALL:print %info% "Success: Cleanup is executed successfully."
ECHO.

:end
