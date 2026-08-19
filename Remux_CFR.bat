@echo off
setlocal enabledelayedexpansion
REM ============================================================================
REM Remux_CFR.bat — SINGLE-FILE MKV -> MP4 REMUX (NEW FILE)
REM   Original: Remux.bat (left untouched per request)
REM   Purpose : Same CFR + subtitle fixes as RemuxDirectory_CFR.bat but for
REM             one file (prompt or drag-and-drop).
REM
REM   FEATURES (see RemuxDirectory_CFR.bat header for details):
REM     - Generic FPS: any 23.976/29.97/59.94/24/25/30/60/any via ffprobe
REM       Integer FPS: -video_track_timescale only -> VFR 0.000
REM       NTSC FPS: + setts BSF -> VFR ~0.06 vs 0.57 without (0.000 if no B-frames)
REM     - Force CFR, warn if true VFR (vfrdet + r/avg mismatch)
REM     - Subtitles: text -> mov_text, bitmap PGS/VobSub dropped with warning
REM     - Optimizations: -fps_mode passthrough -movflags +faststart -tag:v hvc1
REM     - No overwrite (-n)
REM   USAGE:
REM     - Drag & drop an .mkv onto this .bat, OR
REM     - Double-click and enter file name when prompted
REM   REQUIREMENTS: ffmpeg + ffprobe in PATH
REM ============================================================================

chcp 65001 >nul 2>&1
echo === Remux CFR Single File + Subs + Faststart (no overwrite) ===

where ffmpeg >nul 2>&1
if errorlevel 1 (
  echo ERROR: ffmpeg not found in PATH.
  pause
  exit /b 1
)
where ffprobe >nul 2>&1
if errorlevel 1 (
  echo ERROR: ffprobe not found in PATH.
  pause
  exit /b 1
)

REM ---- get input: drag-drop arg wins, else prompt ----
set "INPUT=%~1"
if not "%~1"=="" (
  echo Input via drag-drop: "%~1"
) else (
  set /p INPUT=Enter file name ^(drag file here or type path^): 
)

REM strip surrounding quotes that set /p may have captured
set "INPUT=%INPUT:"=%"

if "%INPUT%"=="" (
  echo No file given.
  pause
  exit /b 1
)

REM allow "file.mkv" entered with or without quotes and with spaces
if not exist "%INPUT%" (
  echo ERROR: File not found: "%INPUT%"
  pause
  exit /b 1
)

REM split dir/name/ext for robust output path (handles "my file.name.mkv")
set "INDIR=%~dp1"
set "INNAME=%~n1"
set "INEXT=%~x1"
REM if we came via prompt, %~dp1 etc are empty, so fallback to parsing INPUT
if "%~x1"=="" (
  for %%P in ("%INPUT%") do (
    set "INDIR=%%~dpP"
    set "INNAME=%%~nP"
    set "INEXT=%%~xP"
  )
)

REM normalize INDIR - if empty, use current dir
if "!INDIR!"=="" set "INDIR=%CD%\"

set "OUTFILE=!INDIR!!INNAME!.mp4"

echo Input : "%INPUT%"
echo Output: "!OUTFILE!"

if exist "!OUTFILE!" (
  echo SKIP: "!OUTFILE!" already exists ^(no overwrite policy^)
  pause
  exit /b 0
)

REM ---- probe FPS (generic) ----
set "FPS="
set "NUM="
set "DEN="
for /f "delims=" %%F in ('ffprobe -v error -select_streams v:0 -show_entries stream^=avg_frame_rate -of default^=nw^=1:nk^=1 "!INPUT!" 2^>^&1') do set "FPS=%%F"
if "!FPS!"=="" set "FPS=0/0"
if "!FPS!"=="0/0" (
  for /f "delims=" %%F in ('ffprobe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of default^=nw^=1:nk^=1 "!INPUT!" 2^>^&1') do set "FPS=%%F"
)
if "!FPS!"=="N/A" (
  for /f "delims=" %%F in ('ffprobe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of default^=nw^=1:nk^=1 "!INPUT!" 2^>^&1') do set "FPS=%%F"
)
if "!FPS!"=="" set "FPS=30/1"
if "!FPS!"=="N/A" set "FPS=30/1"
if "!FPS!"=="0/0" set "FPS=30/1"

for /f "tokens=1,2 delims=/" %%A in ("!FPS!") do (
  set "NUM=%%A"
  set "DEN=%%B"
)
if "!NUM!"=="" set "NUM=30"
if "!DEN!"=="" set "DEN=1"
if "!NUM!"=="0" set "NUM=30"
if "!DEN!"=="0" set "DEN=1"

