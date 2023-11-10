@echo off

rem call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" > NUL

set name=""
for %%I in (.) do set name=%%~nxI

set dir=%cd%
set project=%~dp0
set lang_path=%project%lang

set debug=1
set hot_code_reloading=1

set print_command=0

if %debug%==1 (
    set link_options=/link /nologo /INCREMENTAL:NO /LIBPATH:"%lang_path%\debug"
    set options=/MTd /Od /DEBUG /Zi /EHsc /nologo
) else (
    set link_options=/link /nologo /INCREMENTAL:NO /LIBPATH:"%lang_path%\release"
    set options=/MT /O2 /EHsc /nologo
)

set build=%project%build

if not exist %build% mkdir %build%

set includes=%project%code %lang_path%\modules %lang_path%\modules\win32

if %hot_code_reloading%==1 (
    set includes=%includes% %lang_path%\modules\hot_reloading
)

if %debug%==1 (
    if %print_command%== 1 (
        echo %lang_path%\lang -cpp %build%\%name%.cpp %includes% %project%code\debug
    )
    
    %lang_path%\lang -cpp %build%\%name%.cpp %includes% %project%code\debug
) else (
    if %print_command%== 1 (
        echo %lang_path%\lang -cpp %build%\%name%.cpp %includes% %project%code\debug
    )
    
    %lang_path%\lang -cpp %build%\%name%.cpp %includes% %project%code\release
)

if %ERRORLEVEL%==0 (
    cd %build%
    
    if %hot_code_reloading%==1 (
        cl /Fo%name% /c %name%.cpp %options%
        
        cl /Fe%name% %name%.obj %options% /LD %link_options%
        cl /Fe%name% %name%.obj %options%     %link_options%
    ) else (
        cl /Fe%name% %name%.cpp %options% %link_options%
    )
    
    cd %dir%
    
    copy %build%\*.pdb %project%*.pdb >NUL 2>NUL
    copy %build%\*.dll %project%*.dll >NUL 2>NUL
    copy %build%\*.exe %project%*.exe >NUL 2>NUL
)