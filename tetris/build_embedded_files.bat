@echo off

if not exist build mkdir build

pushd build

rem add embedded files
del embedded_files.rc > NUL 2>NUL
echo "" >> embedded_files.rc
rem echo icon.ico ICON "%cd:\=/%/assets/icon.ico" >> embedded_files.rc

rem build resource file
rc /nologo /fo embedded_files.res /r embedded_files.rc

popd