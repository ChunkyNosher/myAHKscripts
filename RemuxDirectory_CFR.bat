@echo off
setlocal enabledelayedexpansion
REM ============================================================================
REM RemuxDirectory_CFR.bat  —  LOSSLESS MKV -> MP4 REMUX (NEW FILE)
REM   Original: RemuxDirectory.bat  (left untouched per request)
REM   Purpose : Fix CFR->VFR bug + add MP4-compatible subtitles + optimizations
REM   Updated: 2026-08-19 — Fast defaults + log capturing (USE_FASTSTART=0)
REM
REM   WHAT IT DOES:
REM     - Remuxes every *.mkv in current directory to *.mp4 via stream copy
REM       (no re-encode, no quality loss, fast)
REM     - Generic FPS handling: works for ANY fps including non-integers
REM       23.976 (24000/1001), 29.97 (30000/1001), 59.94 (60000/1001),
REM       24/25/30/50/60 and arbitrary values like 23.976024... etc.
REM       Uses ffprobe avg_frame_rate -> -video_track_timescale (+ setts for NTSC)
REM     - Forces CFR (corrects MKV 1ms TimecodeScale jitter vs MP4 rational
REM       timebase). Integer FPS (30/1, 60/1): only timescale -> VFR 0.000
REM       NTSC FPS (24000/1001 etc): + setts BSF to rewrite timestamps
REM     - Warns if source is true VFR (header mismatch + sampled vfrdet)
REM     - Converts text subtitles (srt/ass/ssa/mov_text) -> mov_text (MP4 only)
REM       Bitmap subs (hdmv_pgs_subtitle/vobsub) -> auto-dropped with warning
REM     - Optimizations: -map 0:v/0:a/0:s? -c:v copy -c:a copy -c:s mov_text
REM       -fps_mode passthrough -tag:v hvc1 for HEVC, faststart OPTIONAL
REM     - No overwrite (-n): skips if .mp4 already exists
REM ============================================================================

chcp 65001 >nul 2>&1

REM --- Fast Defaults (change here if needed) ---
set "VFRDET_MODE=sample"
set "VFRDET_FRAMES=2000"
set "USE_FASTSTART=0"
set "LOG_TIMINGS=1"

REM --- Log setup (timestamped file in .\logs\) ---
set "LOG_DIR=%~dp0logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'"') do set "LOG_STAMP=%%T"
set "LOG_FILE=%LOG_DIR%\%LOG_STAMP%.txt"
echo [%date% %time%] === RemuxDirectory_CFR Start VFRDET_MODE=%VFRDET_MODE% VFRDET_FRAMES=%VFRDET_FRAMES% USE_FASTSTART=%USE_FASTSTART% === > "%LOG_FILE%" 2>&1
echo [%date% %time%] WorkingDir: %CD% >> "%LOG_FILE%" 2>&1

echo.
echo === RemuxDirectory CFR + Subs + Faststart=%USE_FASTSTART% (no overwrite) ===
echo === Log: %LOG_FILE% ===
echo.
echo [%date% %time%] === RemuxDirectory CFR Start === >> "%LOG_FILE%" 2>&1

REM --- sanity checks ---
where ffmpeg >nul 2>&1
if errorlevel 1 (
  echo ERROR: ffmpeg not found in PATH. Install ffmpeg and add to PATH.
  echo [%date% %time%] ERROR ffmpeg not found >> "%LOG_FILE%" 2>&1
  pause
  exit /b 1
)
where ffprobe >nul 2>&1
if errorlevel 1 (
  echo ERROR: ffprobe not found in PATH. Install ffmpeg full build.
  echo [%date% %time%] ERROR ffprobe not found >> "%LOG_FILE%" 2>&1
  pause
  exit /b 1
)

if not exist "*.mkv" (
  echo No *.mkv files found in current directory.
  echo [%date% %time%] No MKVs found >> "%LOG_FILE%" 2>&1
  pause
  exit /b 0
)

set "SUCCESS=0"
set "SKIPPED=0"
set "FAILED=0"
set "WARNED=0"

