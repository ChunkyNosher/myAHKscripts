# Premium Bitrate Detection: False Positive Detection for All Videos

**Script Version:** yt-dlp batch downloader.bat (latest) | **Date:** 2025-12-01 | **Scope:** Premium format detection logic incorrectly identifies all videos as having Premium bitrate

---

## Problem Summary
The batch script's Premium bitrate detection logic is incorrectly flagging EVERY video as having "Premium Bitrate Format" available, even when the videos do not actually have Premium format options. This results in all videos being re-encoded with H.265, regardless of their actual available formats, and incorrect logging showing "Premium Re-encoded: 6" when no Premium formats were actually present.

## Root Cause
**File:** `yt-dlp batch downloader.bat`  
**Location:** `:DOWNLOAD_AND_ENCODE` subroutine (lines 385-450, specifically lines 410-440)  
**Issue:** The `findstr` command checking for "premium" in the format list output is producing false positives because it's matching against the entire format list file content, including text that is NOT in the format ID or format data columns.

### Specific Problematic Code Sections

**Lines 410-433:** The format ID checks using multiple `findstr` patterns:
```batch
rem Check for premium format IDs in the format list
findstr /r "^356[ 	]" "!TEMP_FORMAT_FILE!" >nul 2>&1
if !errorlevel! equ 0 (
	set "PREMIUM_DETECTED=1"
)
findstr /r "^616[ 	]" "!TEMP_FORMAT_FILE!" >nul 2>&1
if !errorlevel! equ 0 (
	set "PREMIUM_DETECTED=1"
)
findstr /r "^774[ 	]" "!TEMP_FORMAT_FILE!" >nul 2>&1
if !errorlevel! equ 0 (
	set "PREMIUM_DETECTED=1"
)

rem Also check with leading spaces for format IDs
findstr /c:" 356 " "!TEMP_FORMAT_FILE!" >nul 2>&1
if !errorlevel! equ 0 (
	set "PREMIUM_DETECTED=1"
)
findstr /c:" 616 " "!TEMP_FORMAT_FILE!" >nul 2>&1
if !errorlevel! equ 0 (
	set "PREMIUM_DETECTED=1"
)
findstr /c:" 774 " "!TEMP_FORMAT_FILE!" >nul 2>&1
if !errorlevel! equ 0 (
	set "PREMIUM_DETECTED=1"
)
```

**Lines 435-440:** The case-insensitive "premium" text search (THE PRIMARY CULPRIT):
```batch
rem Check for premium in MORE INFO column (high bitrate indicator)
findstr /i "premium" "!TEMP_FORMAT_FILE!" >nul 2>&1
if !errorlevel! equ 0 (
	set "PREMIUM_DETECTED=1"
)
```

### Why This Causes False Positives

The `findstr /i "premium" "!TEMP_FORMAT_FILE!"` command is searching for the word "premium" anywhere in the yt-dlp format list output. However, according to recent yt-dlp documentation and GitHub issues, YouTube has been phasing out certain Premium format access, and the format list output structure has changed.

The issue is that yt-dlp's `--list-formats` output can include informational text, headers, or metadata that contains the word "premium" even when NO actual Premium format IDs (356, 616, 774, 721) are available. For example:
- Header text about Premium features
- Codec descriptions mentioning Premium support
- Warning messages about Premium format availability
- The verbose output debug file (`!TEMP_FORMAT_FILE!.debug`) may contain "Detected YouTube Premium" subscription messages

The current logic treats ANY occurrence of the text "premium" in the format list file as confirmation of Premium format availability, which is fundamentally flawed.

### Additional Context from yt-dlp Documentation

Based on GitHub issues and documentation:
- **Format 616** was the iOS m3u8 Premium format, but YouTube has been blocking access to it since August 2025 (even for non-Premium users who previously had access)
- **Format 356** is the HTTPS variant of 616, only accessible with actual Premium account cookies
- **Format 774** and **721** (AV1 Premium) are also Premium-exclusive and require authentication
- The script checks for Premium subscription detection in verbose output (`"Detected YouTube Premium"` in `.debug` file), but this only confirms the user HAS Premium subscription, NOT that Premium formats are actually available for that specific video
- Not all videos uploaded to YouTube have Premium bitrate variants available, even for Premium subscribers

<scope>
**Modify:**
- `yt-dlp batch downloader.bat` (`:DOWNLOAD_AND_ENCODE` subroutine, lines 385-480)

**Do NOT Modify:**
- Other encoding profiles or menu logic
- Log file generation structure
- Other parts of the download/encoding workflow
</scope>

## Fix Required

The Premium detection logic needs to be completely redesigned to use more robust format list parsing rather than naive text searching. The solution should:

1. **Parse the format list output structurally** rather than searching for plain text. The yt-dlp `--list-formats` output is organized in columns, and the format ID column is at the beginning of each line. Premium format detection should ONLY match against lines where the format ID column (first column) contains one of the specific Premium format IDs.

2. **Strengthen the regex patterns** to match ONLY the format ID column at the beginning of lines, not arbitrary text appearing later in the line or in header/footer text. The current `findstr /r "^356[ 	]"` pattern is on the right track but may not be specific enough for the actual yt-dlp output structure.

