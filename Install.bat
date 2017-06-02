@echo off
SetLocal EnableDelayedExpansion

if not [%1]==[] (
	set gamedir=%1
	goto:make_copies
)

cls

echo.
echo Welcome to the Magic ENB installation script^^!
echo.
echo You can also run the installation directly passing the folder location, like 
echo 'install "C:\Program Files\Steam\steamapps\common\Skyrim Special Edition"'
echo.
echo THIS WILL REPLACE ANY PREVIOUS PRESET PRESENT IN THE GAME FOLDER
echo.
:input_gamedir
echo Please type the game directory location, such as:
echo "C:\Program Files\Steam\steamapps\common\Skyrim Special Edition"
echo Without quotes, please. (the "")
echo Or if you'd like to quit, just press enter without typing anything.
echo.
set /p gamedir=Game directory: 
echo.

if ["%gamedir%"]==[""] (
	echo Okay, quitting...
	goto:eof
)

echo Selected directory: "%gamedir%"
set /p confirm=Are you sure you want to proceed with the installation? (y/n): 
if /i not ["%confirm%"]==["y"] (
	echo Okay, quitting...
	goto:eof
)
echo.

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
if [%type%]==[3] goto:eof
::else
echo.
echo Invalid choice, please type 1 or 2 for the wanted choice!
echo.
goto:choice


:make_copies
robocopy "enb" "%gamedir%" /copy:dat /e >nul
echo Installation successful^^!
goto:eof

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
