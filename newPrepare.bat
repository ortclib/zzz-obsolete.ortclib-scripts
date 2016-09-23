:: Name:     newPrepare.bat
:: Purpose:  Prepare development environment for ORTC and WebRTC
:: Author:   Sergej Jovanovic
:: Email:	 sergej@gnedo.com
:: Revision: September 2016 - initial version

@ECHO off

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
set taskFailed=0

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
SET supportedInputArguments=;platform;help;logLevel;diagnostic;					
SET platform=all
SET help=0
SET logLevel=2
SET diagnostic=0

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

IF %diagnostic% EQU 1 CALL:diagnostic

::Determine targeted platforms
CALL:identifyTargetedPlatforms

::Check is perl is installed
CALL:perlCheck

::Check if python is installed, and if it is not install it and add in the path
CALL:pythonSetup

::Finish script execution
CALL:done

GOTO:EOF

:diagnostic
SET logLevel=3
CALL:print 2 "Diagnostic mode - checking if some required programs are missing"
CALL:print 2  "================================================================================"
ECHO.
WHERE perl > NUL 2>&1
IF %errorlevel% equ 1 (
	CALL:print 0 "Perl				not installed"
) else (
	CALL:print 1 "Perl				    installed"
)

WHERE python > NUL 2>&1
IF %errorlevel% equ 1 (
	CALL:print 0 "Python				not installed"
) else (
	CALL:print 1 "Python				    installed"
)
ECHO.
CALL:print 2  "================================================================================"
ECHO.
CALL:print 1 "Diagnostic finished"
CALL bin\batchTerminator.bat
GOTO:EOF

REM Based on input arguments determine targeted platforms (WebRTC or ORTC)
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

REM check if entered valid input argument
:checkIfArgumentIsValid
IF "!supportedInputArguments:;%~1;=!" neq "%supportedInputArguments%" (
	::it is valid
	SET %2=1
) ELSE (
	::it is not valid
	SET %2=0
)
GOTO:EOF

REM check if perl is installed
:perlCheck
WHERE perl > NUL 2>&1
IF %errorlevel% equ 1 (
	ECHO.
	CALL:print 2  "================================================================================"
	ECHO.
	CALL:print 2  "Warning! Warning! Warning! Warning! Warning! Warning! Warning!"
	ECHO.
	CALL:print 2  "Perl is missing."
	CALL:print 2  "You need to have installed Perl to build projects properly."
	CALL:print 2  "Use the 32-bit perl from Strawberry http://strawberryperl.com/ to avoid possible linking errors and incorrect assember files generation."
	CALL:print 2  "Download URL: http://strawberryperl.com/download/5.22.1.2/strawberry-perl-5.22.1.2-32bit.msi"
	CALL:print 2  "Make sure that the perl path from Strawberry appears at the beginning of all other perl paths in the PATH" 
	ECHO.
	CALL:print 2  "================================================================================"
	ECHO.
	CALL:print 2  "NOTE: Please restart your command shell after installing perl and re-run this script..."	
	ECHO.
	
	CALL:error 1 "Perl has to be installed before running prepare script!"
	ECHO.	
)
GOTO:EOF

:pythonSetup
WHERE python > NUL 2>&1
IF %ERRORLEVEL% EQU 1 (
	CALL:error 0  "Python is not installed or added in the path"
	CALL:print 2  "Installing Python ..."
	CALL:download https://www.python.org/ftp/python/2.7.6/python-2.7.6.msi  python-2.7.6.msi
	IF !taskFailed!==1 (
		CALL:error 1  "Downloading python installer has failed. Script execution will be terminated. Please, run script once more, if python doesn't get installed again, please do it manually."
	) ELSE (
		START "Python install" /wait msiexec /i python-2.7.6.msi /quiet
		IF !ERRORLEVEL! NEQ 0 (
			CALL:error 1  "Python installation has failed. Script execution will be terminated. Please, run script once more, if python doesn't get installed again, please do it manually."
		) else (
			CALL:print 1 "Python is successfully installed"
		)
		CALL:print 3  "Deleting downloaded file."
		del python-2.7.6.msi
		IF !ERRORLEVEL! NEQ 0 (
			CALL:error 0  "Deleting python installer from /bin folder has failed. You can delete it manually."
		)
	)
	
	IF EXIST C:\Python27\nul CALL:set_path "C:\Python27"
	IF EXIST D:\Python27\nul CALL:set_path "D:\Python27"
	
	WHERE python > NUL 2>&1
	IF !ERRORLEVEL! EQU 1 (
		CALL:error 0  "Python is not added to the path."
	) else (
		CALL:print 1  "Python is added to the path."
	)
) ELSE (
	CALL:print 3  "Python is present."
)

