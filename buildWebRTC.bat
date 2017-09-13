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
SET win32BuildCompilerOption=amd64
SET x86Win32BuildCompilerOption=amd64_x86
SET x64Win32BuildCompilerOption=amd64
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

SET currentPlatform=%PLATFORM%

CALL:print %info%  "%PLATFORM%"
CALL:print %info%  "%Platform !currentPlatform!"

SET startTime=%time%

CALL:determineVisualStudioPath

CALL:setCompilerOption %currentPlatform%

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
	SET win32BuildCompilerOption=x86
	
	SET x86Win32BuildCompilerOption=x86
    SET x64Win32BuildCompilerOption=x86_amd64
)
	
IF /I %~1==x86 (
	SET currentBuildCompilerOption=%x86BuildCompilerOption%
) ELSE (
	IF /I %~1==ARM (
		SET currentBuildCompilerOption=%armBuildCompilerOption%
	) ELSE (
		IF NOT "%currentPlatform%"=="%currentPlatform:win32=%" (
			IF NOT "%currentPlatform%"=="%currentPlatform:x64=%" (
				SET currentBuildCompilerOption=%x64Win32BuildCompilerOption%
			) ELSE (
				SET currentBuildCompilerOption=%x86Win32BuildCompilerOption%
			)
		) ELSE (
			SET currentBuildCompilerOption=%x64BuildCompilerOption%
		)
	)
)

CALL:print %trace% "Selected compiler option is %currentBuildCompilerOption%"

GOTO:EOF


:build

IF EXIST %msVS_Path% (
	CALL %msVS_Path%\VC\vcvarsall.bat %currentBuildCompilerOption%
	IF ERRORLEVEL 1 CALL:error 1 "Could not setup compiler for  %PLATFORM%"
	
rem	MSBuild %SOLUTIONPATH% /property:Configuration=%CONFIGURATION% /property:Platform=%PLATFORM% /t:Build /nodeReuse:False
	MSBuild %SOLUTIONPATH% /property:Configuration=GN /property:Platform=%PLATFORM% /t:Build /nodeReuse:False
	IF ERRORLEVEL 1 CALL:error 1 "Building WebRTC projects for %PLATFORM% has failed"
) ELSE (
	CALL:error 1 "Could not compile because proper version of Visual Studio is not found"
)
GOTO:EOF

:combineLibs
CALL:setPaths %SOLUTIONPATH%

IF NOT EXIST %destinationPath% (
	CALL:makeDirectory %destinationPath%
	IF ERRORLEVEL 1 CALL:error 1 "Could not make a directory %destinationPath%libs"
)

SET webRtcLibs=

FOR /f %%A IN ('forfiles -p %libsSourcePath% /s /m *.lib /c "CMD /c ECHO @relpath"') DO ( SET temp=%%~A && IF "!temp!"=="!temp:protobuf_full_do_not_use=!" SET webRtcLibs=!webRtcLibs! %%~A )
IF EXIST %libsSourcePath%\..\..\boringssl.dll.lib SET webRtcLibs=!webRtcLibs! ..\..\boringssl.dll.lib
IF EXIST %libsSourcePath%\..\..\protobuf_lite.dll.lib SET webRtcLibs=!webRtcLibs! ..\..\protobuf_lite.dll.lib

PUSHD %libsSourcePath%
IF NOT "!webRtcLibs!"=="" %msVS_Path%\VC\Bin\lib.exe /OUT:%destinationPath%webrtc.lib !webRtcLibs!
IF ERRORLEVEL 1 CALL:error 1 "Failed combining libs"

IF EXIST *.dll (
	CALL:print %debug% "Moving dlls from %libsSourcePath% to %destinationPath%"
	FOR /f %%A IN ('forfiles -p %libsSourcePath% /s /m *.dll /c "CMD /c ECHO @relpath"') DO ( COPY %%~A %destinationPath% >NUL )
)

CALL:print %debug% "Moving pdbs from %libsSourcePath% to %destinationPath%"

