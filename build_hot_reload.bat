@echo off

:: 
::
::
::
:: Have some way to differentiate between DLLs (OLD vs NEW)
::
:: Differentiate between PDBs
::
:: IF executable is running, we dont want to build the hot reload mgr app again . only the game.dll
:: else we want to clear the build\hot_reload directory
:: 
:: load raylib inside hot reload mgr app

set GAME_RUNNING=false

set BUILD_DIR=build
set OUT_DIR=build\hot_reload

if not exist %BUILD_DIR% mkdir %BUILD_DIR%
if not exist %OUT_DIR% mkdir %OUT_DIR%

set EXE=hot_reload.exe


for /f %%x in ('tasklist /nh /fi "IMAGENAME eq %EXE%"') do if %%x == %EXE% set GAME_RUNNING=true

set DLL_NAME=game

SET /A PDB_RAND_NUM=%RANDOM%
SET PDB_NAME=%DLL_NAME%_%PDB_RAND_NUM%



if %GAME_RUNNING%==false (
	del /q /s %OUT_DIR% >nul 2>nul
	odin build source\main_hot_reload -debug -out:%OUT_DIR%\%EXE% -pdb-name:%OUT_DIR%\main_hot_reload.pdb
	echo "Built %EXE%"
	IF %ERRORLEVEL% NEQ 0 exit /b 1
) else (
	echo "Already running %EXE%"
)

odin build source\game -debug -define:RAYLIB_SHARED=true -build-mode:dll -out:%OUT_DIR%\%DLL_NAME%.dll.tmp -pdb-name:%OUT_DIR%\%PDB_NAME%.pdb
IF %ERRORLEVEL% NEQ 0 exit /b 1

move /Y %OUT_DIR%\%DLL_NAME%.dll.tmp %OUT_DIR%\%DLL_NAME%.dll


set ODIN_PATH=
for /f %%i in ('odin root') do set "ODIN_PATH=%%i"

if not exist "%OUT_DIR%\raylib.dll" (
	copy "%ODIN_PATH%\vendor\raylib\windows\raylib.dll" %OUT_DIR%
	IF %ERRORLEVEL% NEQ 0 exit /b 1
)
