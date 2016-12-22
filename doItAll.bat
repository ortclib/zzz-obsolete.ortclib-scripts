@ECHO OFF

SETLOCAL EnableDelayedExpansion

SET supportedInputArguments=;repo;branch;destinationFolder;recursive;prepare;publish;publishDestination;nugetTarget;nugetVersion;nugetDestination;pack;packDestination;help;logLevel;
SET repo=https://github.com/ortclib/ortclib-sdk.git
SET branch=master
SET destinationFolder=""
SET recursive=1
SET prepare=1
SET publishDestination=%CD%\..\Publish
SET publish=0
SET nugetVersion=""
SET prerelease=""
SET nugetTarget=""
SET nugetDestination=""
SET pack=0
SET packDestination=""
SET help=0
SET logLevel=2

SET globalLogLevel=2											
SET error=0														
SET info=1														
SET warning=2													
SET debug=3														
SET trace=4	

::targets
SET generate_Ortc_Nuget=0
SET generate_WebRtc_Nuget=0

SET ortcAvailable=0
SET startTime=0
SET endingTime=0
SET clonedFolder=""

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

CALL:clone

CALL:prepare

IF NOT "%nugetTarget%"=="" CALL:nuget

GOTO:DONE

:clone
IF %destinationFolder%=="" CALL:error 1 "Destination folder for project cloning is not set"

CALL:createFolder %destinationFolder%

PUSHD %destinationFolder%
IF %recursive% EQU 1 (
	CALL:print %warning% "GIT: Recursively cloning branch %branch% for repo %repo%"
	GIT CLONE -recursive %repo% %branch%
) ELSE (
	CALL:print %warning% "GIT: Cloning branch %branch% for repo %repo%"
	GIT CLONE %repo% %branch%
)

FOR /D %%i in (*.*) do SET clonedFolder=%%~nxi

POPD

GOTO:EOF

:prepare

PUSHD %destinationFolder%\%clonedFolder%
CALL bin\prepare.bat -logLevel %logLevel%
POPD

GOTO:EOF

:nuget

PUSHD %destinationFolder%\%clonedFolder%

CALL:checkOrtcAvailability
CALL:determineNugetTarget

IF %generate_Ortc_Nuget% EQU 1 CALL:makeNuget Ortc

IF %generate_WebRtc_Nuget% EQU 1 CALL:makeNuget WebRtc

POPD
GOTO:EOF

:makeNuget

IF %publish% EQU 1 (
	IF %pack% EQU 1 ( 
		CALL bin\createNuget.bat -logLevel %logLevel% -target %1 -version %nugetVersion% -prerelease %prerelease% -destination %nugetDestination% -publish -publishDestination %publishDestination% -pack -packDestination %packDestination%
	) ELSE (
		CALL bin\createNuget.bat -logLevel %logLevel% -target %1 -version %nugetVersion% -prerelease %prerelease% -destination %nugetDestination% -publish -publishDestination %publishDestination%
	)
) ELSE (
	CALL bin\createNuget.bat -logLevel %logLevel% -target %1 -version %nugetVersion% -prerelease %prerelease% -destination %nugetDestination%
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
PUSHD %destinationFolder%\%clonedFolder%
CALL:print %trace% "Checking is Ortc available"
IF EXIST ortc\NUL SET ortcAvailable=1
POPD
GOTO:EOF

:determineNugetTarget
CALL:print %trace% "Identifying build targets"
SET validInput=0
SET messageText=

IF "%nugetTarget%"=="" CALL:error 1 "Target has to be specified. Available targets are Ortc and WebRtc."

IF /I "%nugetTarget%"=="all" (
	SET generate_Ortc_Nuget=%ortcAvailable%
	SET generate_WebRtc_Nuget=1
	SET validInput=1
	IF !prepare_ORTC_Environemnt! EQU 1 (
		SET messageText=Generating WebRtc and Ortc nuget packages ...
	) ELSE (
		SET messageText=Generating WebRtc nuget package ...
	)
) ELSE (
	IF /I "%nugetTarget%"=="webrtc" (
		SET generate_WebRtc_Nuget=1
		SET validInput=1
	)
	IF /I "%nugetTarget%"=="ortc" (
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

:createFolder
IF NOT EXIST %1 (
	CALL:print %debug% "Creating folder %1"
	MKDIR %1
	IF ERRORLEVEL 1 CALL:error 1 "Could not make a directory %1"
)
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
	CALL:print %error% "FAILURE: Process has failed!"
	ECHO.
	POPD
	::terminate batch execution
	CALL bin\batchTerminator.bat
)
GOTO:EOF
:DONE
