@echo off

SET REPOSITORY=https://github.com/openpeer/ortc-lib-sdk.git
SET BRANCH=%1
SET failure=0
SET REPOSITORY_DIR=ortc-lib-sdk
SET DESTINATION_PATH=

call:createDestinatioFolder
if "%failure%" neq "0" goto:eof

call:clone
if "%failure%" neq "0" goto:eof

echo Repository is successfully cloned

call:prepare
if "%failure%" neq "0" goto:eof

call:createNuget
if "%failure%" neq "0" goto:eof
goto:done

:createDestinatioFolder
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
::For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a%%b)

SET DESTINATION_PATH=%mydate%
::SET DESTINATION_PATH=%mydate%_%mytime%

call:createFolder %DESTINATION_PATH%

echo %DESTINATION_PATH%
goto:eof

:createFolder
if NOT EXIST %1 (
	mkdir %1
	if ERRORLEVEL 1 call:failure %errorlevel% "Could not make a directory %1"
)
goto:eof

:clone
pushd %DESTINATION_PATH%
if "%BRANCH%" neq "" (
	echo Cloning branch %BRANCH%
	git clone --recursive %REPOSITORY% -b "%BRANCH%"
) else (
	echo Cloning master
	git clone --recursive %REPOSITORY%
)
if ERRORLEVEL 1 call:failure %errorlevel% "Could not make a directory %1"
popd
goto:eof

:prepare
pushd %DESTINATION_PATH%\%REPOSITORY_DIR%
call bin\prepare.bat
if ERRORLEVEL 1 call:failure %errorlevel% "Could not make a directory %1"
popd
goto:eof

:createNuget
pushd %DESTINATION_PATH%\%REPOSITORY_DIR%
call bin\createNuget.bat -b -t -p -s c:\nugetPackages
if ERRORLEVEL 1 call:failure %errorlevel% "Could not make a directory %1"
popd
goto:eof
:failure
echo.

echo ERROR: %~2

echo.
echo FAILURE: Could not create a nuget package.

set failure=%~1

goto:eof

:done

echo.
echo Success: ORTC nuget package is created.
echo.
:end