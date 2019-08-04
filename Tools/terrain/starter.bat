cd /d %~dp0

call "..\..\saveParams.bat" %*

lua terrainer.lua %*

pause