echo Detected FPS: !FPS! ^(NUM=!NUM! DEN=!DEN!^)

REM ---- HEVC tag ----
set "VCODEC="
for /f "delims=" %%C in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=nw^=1:nk^=1 "!INPUT!" 2^>^&1') do set "VCODEC=%%C"
set "VTAG="
if /i "!VCODEC!"=="hevc" set "VTAG=-tag:v hvc1"
if /i "!VCODEC!"=="h265" set "VTAG=-tag:v hvc1"

REM ---- bitmap subtitle warning ----
ffprobe -v error -select_streams s -show_entries stream=codec_name -of csv=p=0 "!INPUT!" 2>nul | findstr /i "hdmv_pgs dvd_subtitle dvb_subtitle dvb_teletext" >nul 2>&1
if not errorlevel 1 (
  echo NOTE: Bitmap subtitles detected ^(PGS/VobSub^) - will be dropped in MP4.
  echo       To keep them, burn with -vf subtitles ^(re-encode^) or OCR externally.
)

REM ---- VFR warn ----
set "RFR="
for /f "delims=" %%R in ('ffprobe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of default^=nw^=1:nk^=1 "!INPUT!" 2^>^&1') do set "RFR=%%R"
if not "!FPS!"=="!RFR!" (
  echo NOTE: Header mismatch r_frame_rate=!RFR! vs avg=!FPS! - possible VFR
)
set "VFR_LOG=%TEMP%\vfr_single.log"
ffmpeg -v info -i "!INPUT!" -vf vfrdet -an -f null - >"!VFR_LOG!" 2>&1
findstr /C:"VFR:" "!VFR_LOG!" >nul 2>&1
if not errorlevel 1 (
  for /f "tokens=*" %%L in ('findstr /C:"VFR:" "!VFR_LOG!"') do (
    echo   %%L
    echo   %%L | findstr /R "VFR:0\.000000" >nul 2>&1
    if errorlevel 1 (
      echo WARNING: VFR/jitter detected - forcing CFR will rewrite timestamps via setts+timescale
      echo          If true VFR ^(phone/screen^), use re-encode: -vf fps=!NUM!/!DEN! -fps_mode cfr
    )
  )
)
del "!VFR_LOG!" >nul 2>&1

REM ---- build CFR args ----
set "TSCALE=!NUM!"
set /a TNUM=!NUM! 2>nul
if !TNUM! GTR 90000 set "TSCALE=60000"
set "CFR_ARGS=-video_track_timescale !TSCALE!"
set "CFR_DESC=-video_track_timescale !TSCALE! (integer CFR)"
if not "!DEN!"=="1" (
  set "CFR_ARGS=-bsf:v setts=time_base=1/!NUM!:ts=N*!DEN!:duration=!DEN!:prescale=1 -video_track_timescale !TSCALE!"
  set "CFR_DESC=-bsf:v setts=time_base=1/!NUM!:ts=N*!DEN!:duration=!DEN!:prescale=1 -video_track_timescale !TSCALE! (NTSC CFR)"
)

echo CFR fix: !CFR_DESC! !VTAG! -fps_mode passthrough
echo Subtitles: text -^> mov_text, faststart on

REM ---- remux ----
ffmpeg -hide_banner -loglevel error -i "!INPUT!" -map 0:v -map 0:a -map 0:s? -map_metadata 0 -c:v copy -c:a copy -c:s mov_text !CFR_ARGS! !VTAG! -fps_mode passthrough -movflags +faststart -n "!OUTFILE!"

if errorlevel 1 (
  echo First pass failed - retrying without subtitles ^(bitmap subs^)...
  ffmpeg -hide_banner -loglevel error -i "!INPUT!" -map 0:v -map 0:a -map_metadata 0 -c:v copy -c:a copy !CFR_ARGS! !VTAG! -fps_mode passthrough -movflags +faststart -sn -n "!OUTFILE!"
  if errorlevel 1 (
    echo FAILED: remux failed. Audio codec may be incompatible ^(opus/flac^). Try manual: -c:a aac
    pause
    exit /b 1
  ) else (
    echo SUCCESS ^(without subs^): "!OUTFILE!" ^[CFR !NUM!/!DEN! tscale !TSCALE!!VTAG!^]
  )
) else (
  echo SUCCESS: "!OUTFILE!" ^[CFR !NUM!/!DEN! tscale !TSCALE!!VTAG!^]
)

echo.
echo Verify: MediaInfo should show "Frame rate mode: Constant"
echo         ffprobe -select_streams v:0 -show_entries stream^=avg_frame_rate,r_frame_rate "!OUTFILE!"
pause
endlocal
exit /b 0