FOR /f %%A IN ('forfiles -p %libsSourcePath% /s /m *.pdb /c "CMD /c ECHO @relpath"') DO ( SET temp=%%~A && IF "!temp!"=="!temp:protobuf_full_do_not_use=!" MOVE %%~A %destinationPath% >NUL )
IF EXIST %libsSourcePath%\..\..\boringssl.dll.pdb  MOVE ..\..\boringssl.dll.pdb %destinationPath% 
IF EXIST %libsSourcePath%\..\..\protobuf_lite.dll.pdb  MOVE ..\..\protobuf_lite.dll.pdb %destinationPath% 

IF EXIST %libsSourcePath%\..\..\boringssl.dll COPY ..\..\boringssl.dll %destinationPath% 
IF EXIST %libsSourcePath%\..\..\protobuf_lite.dll COPY ..\..\protobuf_lite.dll %destinationPath% 

IF ERRORLEVEL 1 CALL:error 0 "Failed moving pdb files"
POPD
GOTO:EOF

:appendLibPath
if "%~1"=="%~1:protobuf_lite.dll=%" SET webRtcLibs=!webRtcLibs! %~1
GOTO:EOF

:moveLibs

IF NOT EXIST %libsSourceBackupPath%NUL (
	CALL:makeDirectory %libsSourceBackupPath%
	CALL:print %trace% "Created folder %libsSourceBackupPath%"
) ELSE (
	IF EXIST %libsSourceBackupPath%%CONFIGURATION%\NUL RD /S /Q %libsSourceBackupPath%%CONFIGURATION%
)


CALL:print %debug% "Moving %libsSourcePath% to %libsSourceBackupPath%"
MOVE %libsSourcePath% %libsSourceBackupPath%
if ERRORLEVEL 1 CALL:error 0 "Failed moving %libsSourcePath% to %libsSourceBackupPath%"

GOTO:EOF

:setPaths
SET basePath=%~dp1

IF /I "%currentPlatform%"=="x64" (
	SET libsSourcePath=%basePath%obj\webrtc
	SET libsSourceBackupPath=%basePath%..\..\WEBRTC_BACKUP_BUILD\%SOFTWARE_PLATFORM%\%CONFIGURATION%\%currentPlatform%\
)

IF /I "%currentPlatform%"=="x86" (
	SET libsSourcePath=%basePath%obj\webrtc
	SET libsSourceBackupPath=%basePath%..\..\WEBRTC_BACKUP_BUILD\%SOFTWARE_PLATFORM%\%CONFIGURATION%\%currentPlatform%\
)

IF /I "%currentPlatform%"=="ARM" (
	SET libsSourcePath=%basePath%obj\webrtc
	SET libsSourceBackupPath=%basePath%..\..\WEBRTC_BACKUP_BUILD\%SOFTWARE_PLATFORM%\%CONFIGURATION%\%currentPlatform%\
)


IF /I "%currentPlatform%"=="win32" (
	SET libsSourcePath=%basePath%build_win32\%CONFIGURATION%
	SET libsSourceBackupPath=%basePath%build_win32\%SOFTWARE_PLATFORM%\
)

IF /I "%currentPlatform%"=="win32_x64" (
	SET libsSourcePath=%basePath%build_win32\%CONFIGURATION%_x64
	SET libsSourceBackupPath=%basePath%build_win32\%SOFTWARE_PLATFORM%\
)

CALL:print %debug% "Source path is %libsSourcePath%"

::SET destinationPath=%basePath%WEBRTC_BUILD\%SOFTWARE_PLATFORM%\%CONFIGURATION%\%currentPlatform%\
SET destinationPath=%libsSourcePath%\..\..\..\..\WEBRTC_BUILD\%SOFTWARE_PLATFORM%\%CONFIGURATION%\%currentPlatform%\

CALL:print %debug% "Destination path is %destinationPath%"
GOTO :EOF

:makeDirectory
IF NOT EXIST %~1\NUL (
	MKDIR %~1
	CALL:print %trace% "Created folder %~1"
) ELSE (
	CALL:print %trace% "%~1 folder already exists"
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
	CALL:print %error% "FAILURE: Building WebRtc library has failed!"
	ECHO.
	SET endTime=%time%
	CALL:showTime
	POPD
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
