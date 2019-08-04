cd /d %~dp0

call "..\..\saveParams.bat" %*

lua "starter.lua" %*

pause