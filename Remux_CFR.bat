@echo off
setlocal enabledelayedexpansion
REM ============================================================================
REM Remux_CFR.bat — SINGLE-FILE MKV -> MP4 REMUX (NEW FILE)
REM   Original: Remux.bat (left untouched per request)
REM   Updated: 2026-08-19 — Fast defaults + log capturing (USE_FASTSTART=0)
REM   Features same as RemuxDirectory_CFR.bat:
REM     - Generic FPS, Force CFR, sampled vfrdet, mov_text, no overwrite
REM ============================================================================

chcp 65001 >nul 2>&1

REM --- Fast Defaults ---
set "VFRDET_MODE=sample"
set "VFRDET_FRAMES=2000"
set "USE_FASTSTART=0"
set "LOG_TIMINGS=1"

set "LOG_DIR=%~dp0logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'"') do set "LOG_STAMP=%%T"
set "LOG_FILE=%LOG_DIR%\%LOG_STAMP%.txt"
echo [%date% %time%] === Remux_CFR Start VFRDET_MODE=%VFRDET_MODE% USE_FASTSTART=%USE_FASTSTART% === > "%LOG_FILE%" 2>&1

echo === Remux CFR Single File + Subs + Faststart=%USE_FASTSTART% (no overwrite) ===
echo === Log: %LOG_FILE% ===
echo [%date% %time%] Start single file >> "%LOG_FILE%" 2>&1

where ffmpeg >nul 2>&1
if errorlevel 1 (
  echo ERROR: ffmpeg not found in PATH.
  echo ERROR ffmpeg not found >> "%LOG_FILE%" 2>&1
  pause
  exit /b 1
)
where ffprobe >nul 2>&1
if errorlevel 1 (
  echo ERROR: ffprobe not found in PATH.
  echo ERROR ffprobe not found >> "%LOG_FILE%" 2>&1
  pause
  exit /b 1
)

REM ---- get input: drag-drop arg wins, else prompt ----
set "INPUT=%~1"
if not "%~1"=="" (
  echo Input via drag-drop: "%~1"
  echo Input drag-drop "%~1" >> "%LOG_FILE%" 2>&1
) else (
  set /p INPUT=Enter file name ^(drag file here or type path^): 
)
set "INPUT=%INPUT:"=%"

if "%INPUT%"=="" (
  echo No file given.
  echo No file given >> "%LOG_FILE%" 2>&1
  pause
  exit /b 1
)
if not exist "%INPUT%" (
  echo ERROR: File not found: "%INPUT%"
  echo Not found "%INPUT%" >> "%LOG_FILE%" 2>&1
  pause
  exit /b 1
)

set "INDIR=%~dp1"
set "INNAME=%~n1"
set "INEXT=%~x1"
if "%~x1"=="" (
  for %%P in ("%INPUT%") do (
    set "INDIR=%%~dpP"
    set "INNAME=%%~nP"
    set "INEXT=%%~xP"
  )
)
if "!INDIR!"=="" set "INDIR=%CD%\"
set "OUTFILE=!INDIR!!INNAME!.mp4"

echo Input : "%INPUT%"
echo Output: "!OUTFILE!"
echo Input "%INPUT%" Output "!OUTFILE!" >> "%LOG_FILE%" 2>&1

if exist "!OUTFILE!" (
  echo SKIP: "!OUTFILE!" already exists ^(no overwrite policy^)
  echo SKIP exists >> "%LOG_FILE%" 2>&1
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
echo FPS !FPS! NUM=!NUM! DEN=!DEN! >> "%LOG_FILE%" 2>&1

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
  echo Bitmap subs detected >> "%LOG_FILE%" 2>&1
)

REM ---- VFR warn (sampled, only if header mismatch) ----
set "RFR="
for /f "delims=" %%R in ('ffprobe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of default^=nw^=1:nk^=1 "!INPUT!" 2^>^&1') do set "RFR=%%R"
set "DO_VFRDET=0"
if not "!FPS!"=="!RFR!" (
  echo NOTE: Header mismatch r_frame_rate=!RFR! vs avg=!FPS! - possible VFR
  echo Header mismatch !RFR! vs !FPS! >> "%LOG_FILE%" 2>&1
  set "DO_VFRDET=1"
) else (
  echo Header OK, skip vfrdet per fast path
  echo Header OK skip vfrdet >> "%LOG_FILE%" 2>&1
)

