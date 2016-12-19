:: Name:      buildWebRTC.bat
:: Purpose:   Builds WebRTC lib
:: Author:    Sergej Jovanovic
:: Email:     sergej@gnedo.com
:: Twitter:   @JovanovicSergej
:: Revision:  November 2016 - initial version

@ECHO off
SETLOCAL EnableDelayedExpansion

SET SOLUTIONPATH=%1
SET CONFIGURATION=%2
SET PLATFORM=%3
SET SOFTWARE_PLATFORM=%4
SET msVS_Path=""
SET failure=0
SET x86BuildCompilerOption=amd64_x86
SET x64BuildCompilerOption=amd64
SET armBuildCompilerOption=amd64_arm
SET currentBuildCompilerOption=amd64

SET startTime=0
SET endingTime=0

::log levels
SET logLevel=4											
SET error=0														
SET info=1														
SET warning=2													
SET debug=3														
SET trace=4	

CALL:print %info% "Webrtc build is started. It will take couple of minutes."
CALL:print %info% "Working ..."
echo 9999
SET startTime=%time%

CALL:determineVisualStudioPath

CALL:setCompilerOption %PLATFORM%

CALL:build

CALL:combineLibs

CALL:moveLibs

GOTO:done

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


:build

IF EXIST %msVS_Path% (
	CALL %msVS_Path%\VC\vcvarsall.bat %currentBuildCompilerOption%
	IF ERRORLEVEL 1 CALL:error 1 "Could not setup compiler for  %PLATFORM%"
	
	MSBuild %SOLUTIONPATH% /property:Configuration=%CONFIGURATION% /property:Platform=%PLATFORM% /t:Clean;Build /nodeReuse:False /m
	if ERRORLEVEL 1 CALL:error 1 "Building WebRTC projects for %PLATFORM% has failed"
) ELSE (
	CALL:error 1 "Could not compile because proper version of Visual Studio is not found"
)
GOTO:EOF

:combineLibs
CALL:setPaths %SOLUTIONPATH%

IF NOT EXIST %destinationPath% (
	MKDIR %destinationPath%
	IF ERRORLEVEL 1 CALL:error 1 "Could not make a directory %destinationPath%libs"
)

%msVS_Path%\VC\Bin\lib.exe /OUT:%destinationPath%webrtc.lib %libsSourcePath%\*.lib %libsSourcePath%\lib\*.lib
IF ERRORLEVEL 1 CALL:error 1 "Failed combining libs"

CALL:print %debug% "Moving pdbs from %libsSourcePath% to %destinationPath%"
IF "%CONFIGURATION%"=="Release" (
	FOR /R %libsSourcePath% %%f in (*.pdb) DO MOVE %%f %destinationPath%
) ELSE (
	MOVE %libsSourcePath%\*.pdb %destinationPath%
)
IF ERRORLEVEL 1 CALL:error 0 "Failed moving pdb files"
GOTO:EOF

:moveLibs

IF NOT EXIST %libsSourcePathDestianation%NUL (
	MKDIR %libsSourcePathDestianation%
	CALL:print %trace% "Created folder %libsSourcePathDestianation%"
) ELSE (
	IF EXIST %libsSourcePathDestianation%%CONFIGURATION%\NUL RD /S /Q %libsSourcePathDestianation%%CONFIGURATION%
)


CALL:print %debug% "Moving %libsSourcePath% to %libsSourcePathDestianation%"
MOVE %libsSourcePath% %libsSourcePathDestianation%
if ERRORLEVEL 1 CALL:error 0 "Failed moving %libsSourcePath% to %libsSourcePathDestianation%"

GOTO:EOF

:setPaths
SET basePath=%~dp1

IF /I "%PLATFORM%"=="x64" (
	SET libsSourcePath=%basePath%build_win10_x64\%CONFIGURATION%
	SET libsSourcePathDestianation=%basePath%build_win10_x64\%SOFTWARE_PLATFORM%\
)

IF /I "%PLATFORM%"=="x86" (
	SET libsSourcePath=%basePath%build_win10_x86\%CONFIGURATION%
	SET libsSourcePathDestianation=%basePath%build_win10_x86\%SOFTWARE_PLATFORM%\
)

IF /I "%PLATFORM%"=="ARM" (
	SET libsSourcePath=%basePath%build_win10_arm\%CONFIGURATION%
	SET libsSourcePathDestianation=%basePath%build_win10_arm\%SOFTWARE_PLATFORM%\
)
CALL:print %debug% "Source path is %libsSourcePath%"

SET destinationPath=%basePath%WEBRTC_BUILD\%SOFTWARE_PLATFORM%\%CONFIGURATION%\%PLATFORM%\

CALL:print %debug% "Destination path is %destinationPath%"
GOTO :EOF

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
	CALL:print %error% "FAILURE: Building WebRtc library has failed!"
	ECHO.
	SET endTime=%time%
	CALL:showTime
	::terminate batch execution
	CALL %~dp0\batchTerminator.bat
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
ECHO.
CALL:print %info% "Success:  WebRtc library is built successfully."
ECHO.
SET endTime=%time%
CALL:showTime
:end
