@echo off
SetLocal EnableDelayedExpansion

cls

echo Please type the game directory location, such as:
echo "C:\Program Files\Steam\steamapps\common\Skyrim Special Edition"
echo.
set /p gamedir=Game directory: 

::making links doesn't really work right now
goto:make_copies

echo.
echo How would you like to install the ENB preset?
echo.
echo The installer can either copy the files to the game directory or
echo create symbolic links, which are like shortcuts, to the files.
echo The latter requires administration priviledges for the 'mklink' command
echo so if it doesn't work you need to re-run the install script as admin.
echo.
echo 1)Create copies the preset files in the game directory.
echo 2)Create symbolic links of the preset files in the game directory. [ADVANCED]
echo 3)Exit the installer.
echo.

:choice
set /p type=Type the number of the desired choice: 

if [%type%]==[1] goto:make_copies
if [%type%]==[2] goto:make_symlinks
if [%type%]==[3] cls && goto:eof
::else
echo.
echo Invalid choice, please type 1 or 2 for the wanted choice!
echo.
goto:choice


:make_copies
robocopy "enb" "%gamedir%" /copy:dat /e >nul
echo Installation successful^^!
goto:finish

:make_symlinks
set origindir=%cd%\ENB
if not exist %gamedir% mkdir "%gamedir%"
cd /d %gamedir%

::make symbolic link for each folder
for /d %%i in (%origindir%\*) do (
	if exist "%%~ni" rmdir "%%~ni"
	mklink /d "%%~ni" "%%i" >nul 2>nul
)

::make symbolic link for each file
for %%i in (%origindir%\*) do (
	if exist "%%~ni.%%~xi" del /q "%%~ni.%%~xi"
	mklink "%%~ni.%%~xi" "%%i" >nul 2>nul
)

if not [%errorlevel%]==[0] (
	echo Something went wrong, try re-running the script as admin.
) else (
	echo Installation successful^^!
)

goto:finish


:finish
pause
cls
goto:eof