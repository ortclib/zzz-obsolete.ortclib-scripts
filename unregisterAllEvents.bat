@ECHO OFF
SETLOCAL EnableDelayedExpansion

net session >nul 2>&1
if %errorLevel% == 0 (
 	echo Unregistering events...
	for /r ortc\windows\solutions\eventing\ %%g in (unre*.bat) do cd %%~dpg & CALL %%g
) else ( 
 	echo Failure: Events unregistration can be only run from command prompt as administrator
)


