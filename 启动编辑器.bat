@echo off
rem Open project in Godot 4.7.2 editor
cd /d "%~dp0"
start "" "D:\Godot\Godot_v4.7.2-stable_win64.exe" --editor --path "%CD%"
