@ECHO OFF

SETLOCAL EnableDelayedExpansion

SET supportedInputArguments=;repo;branch;destinationFolder;recursive;prepare;publish;publishDestination;nugetTarget;nugetVersion;nugetDestination;prerelease;pack;packDestination;help;logLevel;noClone;
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
SET noClone=0

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
SET aux=%~1
IF "%aux:~0,1%"=="-" (
	IF NOT "%nome%"=="" (
		SET "%nome%=1"
	)
   SET nome=%aux:~1,250%
   SET validArgument=0
   CALL:checkIfArgumentIsValid !nome! validArgument
   IF !validArgument!==0 CALL:error 1 "Invalid input argument !nome!. For the list of available arguments and usage examples, please run script with -help option."
) ELSE (
	IF NOT "%nome%"=="" (
		SET "%nome%=%1"
		CALL:print %trace% "Processing argument: !nome!"
	) else (
		CALL:error 1 "Invalid input argument !nome!. For the list of available arguments and usage examples, please run script with -help option."
	)
   SET nome=
)
SHIFT
GOTO parseInputArguments

:main

SET startTime=%time%

IF %noClone% EQU 0 CALL:clone

CALL:prepare

IF NOT "%nugetTarget%"=="" CALL:nuget

GOTO:DONE

:clone
IF %destinationFolder%=="" CALL:error 1 "Destination folder for project cloning is not set"

CALL:createFolder %destinationFolder%

PUSHD %destinationFolder%
IF ERRORLEVEL 1 CALL:error 1 "Folder %destinationFolder% doesn't exist"

IF %recursive% EQU 1 (
	CALL:print %warning% "GIT: Recursively cloning branch %branch% for repo %repo%"
	CALL git clone --recursive %repo% -b %branch%
) ELSE (
	CALL:print %warning% "GIT: Cloning branch %branch% for repo %repo%"
	CALL git clone %repo% -b %branch%
)
IF ERRORLEVEL 1 CALL:error 1 "Cloning has failed."

FOR /D %%i in (*.*) do SET clonedFolder=%%~nxi

POPD

GOTO:EOF

:prepare

echo %destinationFolder%
echo %clonedFolder%
PUSHD %destinationFolder%\%clonedFolder%
IF ERRORLEVEL 1 CALL:error 1 "Folder %destinationFolder%\%clonedFolder% doesn't exist"
CALL bin\prepare.bat -logLevel %logLevel%
POPD

GOTO:EOF

:nuget

FOR /D %%i in (%destinationFolder%\*.*) do SET clonedFolder=%%~nxi

PUSHD %destinationFolder%\%clonedFolder%
IF ERRORLEVEL 1 CALL:error 1 "Folder %destinationFolder%\%clonedFolder% doesn't exist"

CALL:checkOrtcAvailability
CALL:determineNugetTarget

IF %generate_Ortc_Nuget% EQU 1 CALL:makeNuget Ortc

IF %generate_WebRtc_Nuget% EQU 1 CALL:makeNuget WebRtc

POPD
GOTO:EOF

:makeNuget

PUSHD %destinationFolder%\%clonedFolder%

SET prereleaseParameter=
IF NOT %prerelease%=="" SET prereleaseParameter=-prerelease %prerelease%

IF %publish% EQU 1 (
	IF %pack% EQU 1 ( 
		CALL:print %warning% "Runing script: bin\createNuget.bat -logLevel %logLevel% -target %1 -version %nugetVersion% -destination %nugetDestination% -publish -publishDestination %publishDestination% -pack -packDestination %packDestination% !prereleaseParameter!"
		CALL bin\createNuget.bat -logLevel %logLevel% -target %1 -version %nugetVersion% -destination %nugetDestination% -publish -publishDestination %publishDestination% -pack -packDestination %packDestination% !prereleaseParameter!
	) ELSE (
	CALL:print %warning% "Runing script: bin\createNuget.bat -logLevel %logLevel% -target %1 -version %nugetVersion% -destination %nugetDestination% -publish -publishDestination %publishDestination%!prereleaseParameter!"
		CALL bin\createNuget.bat -logLevel %logLevel% -target %1 -version %nugetVersion% -destination %nugetDestination% -publish -publishDestination %publishDestination% !prereleaseParameter!
	)
) ELSE (
	CALL:print %warning% "Runing script: bin\createNuget.bat -logLevel %logLevel% -target %1 -version %nugetVersion% -destination %nugetDestination% !prereleaseParameter!"
	CALL bin\createNuget.bat -logLevel %logLevel% -target %1 -version %nugetVersion% -destination %nugetDestination% !prereleaseParameter!
)
POPD
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
	SET endTime=%time%
	CALL:showTime
	::terminate batch execution
	CALL:terminate
)
GOTO:EOF

:terminate
call :CtrlC <"%temp%\ExitBatchYes.txt" 1>nul 2>&1
:CtrlC
cmd /c exit -1073741510

:buildYes - Establish a Yes file for the language used by the OS
pushd "%temp%"
set "yes="
copy nul ExitBatchYes.txt >nul
for /f "delims=(/ tokens=2" %%Y in (
  '"copy /-y nul ExitBatchYes.txt <nul"'
) do if not defined yes set "yes=%%Y"
echo %yes%>ExitBatchYes.txt
popd
exit /b
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
ECHO [93mTotal time: %hours%:%mins%:%secs% (%totalsecs%s total)[0m

GOTO:EOF

:DONE
ECHO.
CALL:print %info% "Success:  Everything is done"
SET endTime=%time%
CALL:showTime
ECHO.