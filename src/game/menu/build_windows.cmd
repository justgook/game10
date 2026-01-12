@echo off
REM Build nuklear/sokol_nuklear and menu libraries for Windows
REM Outputs to lib\ folder
REM Follows same pattern as sokol\build_clibs_windows.cmd

set SOKOL_C_DIR=..\sokol\c
set C_DIR=c
set LIB_DIR=lib

if not exist %LIB_DIR% mkdir %LIB_DIR%

REM ============ D3D11 Debug ============
echo Building sokol_nuklear_windows_x64_d3d11_debug...
cl /c /D_DEBUG /DIMPL /DSOKOL_D3D11 /I%SOKOL_C_DIR% /I%C_DIR% %C_DIR%\sokol_nuklear.c /Z7
lib /OUT:%LIB_DIR%\sokol_nuklear_windows_x64_d3d11_debug.lib sokol_nuklear.obj
del sokol_nuklear.obj

echo Building menu_windows_x64_d3d11_debug...
cl /c /D_DEBUG /DIMPL /DSOKOL_D3D11 /I%SOKOL_C_DIR% /I%C_DIR% %C_DIR%\menu.c /Z7
lib /OUT:%LIB_DIR%\menu_windows_x64_d3d11_debug.lib menu.obj
del menu.obj

REM ============ D3D11 Release ============
echo Building sokol_nuklear_windows_x64_d3d11_release...
cl /c /O2 /DNDEBUG /DIMPL /DSOKOL_D3D11 /I%SOKOL_C_DIR% /I%C_DIR% %C_DIR%\sokol_nuklear.c
lib /OUT:%LIB_DIR%\sokol_nuklear_windows_x64_d3d11_release.lib sokol_nuklear.obj
del sokol_nuklear.obj

echo Building menu_windows_x64_d3d11_release...
cl /c /O2 /DNDEBUG /DIMPL /DSOKOL_D3D11 /I%SOKOL_C_DIR% /I%C_DIR% %C_DIR%\menu.c
lib /OUT:%LIB_DIR%\menu_windows_x64_d3d11_release.lib menu.obj
del menu.obj

REM ============ GL Debug ============
echo Building sokol_nuklear_windows_x64_gl_debug...
cl /c /D_DEBUG /DIMPL /DSOKOL_GLCORE /I%SOKOL_C_DIR% /I%C_DIR% %C_DIR%\sokol_nuklear.c /Z7
lib /OUT:%LIB_DIR%\sokol_nuklear_windows_x64_gl_debug.lib sokol_nuklear.obj
del sokol_nuklear.obj

echo Building menu_windows_x64_gl_debug...
cl /c /D_DEBUG /DIMPL /DSOKOL_GLCORE /I%SOKOL_C_DIR% /I%C_DIR% %C_DIR%\menu.c /Z7
lib /OUT:%LIB_DIR%\menu_windows_x64_gl_debug.lib menu.obj
del menu.obj

REM ============ GL Release ============
echo Building sokol_nuklear_windows_x64_gl_release...
cl /c /O2 /DNDEBUG /DIMPL /DSOKOL_GLCORE /I%SOKOL_C_DIR% /I%C_DIR% %C_DIR%\sokol_nuklear.c
lib /OUT:%LIB_DIR%\sokol_nuklear_windows_x64_gl_release.lib sokol_nuklear.obj
del sokol_nuklear.obj

echo Building menu_windows_x64_gl_release...
cl /c /O2 /DNDEBUG /DIMPL /DSOKOL_GLCORE /I%SOKOL_C_DIR% /I%C_DIR% %C_DIR%\menu.c
lib /OUT:%LIB_DIR%\menu_windows_x64_gl_release.lib menu.obj
del menu.obj

echo.
echo Done! Libraries built in %LIB_DIR%\
dir %LIB_DIR%
