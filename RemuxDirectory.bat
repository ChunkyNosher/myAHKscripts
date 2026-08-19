@echo off & setlocal enabledelayedexpansion
for %%v in ("*.mkv") do (
  set FileName=%%v

  ffmpeg -i "!FileName!" -c copy -map 0:v -map 0:a "!FileName:~0,-4!.mp4"
)
pause