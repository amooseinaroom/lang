@echo off

cd lang
call build_lang.bat
call build_stb_truetype_lib.bat
call build_stb_image_lib.bat
cd ..
call build_embedded_files.bat
call build.bat