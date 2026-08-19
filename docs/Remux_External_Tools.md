# Remux External Tools — When and Why to Use Them

This doc explains the **optional external polish tools** mentioned in `RemuxDirectory_CFR.bat` and `Remux_CFR.bat`. The new batches work **pure ffmpeg** and need no extra tools. Only consider these if `ffmpeg`-only output still shows `VFR` in MediaInfo or has A/V desync.

## 1. `mp4fpsmod` (nu774) — Lightweight MP4 Timecode Editor

**What:** Tiny standalone `.exe` that edits MP4 sample durations (`stts/ctts`) without re-encoding.  
**Source:** https://github.com/nu774/mp4fpsmod — Releases contain `mp4fpsmod.exe` for Windows.  
**Size:** ~200 KB, no install, no deps.

**When to use:**
- You ran `RemuxDirectory_CFR.bat` and `MediaInfo` still reports `Frame rate mode: Variable` or `Minimum/Maximum frame rate` differ by >0.01 fps.
- You have a known CFR file that ffmpeg still flags as VFR after the `setts+timescale` fix (e.g., very long film with accumulated error).
- You need to change FPS without re-encoding, or shift audio delay.

**Examples:**
```bat
REM Fix CFR after ffmpeg remux (23.976 example, all NTSC fractions work)
mp4fpsmod --fps 0:24000/1001 input.mp4 -o fixed.mp4
mp4fpsmod --fps 0:30000/1001 input.mp4 -o fixed.mp4
mp4fpsmod --fps 0:60000/1001 input.mp4 -o fixed.mp4
mp4fpsmod --fps 0:30 input.mp4 -o fixed.mp4
mp4fpsmod --fps 0:25 input.mp4 -o fixed.mp4

REM In-place edit (overwrites, no -o needed, but keep backup)
mp4fpsmod --fps 0:24000/1001 -c -i input.mp4

REM Extract timecodes to inspect
mp4fpsmod -p tc.txt input.mp4
REM Edit via timecode file (v2 format)
mp4fpsmod -t tc.txt -c -o fixed.mp4 input.mp4
```

**Flags:**
- `-c` / `--compress-dts` — **Always add for wide player compatibility** (minimizes CTS delay, avoids edts/elst issues). Without it, some hardware players lose sync.
- `-o` output, `-i` in-place, `-p` print, `-t` tcfile, `-x` optimize.

**Pros:** Lossless, instant, no ffmpeg needed.  
**Cons:** Only MP4, ignores `edts/elst` (must re-specify delay with `-d` if source had audio delay). Extra binary to distribute.

---

## 2. `MP4Box` / `gpac` — Full ISO-BMFF Muxer

**What:** The reference MP4 packager from the GPAC project. Can import MKV/AVI/TS/H264 and write spec-correct MP4. More thorough than ffmpeg for chapters, Dolby Vision, track order.  
**Source:** https://gpac.io/downloads/gpac-nightly-builds/ — contains `MP4Box.exe` + `gpac.exe`.  
**Size:** ~30 MB.

**When to use:**
- You need **Dolby Vision / HDR metadata** preserved (ffmpeg sometimes drops `dovi` config from MKV — MP4Box with reparse keeps it).
- You have **chapter/menu** issues (duplicate menus, wrong order — see gpac#2607, fix with `--chapm=udta`).
- You want ffmpeg-alternative remux pipeline: `MKV -> raw -> MP4` with proper re-parsing.
- You prefer to **verify/fix** a file ffmpeg produced.

**Examples:**
```bat
REM Simple remux (trusts container metadata, fast)
MP4Box -add input.mkv -new output.mp4

REM Full reparse — forces re-creation of sample tables (fixes VFR jitter, DV)
MP4Box -add input.mkv:reparse -new output.mp4
REM or legacy syntax
MP4Box -add input.mkv --reparse -new output.mp4

REM gpac equivalent (newer CLI)
gpac -i input.mkv:unframer -o output.mp4
gpac -i input.mkv:reframer -o output.mp4   REM lighter: rewrite metadata only

REM Keep only Nero-style chapters (avoid duplicate QT chapters)
MP4Box -add input.mkv:chapm=udta -new output.mp4

REM Force FPS if bitstream has no timing (rare)
MP4Box -add video.h264:fps=23.976 -add audio.aac -new output.mp4
```

**Pros:** Most spec-correct, handles DV/HDR, chapters, track `tkidx` ordering, `--force_dv`, `--xps_inband`.  
**Cons:** Larger, help text is fragmented (`MP4Box -h reparse`, `gpac -h`), slightly slower, separate download.

---

## 3. `mkvextract` (mkvtoolnix) — Demux to Elementary Stream

**When:** You want the **AVI-intermediate kludge** for stubborn files: `MKV -> AVI -> MP4` or `MKV -> .h264 -> MP4`. Rarely needed now that `setts` exists.

```bat
ffmpeg -i input.mkv -c copy -f h264 temp.h264
ffmpeg -r 24000/1001 -i temp.h264 -c copy output.mp4
REM or with audio
ffmpeg -i temp.h264 -i input.mkv -map 0:v -map 1:a -c copy output.mp4
```

---

## Recommendation for This Repo

**Default:** Use `RemuxDirectory_CFR.bat` / `Remux_CFR.bat` (pure ffmpeg). They already force CFR generically for any FPS via `-bsf:v setts + -video_track_timescale` and warn if true VFR.

**Only if verification fails:**
1. Try `mp4fpsmod --fps 0:<fps> input.mp4 -o fixed.mp4` (quickest).
2. Else `MP4Box -add input.mkv:reparse -new output.mp4` (most thorough).

Verify after any tool:
```bat
ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate,r_frame_rate -of default=nw=1 input.mp4
ffmpeg -i input.mp4 -vf vfrdet -an -f null - 2>&1 | findstr VFR:
REM Expect: VFR:0.000000 (0/frames)  and  avg == r  and MediaInfo Constant
```
