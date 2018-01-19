:: Name:      buildWebRTC.bat
:: Purpose:   Builds WebRTC lib
:: Author:    Sergej Jovanovic
:: Email:     sergej@gnedo.com
:: Twitter:   @JovanovicSergej
:: Revision:  December 2017 - initial version

@ECHO off
SETLOCAL EnableDelayedExpansion

SET CONFIGURATION=%1
SET PLATFORM=%2
SET SOFTWARE_PLATFORM=%3
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

SET baseBuildPath=webrtc\xplatform\webrtc\out

CALL:print %info% "Webrtc build is started. It will take couple of minutes."
CALL:print %info% "Working ..."

SET currentPlatform=%PLATFORM%
SET linkPlatform=%currentPlatform%

CALL:print %info%  "%PLATFORM%"
CALL:print %info%  "%Platform !currentPlatform!"

SET startTime=%time%

CALL:determineVisualStudioPath

CALL:setCompilerOption %currentPlatform%

CALL:buildNativeLibs

GOTO:done

:determineVisualStudioPath

SET progfiles=%ProgramFiles%
IF NOT "%ProgramFiles(x86)%" == "" SET progfiles=%ProgramFiles(x86)%

REM Check if Visual Studio 2017 is installed
SET msVS_Path="%progfiles%\Microsoft Visual Studio\2017"
SET msVS_Version=14

IF EXIST !msVS_Path! (
	SET msVS_Path=!msVS_Path:"=!
	IF EXIST "!msVS_Path!\Community" SET msVS_Path="!msVS_Path!\Community"
	IF EXIST "!msVS_Path!\Professional" SET msVS_Path="!msVS_Path!\Professional"
	IF EXIST "!msVS_Path!\Enterprise" SET msVS_Path="!msVS_Path!\Enterprise"
	IF EXIST "!msVS_Path!\VC\Tools\MSVC" SET tools_MSVC_Path=!msVS_Path!\VC\Tools\MSVC
)

IF NOT EXIST !msVS_Path! CALL:error 1 "Visual Studio 2017 is not installed"

for /f %%i in ('dir /b %tools_MSVC_Path%') do set tools_MSVC_Version=%%i

CALL:print %debug% "Visual Studio path is !msVS_Path!"
CALL:print %debug% "Visual Studio 2017 Tools MSVC Version is !tools_MSVC_Version!"

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
        SET linkPlatform=x64
			) ELSE (
				SET currentBuildCompilerOption=%x86Win32BuildCompilerOption%
        SET linkPlatform=x86
			)
		) ELSE (
			SET currentBuildCompilerOption=%x64BuildCompilerOption%
		)
	)
)

CALL:print %trace% "Selected compiler option is %currentBuildCompilerOption%"

GOTO:EOF

:buildNativeLibs
  IF EXIST !baseBuildPath! (
    PUSHD !baseBuildPath!
    SET ninjaPath=..\..\..\..\..\webrtc\xplatform\depot_tools\ninja
    SET outputPath=win_x64_!CONFIGURATION!
    
    IF NOT "%currentPlatform%"=="%currentPlatform:win32=%" (
			IF NOT "%currentPlatform%"=="%currentPlatform:x64=%" (
				SET outputPath=win_x64_!CONFIGURATION!
			) ELSE (
				SET outputPath=win_x86_!CONFIGURATION!
			)
		) ELSE (
			SET outputPath=winuwp_10_!PLATFORM!_!CONFIGURATION!
		)
    
    CD !outputPath!
    IF ERRORLEVEL 1 CALL:error 1 "!outputPath! folder doesn't exist"
    
    CALL:print %warning% "Building %SOFTWARE_PLATFORM% native libs"
    !ninjaPath! %SOFTWARE_PLATFORM%
    IF ERRORLEVEL 1 CALL:error 1 "Building %SOFTWARE_PLATFORM% in %CD% has failed"s
    
    IF /I "%SOFTWARE_PLATFORM%"=="webrtc" (
      CALL:print %warning% "Building webrtc/rtc_base:rtc_json native lib"
      !ninjaPath! webrtc/rtc_base:rtc_json
      IF ERRORLEVEL 1 CALL:error 1 "Building webrtc/rtc_base:rtc_json in %CD% has failed"s
    )
    
    IF NOT "%SOFTWARE_PLATFORM%"=="webrtc/examples:peerconnection_server" CALL:combineLibs !outputPath!
    CD ..
  )
