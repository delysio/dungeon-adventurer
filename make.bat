@echo off
@setlocal
@set PATH=%PATH%;F:\!_emulacja\AtariXE\Scene\_Moje\Maze\
@set PATH=%PATH%;F:\!_emulacja\AtariXE\Scene\_Moje\Maze\output

REM -------------------- Delete old files

del dungeon_adventurer.xex

REM -------------------- Process levels

python python/find_items.py

echo Item tables generated.

python python/remove_new_lines.py

echo Levels compacted.

python python/pak_levels.py

echo Levels packed

REM -------------------- Process ATASCII text 

python python/convert_all_strings.py

echo All ATASCII files processed

REM -------------------- Pack assets

apultra.exe graphics\death.fnt graphics\death_font.pak
apultra.exe graphics\death.scr graphics\death_data.pak
apultra.exe graphics\dungeon_adventurer.fnt graphics\title_font.pak
apultra.exe graphics\dungeon_adventurer.scr graphics\title_data.pak
apultra.exe graphics\panel.dat graphics\panel.pak
apultra.exe graphics\text_font.fnt graphics\text_font.pak
apultra.exe graphics\mazefont.fnt graphics\maze_font.pak
apultra.exe graphics\end_story.dat graphics\end_story.pak
apultra.exe graphics\game_over_text.dat graphics\game_over_text.pak
apultra.exe graphics\instruction_text_page_1.dat graphics\instruction_text_page_1.pak
apultra.exe graphics\instruction_text_page_2.dat graphics\instruction_text_page_2.pak

echo Assets compacted.

REM -------------------- Compile

mp.exe Maze.pas -code:2000 

if %ERRORLEVEL% == 0 goto :MADS

echo Mad Pascal gives errors (%errorlevel%). Compilation unsuccesful.
goto :END

REM -------------------- Assembly

:MADS
mads.exe Maze.a65 -x -i:base\ -t -l -o:dungeon_adventurer.xex

if %ERRORLEVEL% == 0 goto :RUN

echo MADS gives errors (%errorlevel%). Compilation unsuccesful.
goto :END

REM -------------------- RUN

:RUN
pause

start dungeon_adventurer.xex

:END