if "!DO_VFRDET!"=="1" (
  if "!VFRDET_MODE!"=="off" (
    echo SKIP vfrdet per VFRDET_MODE=off
    echo SKIP vfrdet off >> "%LOG_FILE%" 2>&1
  ) else (
    set "VFR_LOG=%TEMP%\vfr_single.log"
    if "%LOG_TIMINGS%"=="1" echo [%time%] vfrdet start mode=!VFRDET_MODE! frames=!VFRDET_FRAMES! >> "%LOG_FILE%" 2>&1
    if "!VFRDET_MODE!"=="sample" (
      ffmpeg -v info -i "!INPUT!" -vf vfrdet -frames:v !VFRDET_FRAMES! -an -f null - >"!VFR_LOG!" 2>&1
    ) else (
      ffmpeg -v info -i "!INPUT!" -vf vfrdet -an -f null - >"!VFR_LOG!" 2>&1
    )
    if "%LOG_TIMINGS%"=="1" echo [%time%] vfrdet done >> "%LOG_FILE%" 2>&1
    findstr /C:"VFR:" "!VFR_LOG!" >nul 2>&1
    if not errorlevel 1 (
      for /f "tokens=*" %%L in ('findstr /C:"VFR:" "!VFR_LOG!"') do (
        echo   %%L
        echo   %%L >> "%LOG_FILE%" 2>&1
        echo   %%L | findstr /R "VFR:0\.000000" >nul 2>&1
        if errorlevel 1 (
          echo WARNING: VFR/jitter detected - forcing CFR will rewrite timestamps
          echo WARNING VFR jitter >> "%LOG_FILE%" 2>&1
        )
      )
    )
    del "!VFR_LOG!" >nul 2>&1
  )
)

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
set "MOVFLAGS="
if "!USE_FASTSTART!"=="1" set "MOVFLAGS=-movflags +faststart"
if "!MOVFLAGS!"=="" (
  echo CFR fix: !CFR_DESC! !VTAG! -fps_mode passthrough ^(faststart OFF^)
) else (
  echo CFR fix: !CFR_DESC! !VTAG! -fps_mode passthrough !MOVFLAGS!
)
echo CFR !CFR_DESC! !VTAG! !MOVFLAGS! >> "%LOG_FILE%" 2>&1

REM ---- remux ----
if "%LOG_TIMINGS%"=="1" echo [%time%] remux start >> "%LOG_FILE%" 2>&1
echo Remuxing...
set "FFLOG=%TEMP%\ffmpeg_single.log"
ffmpeg -hide_banner -loglevel error -i "!INPUT!" -map 0:v -map 0:a -map 0:s? -map_metadata 0 -c:v copy -c:a copy -c:s mov_text !CFR_ARGS! !VTAG! -fps_mode passthrough !MOVFLAGS! -n "!OUTFILE!" > "!FFLOG!" 2>&1
set "FFERR=!errorlevel!"
type "!FFLOG!"
type "!FFLOG!" >> "%LOG_FILE%" 2>&1
del "!FFLOG!" >nul 2>&1
if "%LOG_TIMINGS%"=="1" echo [%time%] remux done err=!FFERR! >> "%LOG_FILE%" 2>&1

if !FFERR! NEQ 0 (
  echo First pass failed - retrying without subtitles ^(bitmap subs^)...
  echo Retry without subs err=!FFERR! >> "%LOG_FILE%" 2>&1
  set "FFLOG2=%TEMP%\ffmpeg_single_retry.log"
  ffmpeg -hide_banner -loglevel error -i "!INPUT!" -map 0:v -map 0:a -map_metadata 0 -c:v copy -c:a copy !CFR_ARGS! !VTAG! -fps_mode passthrough !MOVFLAGS! -sn -n "!OUTFILE!" > "!FFLOG2!" 2>&1
  set "FFERR2=!errorlevel!"
  type "!FFLOG2!"
  type "!FFLOG2!" >> "%LOG_FILE%" 2>&1
  del "!FFLOG2!" >nul 2>&1
  if !FFERR2! NEQ 0 (
    echo FAILED: remux failed. Audio codec may be incompatible ^(opus/flac^). Try -c:a aac
    echo FAILED >> "%LOG_FILE%" 2>&1
    pause
    exit /b 1
  ) else (
    echo SUCCESS ^(without subs^): "!OUTFILE!" ^[CFR !NUM!/!DEN! tscale !TSCALE!!VTAG!^]
    echo SUCCESS without subs >> "%LOG_FILE%" 2>&1
  )
) else (
  echo SUCCESS: "!OUTFILE!" ^[CFR !NUM!/!DEN! tscale !TSCALE!!VTAG!^]
  echo SUCCESS "!OUTFILE!" >> "%LOG_FILE%" 2>&1
)

echo Log: %LOG_FILE%
echo [%date% %time%] Done >> "%LOG_FILE%" 2>&1
pause
endlocal
exit /b 0





