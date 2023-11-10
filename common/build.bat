@echo off

set name=
if "%name%"=="" (
    rem find directory name and use it as exe name
    for %%I in (.) do set name=%%~nxI
)

set source=%cd%\code\main.cpp
set options=/MTd /Od /DEBUG /Zi /EHsc /nologo /I %cd%\code /I %cd%\common
rem set options=/MT /O2 /EHsc /nologo /I %cd%\code /I %cd%\common

if not exist build mkdir build
pushd build

cl /Fe%name% %source% %options% /link /INCREMENTAL:NO

popd

copy build\*.pdb *.pdb >NUL 2>NUL
copy build\*.dll *.dll >NUL 2>NUL
copy build\*.exe *.exe >NUL 2>NUL