3. **Remove or significantly restrict the generic "premium" text search** (line 436). This catch-all search is the primary source of false positives. If kept at all, it should have much stricter context requirements (e.g., only in specific columns, with format-like structure around it).

4. **Consider the relationship between Premium subscription detection and format availability**. The script currently checks for "Detected YouTube Premium" in verbose output, but this only confirms the user's subscription status, NOT whether the specific video being downloaded has Premium formats. These should be treated as separate checks.

5. **Add validation to ensure matched format IDs appear in properly structured format list lines**. Format list lines have a specific structure with format ID, extension, resolution, and other metadata in specific columns. The detection should verify the match occurs in a properly formatted line, not in header text, warnings, or metadata sections.

6. **Consider using yt-dlp's JSON output for format detection** as an alternative approach. Using `yt-dlp -J <URL>` produces structured JSON output that can be parsed more reliably than text-based format lists, eliminating ambiguity about what text appears where.

<acceptance_criteria>
- [ ] Only videos that actually have Premium format IDs (356, 616, 774, or 721) available are detected as Premium
- [ ] Videos without Premium formats are correctly identified as non-Premium (H.264, AV1, or VP9)
- [ ] The log file accurately reports the count of Premium-encoded videos
- [ ] No false positives from header text, warnings, or metadata containing "premium"
- [ ] The detection logic works correctly whether or not the user has a Premium subscription
- [ ] Manual test: Run script on known non-Premium videos → should NOT detect Premium format → should download as AV1/VP9/H264 appropriately
- [ ] Manual test: Run script on known Premium videos (with cookies) → should correctly detect Premium format → should download/re-encode appropriately
</acceptance_criteria>

## Supporting Context

<details>
<summary>Log Evidence</summary>

From the attached log file `encoding_01-Mon-12_03-43_GPU_MIXEDVIDEO.txt`:

```
Processing: https://www.youtube.com/watch?v=Ci_zad39Uhw 
Timestamp: Mon 12/01/2025 15:43:51.69 
  Detected: YouTube Premium subscription active 
  Detected: Premium Bitrate Format 
  Action: Downloading Premium and re-encoding to H.265 
  Status: SUCCESS 
 
Processing: https://www.youtube.com/watch?v=ldBCQNOMQaE 
Timestamp: Mon 12/01/2025 15:44:53.85 
  Detected: YouTube Premium subscription active 
  Detected: Premium Bitrate Format 
  Action: Downloading Premium and re-encoding to H.265 
  Status: SUCCESS
```

All 6 videos processed in the log show "Detected: Premium Bitrate Format" even though statistically, it's extremely unlikely that ALL videos from a random batch would have Premium formats available (many YouTube videos, especially older uploads, were never encoded with Premium bitrate variants).

The log also shows "Premium Re-encoded: 6" in the summary, which is suspiciously high for a batch of videos.
</details>

<details>
<summary>yt-dlp Premium Format Background</summary>

**Premium Format IDs:**
- **356**: VP9 1080p Premium (HTTPS/DASH) - requires Premium cookies
- **616**: VP9 1080p Premium (m3u8/HLS) - formerly accessible without Premium, now heavily restricted by YouTube
- **774**: VP9 Premium variant
- **721**: AV1 Premium enhanced bitrate - requires Premium cookies

**Recent Changes (2025):**
- YouTube began phasing out access to format 616 (iOS m3u8 client) around August 2025
- yt-dlp removed the iOS client as a default client in late 2025
- Premium formats now require actual Premium account cookies for access
- Many videos, even with Premium subscription, may not have Premium format variants available (dependent on when/how the video was originally uploaded and encoded)

**Key Insight:** Having a Premium subscription does NOT guarantee that any specific video has Premium formats available. The subscription status and format availability are separate concerns.

Sources: GitHub issues #14133, #14669, #10682 from yt-dlp/yt-dlp repository; Reddit discussions on r/youtubedl
</details>

<details>
<summary>yt-dlp Format List Output Structure</summary>

The `yt-dlp --list-formats` output is structured in columns:

```
ID  EXT RESOLUTION FPS │   FILESIZE   TBR PROTO │ VCODEC          VBR ACODEC      ABR ASR MORE INFO
---------------------------------------------------------------------------------------------------
139 m4a audio only     │    1.45MiB   65k https │ audio only          mp4a.40.5   65k 22k low, m4a_dash
140 m4a audio only     │    2.90MiB  130k https │ audio only          mp4a.40.2  130k 44k medium, m4a_dash
251 webm audio only    │    2.93MiB  131k https │ audio only          opus       131k 48k medium, webm_dash
...
```

The first column is the format ID. Premium format IDs would appear in this column if available. The detection logic should ONLY match format IDs in this specific column position, not arbitrary text elsewhere in the output or in headers/footers.

According to yt-dlp documentation, the output is tabular with whitespace-separated columns. The MORE INFO column (rightmost) can contain descriptive text that might include words like "premium" as codec descriptions or quality indicators, which is why a naive text search produces false positives.
</details>

---

**Priority:** High | **Dependencies:** None | **Complexity:** Medium

**Recommended Approach:** Refactor to use yt-dlp's JSON output (`-J` flag) for format detection, as this provides structured data that eliminates parsing ambiguities, or implement significantly stricter regex patterns that only match the format ID column at the beginning of format list lines.
