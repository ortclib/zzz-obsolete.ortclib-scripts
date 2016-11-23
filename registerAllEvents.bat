@ECHO OFF
SETLOCAL EnableDelayedExpansion


net session >nul 2>&1
if %errorLevel% == 0 (
 	echo Registering events...
	for /r ortc\windows\solutions\eventing\ %%g in (re*.bat) do cd %%~dpg & CALL %%g
) else ( 
 	echo Failure: Events registration can be only run from command prompt as administrator
)
