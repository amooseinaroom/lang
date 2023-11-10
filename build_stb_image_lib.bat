@echo off

set includes=/I %cd%/code /I %cd%/common

set source=%cd%\code\stb_image.cpp

if not exist build mkdir build
if not exist release mkdir release
if not exist debug mkdir debug

pushd build

set options=/MT /O2 /EHsc /nologo %includes%
cl /Fostb_image /c %source% %options% /link /INCREMENTAL:NO
lib stb_image.obj /nologo

copy stb_image.lib ..\release\stb_image.lib >NUL 2>NUL

set options=/MTd /Od /DEBUG /Z7 /EHsc /nologo %includes%
cl /Fostb_image /c %source% %options% /link /INCREMENTAL:NO
lib stb_image.obj /nologo

copy stb_image.lib ..\debug\stb_image.lib >NUL 2>NUL

popd
