@ECHO OFF
SETLOCAL EnableDelayedExpansion

SET HOSTCPU=""
SET CONFIGURATION=Release
::SET PLATFORM=x64
SET eventingToolCompilerCpu=x86
SET solutionPath=ortc\xplatform\zsLib-eventing\projects\msvc\zsLib.Eventing.Win32.sln
SET msVS_Path=""
SET tools_MSVC_Path=""
SET tools_MSVC_Version=""
SET x86BuildCompilerOption=amd64_x86
SET x64BuildCompilerOption=amd64
SET armBuildCompilerOption=amd64_arm
SET currentBuildCompilerOption=amd64

SET ortcZsLibTemplatePath=ortc\windows\templates\events\zsLib.Eventing.sln
SET ortcZsLibDestinationPath=ortc\windows\solutions\
SET compilerOutputPath=%cd%\ortc\xplatform\zsLib-eventing\projects\msvc\Build\Output\!eventingToolCompilerCpu!\!CONFIGURATION!\zsLib.Eventing.Tool.Compiler\zsLib.Eventing.Tool.Compiler.exe
SET compilerPath=%cd%\bin\zsLib.Eventing.Tool.Compiler.exe



SET eventsIncludePath=..\Internal
SET eventsIntermediatePath=IntermediateTemp
SET eventsOutput=%cd%\ortc\windows\solutions\Eventing\
SET idlOutput=%cd%\ortc\xplatform\ortclib-cpp\ortc\idl\
SET idlGeneratedCTemplatesPath=%cd%\ortc\windows\templates\wrappers\c\
SET idlGeneratedCPath=%cd%\ortc\xplatform\ortclib-cpp\ortc\idl\wrapper\generated\c\

SET startTime=0
SET endingTime=0

::input arguments
SET supportedInputArguments=;platform;cpu;managedBuild;logLevel;
SET platform=win32
SET cpu=x64
SET vsCpu=x64
SET managedBuild=0
SET help=0
SET logLevel=2

::log levels
SET logLevel=2							
SET error=0														
SET info=1														
SET warning=2													
SET debug=3														
SET trace=4	

ECHO.
CALL:print %info% "Running eventing preparation script ..."
CALL:print %info% "================================="

IF "%1"=="" (
	CALL:print %warning% "Running script with default parameters: "
	CALL:print %warning% "Managed Build: No"
	CALL:print %warning% "Platform: win32"
	CALL:print %warning% "Cpu: x64"
	CALL:print %warning% "Log level: %logLevel% ^(warning^)"
)

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

IF /I "%platform%"=="all" SET platform="win32"
IF /I "%cpu%"=="all" SET cpu="x64"
IF /I "%cpu%"=="win32" set cpu=x86
SET vsCpu=%cpu%
IF /I "%cpu%"=="x86" (
	IF /I "%platform%"=="win32" SET vsCpu=Win32
)

SET currentPlatform=%platform%
SET currentCpu=%cpu%
SET currentVsCpu=%vsCpu%
CALL:print %warning% "Cpu: %currentCpu%"

CALL:determineWindowsSDK

SET windowsKitPath="C:\Program Files (x86)\Windows Kits\10\bin\%selectedSDKVer%\%currentCpu%\"
SET startTime=%time%

CALL:checkPlatform
CALL:checkCpu
CALL:checkManagedBuild

CALL:determineVisualStudioPath

CALL:setCompilerOption %eventingToolCompilerCpu%

CALL:buildEventingToolCompiler

CALL:prepareEvents

CALL:prepareIdl

CALL:copyTemplates

GOTO:done

:checkPlatform
SET validInput=0

IF /I "%currentPlatform%"=="win32" SET validInput=1

IF /I "%currentPlatform%"=="winuwp" SET validInput=1
	
IF !validInput!==0 CALL:error 1 "Invalid platform"

GOTO:EOF

:checkCpu
SET validInput=0

IF /I "%currentCpu%"=="x64" SET validInput=1

IF /I "%currentCpu%"=="x86" SET validInput=1

IF /I "%currentCpu%"=="arm" SET validInput=1
	
IF !validInput!==0 CALL:error 1 "Invalid cpu"

GOTO:EOF

:checkManagedBuild

managedBuild=0

