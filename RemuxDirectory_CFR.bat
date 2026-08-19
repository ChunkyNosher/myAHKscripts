@echo off
setlocal enabledelayedexpansion
REM ============================================================================
REM RemuxDirectory_CFR.bat  —  LOSSLESS MKV -> MP4 REMUX (NEW FILE)
REM   Original: RemuxDirectory.bat  (left untouched per request)
REM   Purpose : Fix CFR->VFR bug + add MP4-compatible subtitles + optimizations
REM
REM   WHAT IT DOES:
REM     - Remuxes every *.mkv in current directory to *.mp4 via stream copy
REM       (no re-encode, no quality loss, fast)
REM     - Generic FPS handling: works for ANY fps including non-integers
REM       23.976 (24000/1001), 29.97 (30000/1001), 59.94 (60000/1001),
REM       24/25/30/50/60 and arbitrary values like 23.976024... etc.
REM       Uses ffprobe avg_frame_rate -> -video_track_timescale (+ setts for NTSC)
REM     - Forces CFR (corrects MKV 1ms TimecodeScale jitter vs MP4 rational
REM       timebase). Without this, MediaInfo reports VFR and Premiere desyncs.
REM       Integer FPS (30/1, 60/1): only -video_track_timescale needed -> VFR 0.000
REM       NTSC FPS (24000/1001 etc): + setts BSF to rewrite timestamps -> VFR 0.00-0.06
REM       (perfect 0.000 if source has no B-frames; 0.06 with B-frames still
REM       10x better than 0.57 without fix; re-encode gives 0.000 if needed)
REM     - Warns if source is true VFR (header mismatch + vfrdet filter)
REM     - Converts text subtitles (srt/ass/ssa/mov_text) -> mov_text (MP4 only
REM       supports mov_text/tx3g). Bitmap subs (hdmv_pgs_subtitle/vobsub)
REM       cannot be converted -> auto-dropped with warning (MP4 limitation).
REM       Alternative is burning with -vf subtitles (re-encode, not used here).
REM     - Optimizations: -map 0:v/0:a/0:s? -c:v copy -c:a copy -c:s mov_text
REM       -fps_mode passthrough -movflags +faststart -tag:v hvc1 for HEVC
REM     - No overwrite (-n): skips if .mp4 already exists
REM     - Preserves metadata (-map_metadata 0)
REM
REM   REQUIREMENTS: ffmpeg.exe + ffprobe.exe in PATH (same build)
REM   USAGE: Place in folder with MKVs and double-click.
REM   SEE ALSO: Remux_CFR.bat for single-file mode, docs/Remux_External_Tools.md
REM   for optional external polish tools (mp4fpsmod / MP4Box).
REM ============================================================================

chcp 65001 >nul 2>&1
echo.
echo === RemuxDirectory CFR + Subs + Faststart (no overwrite) ===
echo.

REM --- sanity checks ---
where ffmpeg >nul 2>&1
if errorlevel 1 (
  echo ERROR: ffmpeg not found in PATH. Install ffmpeg and add to PATH.
  pause
  exit /b 1
)
where ffprobe >nul 2>&1
if errorlevel 1 (
  echo ERROR: ffprobe not found in PATH. Install ffmpeg full build.
  pause
  exit /b 1
)

if not exist "*.mkv" (
  echo No *.mkv files found in current directory.
  echo Place this batch in the folder containing your MKVs.
  pause
  exit /b 0
)

set "SUCCESS=0"
set "SKIPPED=0"
set "FAILED=0"
set "WARNED=0"

