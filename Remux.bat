@echo off & setlocal enabledelayexpansion
set /p name=Enter file name: 
ffmpeg -i "%name%" -c copy -map 0:v -map 0:a "!name:~0,-4!.mp4"
pause