IF /I "%currentPlatform%"=="winuwp" SET managedBuild=1

GOTO:EOF


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

:determineWindowsSDK
SET windowsSDKPath="Program Files (x86)\Windows Kits\10\Lib\"
SET windowsSDKFullPath=C:\!windowsSDKPath!

IF DEFINED USE_WIN_SDK_FULL_PATH SET windowsSDKFullPath=!USE_WIN_SDK_FULL_PATH! && GOTO parseSDKPath
IF DEFINED USE_WIN_SDK SET windowsSDKVersion=!USE_WIN_SDK! && GOTO setVersion
FOR %%p IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
	IF EXIST %%p:\!windowsSDKPath! (
		SET windowsSDKFullPath=%%p:\!windowsSDKPath!
		GOTO determineVersion
	)
)

:parseSDKPath
IF EXIST !windowsSDKFullPath! (
	FOR %%A IN ("!windowsSDKFullPath!") DO (
		SET windowsSDKVersion=%%~nxA
	)
) ELSE (
	CALL:ERROR 1 "Invalid Windows SDK path"
)
GOTO setVersion

::Supports 16299 or newer SDK
:determineVersion
IF EXIST !windowsSDKFullPath! (
	PUSHD !windowsSDKFullPath!
	FOR /F "delims=" %%a in ('dir /ad /b /on') do (
		FOR /f "tokens=1-3 delims=[.] " %%i IN ("%%a") DO (SET v1=%%k)
		IF !v1! GEQ 16299 SET windowsSDKVersion=%%a
	)
	POPD
) ELSE (
	CALL:ERROR 1 "Invalid Windows SDK path"
)

:setVersion
IF NOT "!windowsSDKVersion!"=="" (
	FOR /f "tokens=1-4 delims=[.] " %%i IN ("!windowsSDKVersion!") DO (SET selectedSDKVer=%%i.%%j.%%k.%%l)
) ELSE (
	CALL:ERROR 1 "Supported Windows SDK is not present. Supported Win SDK are 10.0.16299.0 or newer"
)

IF NOT EXIST !windowsSDKFullPath!..\Debuggers\x64\cdb.exe CALL:ERROR 1 %errorMessageMissingDebuggerTools%
IF NOT EXIST !windowsSDKFullPath!..\Debuggers\x86\cdb.exe CALL:ERROR 1 %errorMessageMissingDebuggerTools%
GOTO:EOF



:setCompilerOption
CALL:print %trace% "Determining compiler options ..."
REG Query "HKLM\Hardware\Description\System\CentralProcessor\0" | FIND /i "x86" > NUL && SET HOSTCPU=x86 || SET HOSTCPU=x64

CALL:print %trace% "Host CPU architecture is %HOSTCPU%"

IF /I %HOSTCPU% == x86 (
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
		IF /I %~1==win32 (
			SET currentBuildCompilerOption=%x86BuildCompilerOption%
		) ELSE (
			SET currentBuildCompilerOption=%x64BuildCompilerOption%
		)
	)
)
CALL:print %trace% "Selected compiler option is %currentBuildCompilerOption%"

GOTO:EOF


:buildEventingToolCompiler

IF EXIST %compilerPath% GOTO:EOF

CALL:print %warning% "Building eventing tool compiler ..."
SET currentFolder=%CD%
IF EXIST %msVS_Path% (
	CALL %msVS_Path%\VC\Auxiliary\Build\vcvarsall.bat %currentBuildCompilerOption%
	IF ERRORLEVEL 1 CALL:error 1 "Could not setup compiler for %eventingToolCompilerCpu%"
	CD !currentFolder!
	CALL:copyFiles %ortcZsLibTemplatePath% %ortcZsLibDestinationPath%
	
	IF %logLevel% GEQ %trace% (
		MSBuild %solutionPath% /property:Configuration=%CONFIGURATION% /property:Platform=%eventingToolCompilerCpu% /t:Clean;Build /nodeReuse:False /m
	) ELSE (
		MSBuild %solutionPath% /property:Configuration=%CONFIGURATION% /property:Platform=%eventingToolCompilerCpu% /t:Clean;Build /nodeReuse:False /m > NUL
	)

	IF ERRORLEVEL 1 CALL:error 1 "Building zsLib.Eventing.Tool.Compiler projects for %eventingToolCompilerCpu% has failed"
) ELSE (
	CALL:error 1 "Could not compile because proper version of Visual Studio is not found"
)
CALL:cleanup