GOTO:EOF

:download
IF EXIST %~2 GOTO:EOF
%powershell_path% "Start-BitsTransfer %~1 -Destination %~2"
IF ERRORLEVEL 1 SET taskFailed=1

GOTO:EOF

:set_path
IF "%~1"=="" EXIT /b 2
IF NOT DEFINED PATH EXIT /b 2
::
:: Determine if function was called while delayed expansion was enabled
SETLOCAL
SET "NotDelayed=!"
::
:: Prepare to safely parse PATH into individual paths
SETLOCAL DisableDelayedExpansion
SET "var=%path:"=""%"
SET "var=%var:^=^^%"
SET "var=%var:&=^&%"
SET "var=%var:|=^|%"
SET "var=%var:<=^<%"
SET "var=%var:>=^>%"
SET "var=%var:;=^;^;%"
SET var=%var:""="%
SET "var=%var:"=""Q%"
SET "var=%var:;;="S"S%"
SET "var=%var:^;^;=;%"
SET "var=%var:""="%"
SETLOCAL EnableDelayedExpansion
SET "var=!var:"Q=!"
SET "var=!var:"S"S=";"!"
::
:: Remove quotes from pathVar and abort if it becomes empty
rem set "new=!%~1:"^=!"
SET new=%~1

IF NOT DEFINED new EXIT /b 2
::
:: Determine if pathVar is fully qualified
ECHO("!new!"|FINDSTR /i /r /c:^"^^\"[a-zA-Z]:[\\/][^\\/]" ^
                           /c:^"^^\"[\\][\\]" >NUL ^
  && SET "abs=1" || SET "abs=0"
::
:: For each path in PATH, check if path is fully qualified and then
:: do proper comparison with pathVar. Exit if a match is found.
:: Delayed expansion must be disabled when expanding FOR variables
:: just in case the value contains !
FOR %%A IN ("!new!\") DO FOR %%B IN ("!var!") DO (
  IF "!!"=="" SETLOCAL disableDelayedExpansion
  FOR %%C IN ("%%~B\") DO (
    ECHO(%%B|FINDSTR /i /r /c:^"^^\"[a-zA-Z]:[\\/][^\\/]" ^
                           /c:^"^^\"[\\][\\]" >NUL ^
      && (IF %abs%==1 IF /i "%%~sA"=="%%~sC" EXIT /b 0) ^
      || (IF %abs%==0 IF /i %%A==%%C EXIT /b 0)
  )
)
::
:: Build the modified PATH, enclosing the added path in quotes
:: only if it contains ;
SETLOCAL enableDelayedExpansion
IF "!new:;=!" NEQ "!new!" SET new="!new!"
IF /i "%~2"=="/B" (SET "rtn=!new!;!path!") ELSE SET "rtn=!path!;!new!"
::
:: rtn now contains the modified PATH. We need to safely pass the
:: value accross the ENDLOCAL barrier
::
:: Make rtn safe for assignment using normal expansion by replacing
:: % and " with not yet defined FOR variables
SET "rtn=!rtn:%%=%%A!"
SET "rtn=!rtn:"=%%B!"
::
:: Escape ^ and ! if function was called while delayed expansion was enabled.
:: The trailing ! in the second assignment is critical and must not be removed.
IF NOT DEFINED NotDelayed SET "rtn=!rtn:^=^^^^!"
IF NOT DEFINED NotDelayed SET "rtn=%rtn:!=^^^!%" !
::
:: Pass the rtn value accross the ENDLOCAL barrier using FOR variables to
:: restore the % and " characters. Again the trailing ! is critical.
FOR /f "usebackq tokens=1,2" %%A IN ('%%^ ^"') DO (
  ENDLOCAL & ENDLOCAL & ENDLOCAL & ENDLOCAL & ENDLOCAL
  SET "path=%rtn%" !
)
%powershell_path% -NoProfile -ExecutionPolicy Bypass -command "[Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::User)"

GOTO:EOF

:print
SET logType=%1
SET logMessage=%~2

if %logLevel% GEQ  %logType% (
	if %logType%==0 ECHO [91m%logMessage%[0m
	if %logType%==1 ECHO [92m%logMessage%[0m
	if %logType%==2 ECHO [93m%logMessage%[0m
	if %logType%==3 ECHO [95m%logMessage%[0m
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