GOTO:EOF

:build

IF EXIST %msVS_Path% (
	CALL %msVS_Path%\VC\Auxiliary\Build\vcvarsall.bat %currentbuildCompilerOption%
	IF ERRORLEVEL 1 CALL:error 1 "Could not setup compiler for  %PLATFORM%"
	
rem	MSBuild %SOLUTIONPATH% /property:Configuration=%CONFIGURATION% /property:Platform=%PLATFORM% /t:Build /nodeReuse:False
	MSBuild %SOLUTIONPATH% /property:Configuration=GN /property:Platform=%PLATFORM% /t:Build /nodeReuse:False
	IF ERRORLEVEL 1 CALL:error 1 "Building WebRTC projects for %PLATFORM% has failed"
) ELSE (
	CALL:error 1 "Could not compile because proper version of Visual Studio is not found"
)
GOTO:EOF

:combineLibs
CALL:setPaths %~dp1

CALL %msVS_Path%\VC\Auxiliary\Build\vcvarsall.bat %currentbuildCompilerOption%
IF ERRORLEVEL 1 CALL:error 1 "Could not setup compiler for  %PLATFORM%"

IF NOT EXIST %destinationPath% (
	CALL:makeDirectory %destinationPath%
	IF ERRORLEVEL 1 CALL:error 1 "Could not make a directory %destinationPath%libs"
)

SET webRtcLibs=

FOR /f %%A IN ('forfiles -p %libsSourcePath% /s /m *.lib /c "CMD /c ECHO @relpath"') DO ( SET temp=%%~A && IF "!temp!"=="!temp:protobuf_full_do_not_use=!" SET webRtcLibs=!webRtcLibs! %%~A )

PUSHD %libsSourcePath%

IF NOT "!webRtcLibs!"=="" %msVS_Path%\VC\Tools\MSVC\%tools_MSVC_Version%\bin\Hostx64\!linkPlatform!\lib.exe /IGNORE:4264,4221,4006 /OUT:%destinationPath%webrtc.lib !webRtcLibs!
IF ERRORLEVEL 1 CALL:error 1 "Failed combining libs"

IF EXIST *.dll (
	CALL:print %debug% "Copying dlls from %libsSourcePath% to %destinationPath%"
	FOR /f %%A IN ('forfiles -p %libsSourcePath% /s /m *.dll /c "CMD /c ECHO @relpath"') DO ( COPY %%~A %destinationPath% >NUL )
)

CALL:print %debug% "Copying pdbs from %libsSourcePath% to %destinationPath%"

FOR /f %%A IN ('forfiles -p %libsSourcePath% /s /m *.pdb /c "CMD /c ECHO @relpath"') DO ( SET temp=%%~A && IF "!temp!"=="!temp:protobuf_full_do_not_use=!" COPY %%~A %destinationPath% >NUL )

IF ERRORLEVEL 1 CALL:error 0 "Failed copying pdb files"
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


CALL:print %debug% "Copying %libsSourcePath% to %libsSourceBackupPath%"
COPY %libsSourcePath% %libsSourceBackupPath%
if ERRORLEVEL 1 CALL:error 0 "Failed copying %libsSourcePath% to %libsSourceBackupPath%"

GOTO:EOF

:setPaths
SET basePath=%1
SET libsSourcePath=%basePath%

SET libsSourceBackupPath=%basePath%..\..\WEBRTC_BACKUP_BUILD\%SOFTWARE_PLATFORM%\%CONFIGURATION%\%currentPlatform%\

CALL:print %debug% "Source path is "%basePath%""

IF NOT "%currentPlatform%"=="%currentPlatform:win32=%" (
  SET destinationPath=%libsSourcePath%..\..\WEBRTC_BUILD\%SOFTWARE_PLATFORM%\%CONFIGURATION%\win32_%linkPlatform%\
) ELSE (
  SET destinationPath=%libsSourcePath%..\..\WEBRTC_BUILD\%SOFTWARE_PLATFORM%\%CONFIGURATION%\%currentPlatform%\
)

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
