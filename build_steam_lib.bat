@echo off

set name=steam

set includes=/I %cd%/code /I "%cd%\steamworks_sdk_157\sdk\public\steam"
set source=%cd%\code\%name%.cpp


if not exist build mkdir build
if not exist release mkdir release
if not exist debug mkdir debug

pushd build

set options=/MT /O2 /EHsc /nologo %includes%
cl /Fo%name% /c %source% %options% /link /INCREMENTAL:NO
lib %name%.obj /nologo

copy %name%.lib ..\release\%name%.lib >NUL 2>NUL

set options=/MTd /Od /DEBUG /Z7 /EHsc /nologo %includes%
cl /Fo%name% /c %source% %options% /link /INCREMENTAL:NO
lib %name%.obj /nologo

copy %name%.lib ..\debug\%name%.lib >NUL 2>NUL

popd
