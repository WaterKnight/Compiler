cd /d %~dp0

cd..
cd..

lua "%~dp0readMapInfo.lua" %1

pause