for %%I in ("*.mkv") do (
  echo ------------------------------------------------------------
  echo [%time%] Processing: "%%~nxI"
  echo [%time%] Processing: "%%~nxI" >> "%LOG_FILE%" 2>&1

  REM ---- no overwrite ----
  if exist "%%~nI.mp4" (
    echo SKIP: "%%~nI.mp4" already exists ^(no overwrite policy^)
    echo [%time%] SKIP exists "%%~nI.mp4" >> "%LOG_FILE%" 2>&1
    set /a SKIPPED+=1
    echo. >> "%LOG_FILE%" 2>&1
    echo.
  ) else (
    if "%LOG_TIMINGS%"=="1" echo [%time%] START "%%~nxI" >> "%LOG_FILE%" 2>&1

    REM ---- probe FPS (generic, handles any num/den including non-integers) ----
    set "FPS="
    set "NUM="
    set "DEN="
    for /f "delims=" %%F in ('ffprobe -v error -select_streams v:0 -show_entries stream^=avg_frame_rate -of default^=nw^=1:nk^=1 "%%~I" 2^>^&1') do set "FPS=%%F"
    if "!FPS!"=="" set "FPS=0/0"
    if "!FPS!"=="0/0" (
      for /f "delims=" %%F in ('ffprobe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of default^=nw^=1:nk^=1 "%%~I" 2^>^&1') do set "FPS=%%F"
    )
    if "!FPS!"=="N/A" (
      for /f "delims=" %%F in ('ffprobe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of default^=nw^=1:nk^=1 "%%~I" 2^>^&1') do set "FPS=%%F"
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

    echo  Detected FPS: !FPS! ^(NUM=!NUM! DEN=!DEN!^)
    echo  Detected FPS: !FPS! ^(NUM=!NUM! DEN=!DEN!^) >> "%LOG_FILE%" 2>&1

    REM ---- probe video codec for HEVC tag fix ----
    set "VCODEC="
    for /f "delims=" %%C in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=nw^=1:nk^=1 "%%~I" 2^>^&1') do set "VCODEC=%%C"
    set "VTAG="
    if /i "!VCODEC!"=="hevc" set "VTAG=-tag:v hvc1"
    if /i "!VCODEC!"=="h265" set "VTAG=-tag:v hvc1"

    REM ---- subtitle type check (warn for bitmap subs) ----
    ffprobe -v error -select_streams s -show_entries stream=codec_name -of csv=p=0 "%%~I" 2>nul | findstr /i "hdmv_pgs dvd_subtitle dvb_subtitle dvb_teletext" >nul 2>&1
    if not errorlevel 1 (
      echo  NOTE: Bitmap subtitles detected ^(PGS/VobSub^) - MP4 only supports mov_text.
      echo  NOTE: Bitmap subs detected >> "%LOG_FILE%" 2>&1
      set /a WARNED+=1
    )

    REM ---- VFR detection: tier 1 header mismatch (fast, no decode) ----
    set "RFR="
    for /f "delims=" %%R in ('ffprobe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of default^=nw^=1:nk^=1 "%%~I" 2^>^&1') do set "RFR=%%R"
    set "DO_VFRDET=0"
    if not "!FPS!"=="!RFR!" (
      echo  NOTE: Header mismatch r_frame_rate=!RFR! vs avg_frame_rate=!FPS! - possible VFR
      echo  Header mismatch !RFR! vs !FPS! >> "%LOG_FILE%" 2>&1
      set "DO_VFRDET=1"
    ) else (
      echo  Header OK ^(r == avg^), skip vfrdet per fast path
      echo  Header OK skip vfrdet >> "%LOG_FILE%" 2>&1
    )

    REM ---- tier 2: vfrdet filter (sampled, only if needed) ----
    if "!DO_VFRDET!"=="1" (
      if "!VFRDET_MODE!"=="off" (
        echo  SKIP vfrdet per VFRDET_MODE=off
        echo  SKIP vfrdet off >> "%LOG_FILE%" 2>&1
      ) else (
        set "VFR_LOG=%TEMP%\vfr_%%~nI.log"
        if "%LOG_TIMINGS%"=="1" echo [%time%] vfrdet start mode=!VFRDET_MODE! frames=!VFRDET_FRAMES! >> "%LOG_FILE%" 2>&1
        if "!VFRDET_MODE!"=="sample" (
          ffmpeg -v info -i "%%~I" -vf vfrdet -frames:v !VFRDET_FRAMES! -an -f null - >"!VFR_LOG!" 2>&1
        ) else (
          ffmpeg -v info -i "%%~I" -vf vfrdet -an -f null - >"!VFR_LOG!" 2>&1
        )
        if "%LOG_TIMINGS%"=="1" echo [%time%] vfrdet done >> "%LOG_FILE%" 2>&1
        findstr /C:"VFR:" "!VFR_LOG!" >nul 2>&1
        if not errorlevel 1 (
          for /f "tokens=*" %%L in ('findstr /C:"VFR:" "!VFR_LOG!"') do (
            echo    %%L
            echo    %%L >> "%LOG_FILE%" 2>&1
            echo    %%L | findstr /R "VFR:0\.000000" >nul 2>&1
            if errorlevel 1 (
              echo  WARNING: VFR/jitter detected in "%%~nxI" - forcing CFR will rewrite timestamps
              echo  WARNING VFR jitter "%%~nxI" >> "%LOG_FILE%" 2>&1
              set /a WARNED+=1
            )
          )
        )
        del "!VFR_LOG!" >nul 2>&1
      )
    )

    REM ---- build CFR fix args (generic for ANY fps) ----
    set "TSCALE=!NUM!"
    set /a TNUM=!NUM! 2>nul
    if !TNUM! GTR 90000 set "TSCALE=60000"
    set "CFR_ARGS=-video_track_timescale !TSCALE!"
    set "CFR_DESC=-video_track_timescale !TSCALE! (integer CFR, VFR 0.000)"
    if not "!DEN!"=="1" (
      set "CFR_ARGS=-bsf:v setts=time_base=1/!NUM!:ts=N*!DEN!:duration=!DEN!:prescale=1 -video_track_timescale !TSCALE!"
      set "CFR_DESC=-bsf:v setts=time_base=1/!NUM!:ts=N*!DEN!:duration=!DEN!:prescale=1 -video_track_timescale !TSCALE! (NTSC CFR, VFR ~0.06)"
    )
    set "MOVFLAGS="
    if "!USE_FASTSTART!"=="1" set "MOVFLAGS=-movflags +faststart"
    if "!MOVFLAGS!"=="" (
      echo  CFR fix: !CFR_DESC! !VTAG! -fps_mode passthrough ^(faststart OFF^)
    ) else (
      echo  CFR fix: !CFR_DESC! !VTAG! -fps_mode passthrough !MOVFLAGS!
    )
    echo  CFR fix: !CFR_DESC! !VTAG! !MOVFLAGS! >> "%LOG_FILE%" 2>&1
    echo  Subtitles: srt/ass/ssa -^> mov_text ^(bitmap will be dropped^), faststart=!USE_FASTSTART! >> "%LOG_FILE%" 2>&1

    REM ---- primary remux attempt (with subtitles) ----
    if "%LOG_TIMINGS%"=="1" echo [%time%] remux start "%%~nxI" >> "%LOG_FILE%" 2>&1
    echo  Remuxing...
    set "FFLOG=%TEMP%\ffmpeg_%%~nI.log"
    ffmpeg -hide_banner -loglevel error -i "%%~I" -map 0:v -map 0:a -map 0:s? -map_metadata 0 -c:v copy -c:a copy -c:s mov_text !CFR_ARGS! !VTAG! -fps_mode passthrough !MOVFLAGS! -n "%%~nI.mp4" > "!FFLOG!" 2>&1
    set "FFERR=!errorlevel!"
    type "!FFLOG!"
    type "!FFLOG!" >> "%LOG_FILE%" 2>&1
    del "!FFLOG!" >nul 2>&1
    if "%LOG_TIMINGS%"=="1" echo [%time%] remux done err=!FFERR! >> "%LOG_FILE%" 2>&1

    if !FFERR! NEQ 0 (
      echo  First pass failed ^(likely bitmap subs or incompatible codec^) - retrying without subtitles...
      echo  First pass failed err=!FFERR! retry without subs >> "%LOG_FILE%" 2>&1
      set "FFLOG2=%TEMP%\ffmpeg_%%~nI_retry.log"
      ffmpeg -hide_banner -loglevel error -i "%%~I" -map 0:v -map 0:a -map_metadata 0 -c:v copy -c:a copy !CFR_ARGS! !VTAG! -fps_mode passthrough !MOVFLAGS! -sn -n "%%~nI.mp4" > "!FFLOG2!" 2>&1
      set "FFERR2=!errorlevel!"
      type "!FFLOG2!"
      type "!FFLOG2!" >> "%LOG_FILE%" 2>&1
      del "!FFLOG2!" >nul 2>&1
      if !FFERR2! NEQ 0 (
        echo  FAILED: "%%~I" - check audio codec ^(opus/flac/vp9 not MP4-compatible^). Try -c:a aac.
        echo  FAILED "%%~I" >> "%LOG_FILE%" 2>&1
        set /a FAILED+=1
      ) else (
        echo  SUCCESS ^(without subs^): "%%~nI.mp4" ^[CFR !NUM!/!DEN! tscale !TSCALE!!VTAG!^]
        echo  SUCCESS without subs "%%~nI.mp4" >> "%LOG_FILE%" 2>&1
        set /a SUCCESS+=1
      )
    ) else (
      echo  SUCCESS: "%%~nI.mp4" ^[CFR !NUM!/!DEN! tscale !TSCALE!!VTAG!^]
      echo  SUCCESS "%%~nI.mp4" >> "%LOG_FILE%" 2>&1
      set /a SUCCESS+=1
    )
    echo.
    echo. >> "%LOG_FILE%" 2>&1
    if "%LOG_TIMINGS%"=="1" echo [%time%] DONE "%%~nxI" >> "%LOG_FILE%" 2>&1
  )
)

echo ============================================================
echo Done. Success: %SUCCESS%  Skipped ^(exists^): %SKIPPED%  Failed: %FAILED%  Warned: %WARNED%
echo Output files are in: %CD%
echo Log: %LOG_FILE%
echo ============================================================
echo [%date% %time%] Done Success=%SUCCESS% Skipped=%SKIPPED% Failed=%FAILED% Warned=%WARNED% >> "%LOG_FILE%" 2>&1
pause
endlocal
exit /b 0



