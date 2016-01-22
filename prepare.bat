@echo off
echo.
echo Preparing ortc-lib-sdk...
echo.

set failure=0
set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe

if EXIST ..\bin\nul call:failure -1 "Do not run scripts from bin directory!"
if "%failure%" neq "0" goto:eof

call:doprepare libs\webrtc ..\..\bin\prepare-webrtc.bat WebRTC winrt
if "%failure%" neq "0" goto:eof

rem call:doprepare libs\webrtc ..\..\bin\prepare-webrtc.bat WebRTC win32
rem if "%failure%" neq "0" goto:eof

call:doprepare libs\curl prepare.bat curl
if "%failure%" neq "0" goto:eof

where ninja > NUL 2>&1
if ERRORLEVEL 1 (
	echo Ninja is not in the path
	if NOT EXIST .\bin\ninja.exe (
		echo Downloading ninja ...
		call:install_ninja 
	)

	echo Updating projects ...
	if EXIST .\bin\ninja.exe start /B /wait .\bin\upn.exe .\bin\ .\libs\webrtc\ .\libs\webrtc\chromium\src\
)

where perl > NUL 2>&1
if %errorlevel% equ 1 (
	echo.
	echo ================================================================================
	echo.
	echo Warning! Warning! Warning! Warning! Warning! Warning! Warning!
	echo.
	echo Perl is missing.
	echo You need to have installed Perl to build projects properly.
	echo Use the 32-bit perl from Strawberry http://strawberryperl.com/ to avoid possible linking errors and incorrect assember files generation. 
	echo Download URL: http://strawberryperl.com/download/5.22.0.1/strawberry-perl-5.22.0.1-32bit.msi
	echo Make sure that the perl path from Strawberry appears at the beginning of all other perl paths in the PATH 
	echo.
	echo ================================================================================
	echo.
)

goto:done

:install_ninja

echo Installing ninja ...

%powershell_path% -Command (new-object System.Net.WebClient).DownloadFile('http://github.com/martine/ninja/releases/download/v1.6.0/ninja-win.zip','.\bin\ninja-win.zip')

echo %cd%
echo %~dp0ninja-win.zip
if EXIST .\bin\ninja-win.zip call:unzipfile "%~dp0" "%~dp0ninja-win.zip"

goto:eof

:unzipfile 
set vbs="%temp%\_.vbs"
if exist %vbs% del /f /q %vbs%
>%vbs%  echo Set fso = CreateObject("Scripting.FileSystemObject")
>>%vbs% echo If NOT fso.FolderExists(%1) Then
>>%vbs% echo fso.CreateFolder(%1)
>>%vbs% echo End If
>>%vbs% echo set objShell = CreateObject("Shell.Application")
>>%vbs% echo set FilesInZip=objShell.NameSpace(%2).items
>>%vbs% echo objShell.NameSpace(%1).CopyHere(FilesInZip)
>>%vbs% echo Set fso = Nothing
>>%vbs% echo Set objShell = Nothing
cscript //nologo %vbs%
if exist %vbs% del /f /q %vbs%
del /f /q %2
goto:eof

:doprepare

if NOT EXIST %~1\%~2 call:failure -1 "Did not find %~3 preparation script in %~1\%~2!"
if "%failure%" neq "0" goto:eof

pushd %~1 > NUL
if ERRORLEVEL 1 call:failure %errorlevel% "%~3 preparation failed."
call %~2 %~4%
if ERRORLEVEL 1 call:failure %errorlevel% "%~3 preparation failed."
popd > NUL
if "%failure%" neq "0" goto:eof


goto:eof


:failure
echo.
echo ERROR: %~2
echo.
echo FAILURE: Could not prepare ortc-lib-sdk.

set failure=%~1

goto:eof

:done
echo.
echo Success: completed preparation of ortc-lib SDK.
echo.
