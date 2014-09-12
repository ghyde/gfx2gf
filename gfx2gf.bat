@echo off
:: gfx2gf.bat v1.5 (20140823)
:: by Jeremy Williams
::
:: This batch file converts graphics for Game Frame compatibility (www.ledseq.com).
:: *** You must have ImageMagick installed for it to run (www.imagemagick.org) ***
:: Passed graphic files will be stretched, resized, & resampled if larger than 16x16. If
:: the file is an animated GIF, a filmstrip graphic will be generated along with 
:: a CONFIG.INI using a "hold" value (framerate) equal to the first frame of the
:: animation. Usually this works well, but you may still need to adjust the hold
:: value if the animation plays too slow/fast.

:: simple check for ImageMagick installation
convert > nul
if %ERRORLEVEL%==9009 GOTO NOMAGICK
if "%~1" == "" GOTO NOFILE

:: make folders
set GRAPHIC=%~f1
set FOLDER=%~n1
mkdir "%FOLDER%"
mkdir "%FOLDER%\temp"

:: store source resolution (not necessary?)
set WIDTH=0
set HEIGHT=0
for /f "tokens=*" %%w in ('identify -format "%%w" "%GRAPHIC%[0]"') do set WIDTH=%%w
for /f "tokens=*" %%h in ('identify -format "%%h" "%GRAPHIC%[0]"') do set HEIGHT=%%h

:: convert to BMP and extract animated GIF into seperate files
echo Converting "%~nx1" to Game Frame format...
echo -----
ffmpeg -an -r 1 -i "%GRAPHIC%" -r 1 -f image2 -pix_fmt bgr24 -s 16x16 "%FOLDER%\temp\%%06d.bmp"
echo -----
:: count the number of frames
set SCENES=0
for %%x in ("%FOLDER%\temp\*") do set /a SCENES+=1
echo %SCENES% 16x16 frame(s) created.

if %SCENES% GTR 196000 (echo File has more than 196000 frames. This might not work.)
if %SCENES% GTR 1999 (
	set NESTED=1
	) else (
	set NESTED=0
	)

if %SCENES% == 1 (
	montage "%FOLDER%\temp\*.bmp" -mode concatenate -tile 1x -type truecolor "%FOLDER%\0.bmp"
	echo Graphic conversion finished!
	goto MAKEPREVIEW
	)

:FILMSTRIP

:: combine multiple files into one long filmstrip
echo Creating filmstrip...
montage "%FOLDER%\temp\*.bmp" -mode concatenate -tile 1x -type truecolor "%FOLDER%\0.bmp"
echo Filmstrip conversion finished!

:: store the delay used for the first frame of animation in the animated GIF
set HOLD=0
for /f "tokens=*" %%a in ('identify -format "%%T" "%GRAPHIC%[0]"') do set HOLD=%%a
:: GF frame rate bottoms out around 40
if %HOLD% LSS 4 (set HOLD=4)
set /A HOLD = HOLD * 10

if %SCENES% == 1 (GOTO NOTANIMATED)
if %SCENES% gtr 1 (echo hold value: %HOLD%)
GOTO MAKEINI

:BUILDNEST

echo Long video detected; nesting folders.
convert -crop 16x32000x0x0 "%FOLDER%\0.bmp" "%FOLDER%\%%01d.bmp"
set STRIPS=0
for %%x in ("%FOLDER%\*.bmp") do set /a STRIPS+=1
echo %STRIPS% filmstrips created.
set CURRENTNEST=0

:ITERATE
if %CURRENTNEST% LSS %STRIPS% (
	echo Making nested folder %CURRENTNEST% 
	mkdir "%FOLDER%\%CURRENTNEST%"
	move "%FOLDER%\%CURRENTNEST%.bmp" "%FOLDER%\%CURRENTNEST%\0.bmp"
	copy "%FOLDER%\config.ini" "%FOLDER%\%CURRENTNEST%"
	set /A CURRENTNEST=%CURRENTNEST% + 1
	goto ITERATE
	)

del /Q "%FOLDER%\config.ini"
echo Nesting folders complete.
goto END

:MAKEINI

cd %folder%

:: write config.ini using stored delay value
echo # All of these settings are optional. >> config.ini
echo # If this file doesn’t exist, or if >> config.ini
echo # settings don’t appear in this file, >> config.ini
echo # Game Frame will use default values. >> config.ini
echo. >> config.ini
echo [animation] >> config.ini
echo. >> config.ini
echo # milliseconds to hold each frame >> config.ini
echo # (1000 = 1 sec; lower is faster) >> config.ini
echo hold = %HOLD% >> config.ini
echo. >> config.ini
echo # should the animation loop? If false, >> config.ini
echo # system will progress to next folder >> config.ini
echo # after the last frame is displayed. >> config.ini
echo loop = true >> config.ini
echo. >> config.ini
echo [translate] >> config.ini
echo. >> config.ini
echo # move the animation across the screen >> config.ini
echo # this many pixels per frame. Experiment >> config.ini
echo # with positive and negative numbers for >> config.ini
echo # different directions. >> config.ini
echo moveX = 0 >> config.ini
echo moveY = 16 >> config.ini
echo. >> config.ini
echo # should the movement loop? >> config.ini
if %NESTED% == 0 (
	echo loop = true >> config.ini
	) else (
	echo loop = false >> config.ini
	)
echo. >> config.ini
echo # begin/end scroll off screen? >> config.ini
echo panoff = false >> config.ini
echo. >> config.ini
echo # optionally dictate the next animation >> config.ini
echo # EXAMPLE: nextFolder = mspacman >> config.ini
echo # nextFolder = defend1 >> config.ini

cd ..
echo CONFIG.INI Written!
GOTO MAKEPREVIEW

:MAKEPREVIEW
echo Generating preview...
if %SCENES% LEQ 1 (
	convert -filter box -resize 128x128 "%FOLDER%\temp\*.bmp" "%FOLDER%\%FOLDER%_preview.gif"
	echo Done!
	goto CLEANUP
	)
set /A DELAY=%HOLD%/10
if %SCENES% GEQ 2 (if %SCENES% leq 250 (convert -delay %DELAY% -filter box -resize 128x128 "%FOLDER%\temp\*.bmp" "%FOLDER%\%FOLDER%_preview.gif"))
:: only use the first 250 frames
if %SCENES% GTR 250 (echo Long animation; only previewing the first 250 frames...)
if %SCENES% GTR 250 (convert -delay %DELAY% -filter box -resize 128x128 "%FOLDER%\temp\%%06d.bmp[1-250]" "%FOLDER%\%FOLDER%_preview.gif")

:CLEANUP
rmdir /s /q "%FOLDER%\temp"
if %NESTED% == 1 (goto BUILDNEST)
goto END

:: exits
:NOMAGICK
echo.
echo This program requires ImageMagick (www.imagemagick.org) 
echo to be installed on the system. Make it so.
goto END
:NOTANIMATED
echo File is not animated. Bypassing CONFIG.INI.
goto MAKEPREVIEW
:FILENOTFOUND
echo ERROR: File not found! (Did you type the file extension?)
goto NOFILE
:NOFILE
echo Need input! Drag a graphic onto the .bat file, 
echo or run it from a command prompt as:
echo.
echo gfx2gf yourfile.gif
echo.
GOTO END
:GRAPHICEXISTS
echo 0.bmp already exists! Aborting.
GOTO END
:CONFIGEXISTS
echo CONFIG.INI already exists; not creating.
GOTO MAKEPREVIEW
:END
echo Process finished!
pause