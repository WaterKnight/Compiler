cd /d %~dp0

REM IF EXIST running.txt (
REM 	echo "already running"
REM ) ELSE (
	echo "running" > running.txt

	call "saveParams.bat" %*

	lua "luaproach.lua" %*

	pause

	del running.txt
REM )