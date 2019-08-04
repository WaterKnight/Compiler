cd /d %~dp0

cd..
cd..

lua "%~dp0exportTrigs.lua" %1

pause