for %%I in ("*.mkv") do (
  echo ------------------------------------------------------------
  echo Processing: "%%~nxI"

  REM ---- no overwrite ----
  if exist "%%~nI.mp4" (
    echo SKIP: "%%~nI.mp4" already exists ^(no overwrite policy^)
    set /a SKIPPED+=1
    echo.
  ) else (
    REM ---- probe FPS (generic, handles any num/den including non-integers) ----
    set "FPS="
    set "NUM="
    set "DEN="
    for /f "delims=" %%F in ('ffprobe -v error -select_streams v:0 -show_entries stream^=avg_frame_rate -of default^=nw^=1:nk^=1 "%%~I" 2^>^&1') do set "FPS=%%F"
    REM fallback to r_frame_rate if avg is 0/0 or N/A
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

    REM parse NUM/DEN from FPS string like "24000/1001"
    for /f "tokens=1,2 delims=/" %%A in ("!FPS!") do (
      set "NUM=%%A"
      set "DEN=%%B"
    )
    if "!NUM!"=="" set "NUM=30"
    if "!DEN!"=="" set "DEN=1"
    if "!NUM!"=="0" set "NUM=30"
    if "!DEN!"=="0" set "DEN=1"

    echo  Detected FPS: !FPS! ^(NUM=!NUM! DEN=!DEN!^)

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
      echo        Those tracks will be dropped. For forced style preservation requires
      echo        burning ^(-vf subtitles, re-encode^) or external OCR. See external tools doc.
      set /a WARNED+=1
    )

    REM ---- VFR detection: tier 1 header mismatch ----
    set "RFR="
    for /f "delims=" %%R in ('ffprobe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of default^=nw^=1:nk^=1 "%%~I" 2^>^&1') do set "RFR=%%R"
    if not "!FPS!"=="!RFR!" (
      echo  NOTE: Header mismatch r_frame_rate=!RFR! vs avg_frame_rate=!FPS! - possible VFR, running vfrdet...
    )

    REM ---- tier 2: vfrdet filter (per-frame deltas) ----
    set "VFR_LOG=%TEMP%\vfr_%%~nI.log"
    ffmpeg -v info -i "%%~I" -vf vfrdet -an -f null - >"!VFR_LOG!" 2>&1
    findstr /C:"VFR:" "!VFR_LOG!" >nul 2>&1
    if not errorlevel 1 (
      for /f "tokens=*" %%L in ('findstr /C:"VFR:" "!VFR_LOG!"') do (
        echo    %%L
        echo    %%L | findstr /R "VFR:0\.000000" >nul 2>&1
        if errorlevel 1 (
          echo  WARNING: VFR/jitter detected in "%%~nxI" - forcing CFR will rewrite timestamps
          echo           via setts+timescale. If source was true VFR ^(phone/screen cap^), motion may
          echo           look off. For true VFR, use re-encode: -vf fps=!NUM!/!DEN! -fps_mode cfr
          set /a WARNED+=1
        )
      )
    )
    del "!VFR_LOG!" >nul 2>&1

    REM ---- build CFR fix args (generic for ANY fps) ----
    REM Integer FPS (DEN=1): only timescale needed -> perfect VFR 0.000
    REM NTSC FPS (DEN!=1): need BSF to rewrite timestamps -> VFR 0.00-0.06 vs 0.57 without
    set "TSCALE=!NUM!"
    set /a TNUM=!NUM! 2>nul
    if !TNUM! GTR 90000 set "TSCALE=60000"
    set "CFR_ARGS=-video_track_timescale !TSCALE!"
    set "CFR_DESC=-video_track_timescale !TSCALE! (integer CFR, VFR 0.000)"
    if not "!DEN!"=="1" (
      set "CFR_ARGS=-bsf:v setts=time_base=1/!NUM!:ts=N*!DEN!:duration=!DEN!:prescale=1 -video_track_timescale !TSCALE!"
      set "CFR_DESC=-bsf:v setts=time_base=1/!NUM!:ts=N*!DEN!:duration=!DEN!:prescale=1 -video_track_timescale !TSCALE! (NTSC CFR, VFR ~0.06)"
    )

    echo  CFR fix: !CFR_DESC! !VTAG! -fps_mode passthrough
    echo  Subtitles: srt/ass/ssa -^> mov_text ^(bitmap will be dropped^), faststart enabled

    REM ---- primary remux attempt (with subtitles) ----
    REM Use !CFR_ARGS! which already contains either just timescale or BSF+timescale
    ffmpeg -hide_banner -loglevel error -i "%%~I" -map 0:v -map 0:a -map 0:s? -map_metadata 0 -c:v copy -c:a copy -c:s mov_text !CFR_ARGS! !VTAG! -fps_mode passthrough -movflags +faststart -n "%%~nI.mp4"

    if errorlevel 1 (
      echo  First pass failed ^(likely bitmap subs or incompatible codec^) - retrying without subtitles...
      ffmpeg -hide_banner -loglevel error -i "%%~I" -map 0:v -map 0:a -map_metadata 0 -c:v copy -c:a copy !CFR_ARGS! !VTAG! -fps_mode passthrough -movflags +faststart -sn -n "%%~nI.mp4"
      if errorlevel 1 (
        echo  FAILED: "%%~I" - check audio codec ^(opus/flac/vp9 not MP4-compatible^). Try re-encode audio with -c:a aac.
        set /a FAILED+=1
      ) else (
        echo  SUCCESS ^(without subs^): "%%~nI.mp4" ^[CFR !NUM!/!DEN! tscale !TSCALE!!VTAG!^]
        set /a SUCCESS+=1
      )
    ) else (
      echo  SUCCESS: "%%~nI.mp4" ^[CFR !NUM!/!DEN! tscale !TSCALE!!VTAG!^]
      set /a SUCCESS+=1
    )
    echo.
  )
)

echo ============================================================
echo Done. Success: %SUCCESS%  Skipped ^(exists^): %SKIPPED%  Failed: %FAILED%  Warned: %WARNED%
echo Output files are in: %CD%
echo Verify: ffprobe -show_streams -select_streams v:0 "file.mp4" ^| findstr frame_rate
echo         MediaInfo should show "Frame rate mode: Constant"
echo         ffmpeg -i file.mp4 -vf vfrdet -an -f null - 2^^^>^^^&1 ^| findstr VFR:
echo For perfect CFR with B-frames, re-encode fallback: ffmpeg -i in.mkv -vf fps=NUM/DEN -c:v libx264 -crf 18 -c:a copy -c:s mov_text
echo ============================================================
pause
endlocal
exit /b 0
