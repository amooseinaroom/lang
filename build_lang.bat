@echo off

rem call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" > NUL

rem version 0 - 21.05.2022

set name=lang

set includes=/I %cd%/code /I %cd%/common /I %cd%/common/win32

set source=%cd%\code\main.cpp
set debug_options=/MTd /Od /DEBUG /Zi /EHsc /nologo %includes%
set release_options=/MT /O2 /Zi /EHsc /nologo %includes%

if not exist build mkdir build

del build\embedded_files.rc > NUL 2>NUL
echo lang_internal.t RCDATA "%cd:\=/%/code/lang_internal.t" >> build\embedded_files.rc

pushd build

rc /nologo /fo emedded_files.res /r embedded_files.rc

cl /Fe%name%d %source% %debug_options% emedded_files.res /link /INCREMENTAL:NO
cl /Fe%name% %source% %release_options% emedded_files.res /link /INCREMENTAL:NO

popd

copy code\lang_internal.t lang_internal.t >NUL 2>NUL

copy build\*.pdb *.pdb* >NUL 2>NUL
copy build\*.dll *.dll* >NUL 2>NUL
copy build\*.exe *.exe* >NUL 2>NUL
