@ECHO OFF
SETLOCAL EnableDelayedExpansion
SET CPU=""
SET CONFIGURATION=Release
SET PLATFORM=x86
SET solutionPath=ortc\windows\solutions\zsLib.Eventing.sln
SET msVS_Path=""
SET x86BuildCompilerOption=amd64_x86
SET x64BuildCompilerOption=amd64
SET armBuildCompilerOption=amd64_arm
SET currentBuildCompilerOption=amd64

SET compilerPath=%cd%\ortc\windows\solutions\Build\Output\!PLATFORM!\!CONFIGURATION!\zsLib.Eventing.Tool.Compiler\zsLib.Eventing.Tool.Compiler.exe
SET windowsKitPath="C:\Program Files (x86)\Windows Kits\10\bin\%PLATFORM%\"

SET eventsIncludePath=..\Internal\
SET eventsIntermediatePath=IntermediateTemp
SET eventsOutput=%cd%\ortc\windows\solutions\eventing\


SET startTime=0
SET endingTime=0

::log levels
SET logLevel=4											
SET error=0														
SET info=1														
SET warning=2													
SET debug=3														
SET trace=4	


:main
SET startTime=%time%

CALL:determineVisualStudioPath

CALL:setCompilerOption %PLATFORM%

::CALL:buildEventing

CALL:prepareEvent
GOTO:EOF

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


:buildEventing

IF EXIST %msVS_Path% (
	CALL %msVS_Path%\VC\vcvarsall.bat %currentBuildCompilerOption%
	IF ERRORLEVEL 1 CALL:error 1 "Could not setup compiler for  %PLATFORM%"
	
	MSBuild %solutionPath% /property:Configuration=%CONFIGURATION% /property:Platform=%PLATFORM% /t:Clean;Build /nodeReuse:False /m
	if ERRORLEVEL 1 CALL:error 1 "Building zsLib.Eventing.Tool.Compiler projects for %PLATFORM% has failed"
) ELSE (
	CALL:error 1 "Could not compile because proper version of Visual Studio is not found"
)
GOTO:EOF

:compileEvents
SET eventJsonPath=%1
SET eventPath=%~dp1
SET providerName=%~n1
SET intermediatePath=!eventPath!%eventsIntermediatePath%\
SET headersPath=!eventPath!%eventsIncludePath%!providerName!
SET outputPath=%eventsOutput%!providerName!

echo eventJsonPath=!eventJsonPath!
echo eventPath=!eventPath!
echo providerName=!providerName!
echo intermediatePath=!intermediatePath!
echo headersPath=!headersPath!
echo outputPath=!outputPath!
echo windowsKitPath=%windowsKitPath%
pause

CALL:createFolder !headersPath!
CALL:createFolder !intermediatePath!
CALL:createFolder !outputPath!

pause

PUSHD !eventPath!
CALL %compilerPath% -c !eventJsonPath! -o %eventsIncludePath%!providerName!\!providerName! > NUL

pause
echo Create manifest header file...

%windowsKitPath%mc.exe -um -r !intermediatePath! -h "!headersPath!" "!headersPath!\!providerName!_win_etw.man"

pause
echo Create resource file...
%windowsKitPath%rc.exe !intermediatePath!!providerName!_win_etw.rc

echo Create manifest resource dll...
pause

echo If compiling to managed code resource DLL use: csc.exe /out:!intermediatePath!!providerName!_win_etw.dll /target:library /win32res:!intermediatePath!!providerName!_win_etw.res

%msVS_Path%\VC\bin\link -dll -noentry /MACHINE:%PLATFORM% -out:!intermediatePath!!providerName!_win_etw.dll !intermediatePath!!providerName!_win_etw.res

echo Copy files to output directory...
pause
CALL:copyFiles !intermediatePath!!providerName!_win_etw.dll "!outputPath!\"
CALL:copyFiles "!headersPath!\!providerName!.jman" "!outputPath!\"
CALL:copyFiles "!headersPath!\!providerName!_win_etw.man" "!outputPath!\"
CALL:copyFiles "!headersPath!\!providerName!_win_etw.wprp" "!outputPath!\"
pause
icacls "!outputPath!\!providerName!_win_etw.dll" /grant Users:RX
popd

GOTO:EOF

:prepareEvent

for /r . %%g in (*.events.json) do CALL:compileEvents %%g

GOTO:EOF

:copyFiles
IF EXIST %1 (
	CALL:createFolder %2
	CALL:print %debug% "Copying %1 to %2"
	COPY %1 %2
	IF ERRORLEVEL 1 CALL:error 1 "Could not copy a %1"
) ELSE (
	CALL:error 1 "Could not copy a %1"
)
GOTO:EOF

:createFolder
IF NOT EXIST %1 (
	CALL:print %trace% "Creating folder %1"
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
	CALL:print %error% "FAILURE: Building zsLib.Eventing.Tool.Compiler executable has failed!"
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
CALL:print %info% "Success:  zsLib.Eventing.Tool.Compiler executable is built successfully."
ECHO.
SET endTime=%time%
CALL:showTime
:end