CALL:copyFiles %compilerOutputPath% %cd%\bin\

GOTO:EOF

:compileEvent

SET eventJsonPath=%1
SET eventPath=%~dp1
SET providerName=%~n1
SET intermediatePath=!eventPath!%eventsIntermediatePath%\
SET headersPath=!eventPath!%eventsIncludePath%
SET outputPath=%eventsOutput%!providerName!\%currentCpu%

IF EXIST webrtc\xplatform\webrtc\ortc\!providerName!_eventsCompiled.flg GOTO:EOF

CALL:print %warning% "Preparing !providerName! ..."
CALL:print %trace% eventJsonPath=!eventJsonPath!
CALL:print %trace% eventPath=!eventPath!
CALL:print %trace% providerName=!providerName!
CALL:print %trace% intermediatePath=!intermediatePath!
CALL:print %trace% headersPath=!headersPath!
CALL:print %trace% outputPath=!outputPath!
CALL:print %trace% windowsKitPath=%windowsKitPath%


::CALL:createFolder !headersPath!
CALL:createFolder !intermediatePath!
CALL:createFolder !outputPath!

PUSHD !eventPath!

IF %logLevel% GEQ %trace% (
	CALL %compilerPath% -c !eventJsonPath! -o %eventsIncludePath%\!providerName!
) ELSE (
	CALL %compilerPath% -c !eventJsonPath! -o %eventsIncludePath%\!providerName! > NUL
)
IF ERRORLEVEL 1 CALL:error 1 "Running events tool has failed"

CALL:print %debug% "Creating manifest header file ..."

IF %logLevel% GEQ %trace% (
	%windowsKitPath%mc.exe -um -r !intermediatePath! -h "!headersPath!" "!headersPath!\!providerName!_win_etw.man"
) ELSE (
	%windowsKitPath%mc.exe -um -r !intermediatePath! -h "!headersPath!" "!headersPath!\!providerName!_win_etw.man" > NUL
)
IF ERRORLEVEL 1 CALL:error 1 "Creating manifest header file has failed"

CALL:print %debug% "Creating resource file ..."

IF %logLevel% GEQ %trace% (
	%windowsKitPath%rc.exe !intermediatePath!!providerName!_win_etw.rc
) ELSE (
	%windowsKitPath%rc.exe !intermediatePath!!providerName!_win_etw.rc > NUL
)
IF ERRORLEVEL 1 CALL:error 1 "Creating resource has failed"

CALL:print %debug% "Creating manifest resource dll for !currentCpu! ..."

IF %managedBuild% EQU 1 (
	echo csc
	IF %logLevel% GEQ %trace% (
		%msVS_Path%\MSBuild\15.0\Bin\Roslyn\csc.exe /out:!intermediatePath!!providerName!_win_etw.dll /target:library /win32res:!intermediatePath!!providerName!_win_etw.res
	) ELSE (
		%msVS_Path%\MSBuild\15.0\Bin\Roslyn\csc.exe /out:!intermediatePath!!providerName!_win_etw.dll /target:library /win32res:!intermediatePath!!providerName!_win_etw.res > NUL
	)
) ELSE (  
	echo link
	SET tempCpu=%currentCpu%
  echo %msVS_Path%\VC\Tools\MSVC\%tools_MSVC_Version%\bin\Hostx64\!tempCpu!\link
	IF %logLevel% GEQ %trace% (
        %msVS_Path%\VC\Tools\MSVC\%tools_MSVC_Version%\bin\Hostx64\!tempCpu!\link -verbose -dll -noentry /MACHINE:%currentCpu% -out:!intermediatePath!!providerName!_win_etw.dll !intermediatePath!!providerName!_win_etw.res
	) ELSE (
        %msVS_Path%\VC\Tools\MSVC\%tools_MSVC_Version%\bin\Hostx64\!tempCpu!\link -dll -noentry /MACHINE:%currentCpu% -out:!intermediatePath!!providerName!_win_etw.dll !intermediatePath!!providerName!_win_etw.res > NUL
	)
)
IF ERRORLEVEL 1 CALL:error 1 "Creating manifest resource dll has failed"

