@echo off

set debug=1
set hot_code_reloading=1
set print_command=0

set name=""
for %%I in (.) do set name=%%~nxI

set dir=%cd%
set project=%~dp0
set lang_path=%project%lang

if %debug%==1 (
    set link_options=/link /nologo /INCREMENTAL:NO /LIBPATH:"%lang_path%\debug" /LIBPATH:"%lang_path%\steamworks_sdk_157\sdk\redistributable_bin\win64"
    set options= /MTd /Od /DEBUG /Zi /EHsc /nologo
) else (
    set link_options=/link /nologo /INCREMENTAL:NO /LIBPATH:"%lang_path%\release" /LIBPATH:"%lang_path%\steamworks_sdk_157\sdk\redistributable_bin\win64"
    set options=/TC /MT /O2 /EHsc /nologo
)

set build=%project%build

if not exist %build% mkdir %build%

set includes=%project%code %lang_path%\modules %lang_path%\modules\win32 %lang_path%\modules\hot_reloading %lang_path%\modules\render

if %hot_code_reloading%==1 (
    set includes=%includes% %project%code\build\hot_reloading.t
)

if %debug%==1 (
    set includes=%includes% %project%code\build\debug.t
) else (
    set includes=%includes% %project%code\build\release.t
)

set command=%lang_path%\lang -cpp %build%\%name%.c %includes%

if %print_command%== 1 ( echo %command% )

%command%

if %ERRORLEVEL%==0 (
    cd %build%

    if %hot_code_reloading%==1 (
        cl /Fo%name% /c %name%.c /TC %options%

        cl /Fe%name%     %name%.obj %options%                   /LD %link_options% /PDB:%name%_dll
        cl /Fe%name%_hot %name%.obj %options% embedded_files.res     %link_options%
        copy %name%_hot.exe %name%.exe >NUL 2>NUL
    ) else (
        cl /Fe%name% %name%.c /TC %options% embedded_files.res %link_options%
    )

    cd %dir%

    copy %build%\*.pdb %project%*.pdb >NUL 2>NUL
    copy %build%\*.dll %project%*.dll >NUL 2>NUL
    copy %build%\*.exe %project%*.exe >NUL 2>NUL

    rem deploy to steam
    rem copy %project%%name%.exe %project%steam\windows_x64_content\%name%.exe >NUL 2>NUL
    rem copy %project%%name%.pdb %project%steam\windows_x64_content\%name%.pdb >NUL 2>NUL
)