CALL:print %debug% "Coping files to output directory ..."

CALL:copyFiles !intermediatePath!!providerName!_win_etw.dll "!outputPath!\"
CALL:copyFiles "!headersPath!\!providerName!.jman" "!outputPath!\"
CALL:copyFiles "!headersPath!\!providerName!_win_etw.man" "!outputPath!\"
CALL:copyFiles "!headersPath!\!providerName!_win_etw.wprp" "!outputPath!\"

IF %logLevel% GEQ %trace% (
	icacls "!outputPath!\!providerName!_win_etw.dll" /grant Users:RX
) ELSE (
	icacls "!outputPath!\!providerName!_win_etw.dll" /grant Users:RX > NUL
)
POPD

CALL:createRegistrationBatch !outputPath! !providerName!
CALL:createUnregistrationBatch !outputPath! !providerName!

CALL:cleanup

GOTO:EOF

:createRegistrationBatch
CALL:print %trace% "Creating registration batch file for %2"

SET outputFile=%1\register.%2.bat

ECHO @ECHO OFF > !outputFile!
ECHO echo. >> !outputFile!
ECHO echo Registering manifest file and DLL for !providerName! Windows Performance Recorder... >> !outputFile!
ECHO echo. >> !outputFile!
ECHO echo NOTE: Only run from command prompt as administrator >> !outputFile!
ECHO echo. >> !outputFile!

ECHO CALL wevtutil.exe im !providerName!_win_etw.man /rf:"%%cd%%\!providerName!_win_etw.dll" /mf:"%%cd%%\!providerName!_win_etw.dll" >> !outputFile!
ECHO POPD >> !outputFile!

GOTO:EOF

:createUnregistrationBatch
CALL:print %trace% "Creating unregistration batch file for %2"

SET outputFile=%1\unregister.%2.bat

ECHO @ECHO OFF > !outputFile!
ECHO echo. >> !outputFile!
ECHO echo Unregistering manifest file and DLL for !providerName! Windows Performance Recorder... >> !outputFile!
ECHO echo. >> !outputFile!
ECHO echo NOTE: Only run from command prompt as administrator >> !outputFile!
ECHO echo. >> !outputFile!

ECHO CALL wevtutil.exe um !providerName!_win_etw.man >> !outputFile!
ECHO POPD >> !outputFile!
GOTO:EOF

:addAdminRights

ECHO net session ^>nul 2^>^&1 >> !outputFile!
ECHO if errorLevel 0 ( >> !outputFile!
ECHO 	echo Success: Administrative permissions confirmed. >> !outputFile!
ECHO ) else ( >> !outputFile!
ECHO 	echo Failure: Current permissions inadequate. >> !outputFile!
ECHO ) >> !outputFile!
	
GOTO:EOF

:prepareEvents

FOR /r . %%g IN (*.events.json) DO CALL:compileEvent %%g

GOTO:EOF

:prepareIdl

IF EXIST webrtc\xplatform\webrtc\ortc\idl.flg GOTO:EOF

CALL:print %warning% "Preparing IDL wrappers [cx cppwinrt json wrapper c python dotnet] ..."

PUSHD %idlOutput%

IF %logLevel% GEQ %trace% (
  CALL %compilerPath% -idl cx cppwinrt json wrapper c python dotnet -c config.json -o .
) ELSE (
  CALL %compilerPath% -idl cx cppwinrt json wrapper c python dotnet -c config.json -o > NUL
)

POPD

IF ERRORLEVEL 1 CALL:error 1 "Running events tool has failed"

GOTO:EOF

:copyTemplates
CALL:print %warning% "Copying templates..."
COPY %idlGeneratedCTemplatesPath%*.* %idlGeneratedCPath% > NUL
IF ERRORLEVEL 1 CALL:error 0 "Failed preparing templates"
GOTO:EOF

:copyFiles
IF EXIST %1 (
	CALL:createFolder %2
	CALL:print %debug% "Copying %1 to %2"
	COPY %1 %2 > NUL
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
	CALL:cleanup
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
CALL:print %info% "Success: Eventing preparations is finished successfully."
ECHO.
SET endTime=%time%
CALL:showTime
:end
