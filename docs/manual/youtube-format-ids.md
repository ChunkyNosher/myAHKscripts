# YouTube Format IDs: Complete Reference Guide (December 2025)

**Last Updated:** December 1, 2025  
**Sources:** yt-dlp GitHub repository, MartinEesmaa YouTube Format IDs Gist (Updated Sep 25, 2025), Reddit r/youtubedl community, yt-dlp issue tracker

---

## CRITICAL UPDATES FOR 2025

### Premium Format Availability Changes
- **Format 616** (VP9 1080p Premium m3u8) has been largely **phased out** by YouTube as of August 2025
- **Format 356** (VP9 1080p Premium HTTPS) is the current Premium format but **requires actual Premium account cookies**
- **Format 721** (AV1 1080p 60fps Premium) requires Premium account cookies and is in testing/limited availability
- iOS client access to Premium formats has been blocked with app attestation
- Non-Premium users can no longer access Premium bitrate formats through yt-dlp

---

## PREMIUM BITRATE FORMATS

### Video Formats (Require YouTube Premium + Cookies)

| Format ID | Codec | Resolution | FPS | Protocol | Container | Status | Notes |
|-----------|-------|------------|-----|----------|-----------|--------|-------|
| **356** | VP9 | 1080p | 30 | HTTPS | WebM | **Active** | Primary Premium format, requires cookies |
| **616** | VP9 | 1080p | 30 | m3u8/HLS | WebM | **Deprecated** | Phased out Aug 2025, iOS client |
| **721** | AV1 | 1080p | 60 | HTTPS | MP4 | **Testing** | Premium HFR AV1, limited availability |
| **712** | VP9 | 1080p | ? | ? | WebM | **Unconfirmed** | Mentioned in sources but rarely seen |

**How to download Premium formats with yt-dlp:**
```bash
yt-dlp --cookies-from-browser firefox -f 356+bestaudio <URL>
# OR
yt-dlp --cookies cookies.txt -f 356+bestaudio <URL>
```

### Audio Formats (Require YouTube Premium + Cookies)

| Format ID | Codec | Bitrate | Channels | Status | Notes |
|-----------|-------|---------|----------|--------|-------|
| **774** | Opus | ~256 kbps (VBR) | Stereo (2) | **Active** | Premium audio quality, YT Music |
| **141** | AAC (LC) | 256 kbps | Stereo (2) | **Removed** | Previously YT Music Premium only |

**How to download Premium audio with yt-dlp:**
```bash
yt-dlp --cookies-from-browser firefox -f 774 <URL>
```

**Important Notes:**
- Premium formats are **video-only** (356, 616, 721) or **audio-only** (774), must be merged
- Requires passing browser cookies with `--cookies-from-browser <browser>` or `--cookies <file>`
- Android client does NOT support cookie authentication in yt-dlp
- Format 616 may still appear in format lists but will return 403 errors
- Not all videos have Premium format variants, even for Premium subscribers

---

## AV1 FORMATS

### 1080p AV1 Formats

| Format ID | Resolution | FPS | Bitrate Category | Protocol | Container | Notes |
|-----------|------------|-----|------------------|----------|-----------|-------|
| **399** | 1080p | 30 | Standard | HTTPS | MP4 | Non-Premium, widely available |
| **699** | 1080p | 60 | High | HTTPS | MP4 | AV1 HFR (High Framerate) |
| **721** | 1080p | 60 | **Premium High** | HTTPS | MP4 | **Premium only**, ~3-4x bitrate of 699 |

### 720p AV1 Formats

| Format ID | Resolution | FPS | Bitrate Category | Protocol | Container | Notes |
|-----------|------------|-----|------------------|----------|-----------|-------|
| **398** | 720p | 30 | Standard | HTTPS | MP4 | Non-Premium |
| **698** | 720p | 60 | High | HTTPS | MP4 | AV1 HFR |

### Other AV1 Formats (For Reference)

| Format ID | Resolution | FPS | Bitrate | Notes |
|-----------|------------|-----|---------|-------|
| 397 | 480p | 30 | Standard | Common |
| 697 | 480p | 60 | High | HFR |
| 396 | 360p | 30 | Standard | Common |
| 696 | 360p | 60 | High | HFR |
| 395 | 240p | 30 | Standard | Common |
| 695 | 240p | 60 | High | HFR |
| 394 | 144p | 30 | Standard | Common |
| 694 | 144p | 60 | High | HFR |
| 700 | 1440p | 60 | High | HFR, rare |
| 400 | 1440p | 30 | Standard | Rare |
| 701 | 2160p (4K) | 60 | High | HFR, rare |
| 401 | 2160p (4K) | 30 | Standard | Rare |
| 702 | 4320p (8K) | 60 | High | HFR, extremely rare |
| 402/571 | 4320p (8K) | 60 | High | HFR variants, extremely rare |

**AV1 Notes:**
- AV1 formats are only provided for **popular videos** (varies by view count/age)
- All AV1 variants can be HDR (no separate non-HDR variants)
- AV1 HFR High formats (69x series) have **~3-4x higher bitrate** than standard AV1
- YouTube may apply AI sharpening to AV1 formats (reported in 2025)

---

## VP9 FORMATS

### 1080p VP9 Formats

| Format ID | Resolution | FPS | Bitrate | Protocol | Container | Notes |
|-----------|------------|-----|---------|----------|-----------|-------|
| **248** | 1080p | 30 | Standard | HTTPS | WebM | Most common VP9 1080p |
| **303** | 1080p | 60 | High (HFR) | HTTPS | WebM | VP9 HFR |
| **356** | 1080p | 30 | **Premium** | HTTPS | WebM | **Premium only**, requires cookies |
| **616** | 1080p | 30 | **Premium** | m3u8/HLS | WebM | **Deprecated** (Aug 2025) |
| **335** | 1080p | 60 | HDR HFR | HTTPS | WebM | VP9.2 HDR, rare |

### 720p VP9 Formats

| Format ID | Resolution | FPS | Bitrate | Protocol | Container | Notes |
|-----------|------------|-----|---------|----------|-----------|-------|
| **247** | 720p | 30 | Standard | HTTPS | WebM | Common VP9 720p |
| **302** | 720p | 60 | High (HFR) | HTTPS | WebM | VP9 HFR |
| **612** | 720p | 60 | High (HFR) | m3u8/HLS | WebM | m3u8 variant of 302 |
| **334** | 720p | 60 | HDR HFR | HTTPS | WebM | VP9.2 HDR, rare |

### Other VP9 Formats (For Reference)

| Format ID | Resolution | FPS | Bitrate | Notes |
|-----------|------------|-----|---------|-------|
| 244 | 480p | 30 | Standard | Common |
| 243 | 360p | 30 | Standard | Common |
| 242 | 240p | 30 | Standard | Common |
| 278/598 | 144p | 30 | Standard | 598 is rare variant |
| 271 | 1440p | 30 | Standard | Rare |
| 308 | 1440p | 60 | HFR | Rare |
| 336 | 1440p | 60 | HDR HFR | VP9.2 HDR, rare |
| 313 | 2160p (4K) | 30 | Standard | Rare |
| 315 | 2160p (4K) | 60 | HFR | Rare |
| 337 | 2160p (4K) | 60 | HDR HFR | VP9.2 HDR, rare |
| 272 | 4320p (8K) | 60 | HFR | Extremely rare |

**VP9 Notes:**
- VP9 is YouTube's primary codec for most resolutions
- Non-HFR 1080p+ variants may not be provided for HFR videos
- VP9.2 formats (33x series) support HDR (High Dynamic Range)

---

## H.264 FORMATS (For Reference)

### 1080p H.264 Formats

| Format ID | Resolution | FPS | Protocol | Container | Notes |
|-----------|------------|-----|----------|-----------|-------|
| 137 | 1080p | 30 | HTTPS | MP4 | Standard H.264 |
| 299 | 1080p | 60 | HTTPS | MP4 | H.264 HFR |
| 214 | 720p | 30 | HTTPS | MP4 | High bitrate variant, rare |
| 379 | 720p | 30 | m3u8/HLS | MP4 | Linked to 214, high bitrate |

### 720p H.264 Formats

| Format ID | Resolution | FPS | Protocol | Container | Notes |
|-----------|------------|-----|----------|-----------|-------|
| 136 | 720p | 30 | HTTPS | MP4 | Standard H.264 |
| 298 | 720p | 60 | HTTPS | MP4 | H.264 HFR |

**H.264 Notes:**
- H.264 generally has **lower quality** than VP9/AV1 at same resolution
- Your batch script should **skip re-encoding** H.264 videos unless upgrading to Premium/AV1/VP9
- 1440p+ H.264 variants only provided for 360° videos

---

## M3U8 TO HTTPS FORMAT MAPPING

Many m3u8 (HLS/Apple) format IDs map to equivalent HTTPS DASH format IDs:

| m3u8 ID | HTTPS ID | Resolution | Codec | Notes |
|---------|----------|------------|-------|-------|
| 616 | 356 | 1080p | VP9 | Premium format |
| 617 | 303 | 1080p 60fps | VP9 | VP9 HFR |
| 614 | 248 | 1080p | VP9 | Standard VP9 |
| 612 | 302 | 720p 60fps | VP9 | VP9 HFR |
| 609 | 247 | 720p | VP9 | Standard VP9 |
| 606 | 244 | 480p | VP9 | Standard VP9 |
| 605 | 243 | 360p | VP9 | Standard VP9 |
| 604 | 242 | 240p | VP9 | Standard VP9 |
| 603 | 278 | 144p | VP9 | Standard VP9 |
| 602 | 598 | 144p | VP9 | Rare variant |
| 620 | 271 | 1440p | VP9 | Rare |
| 625 | 313 | 2160p | VP9 | Rare |
| 270 | 137 | 1080p | H.264 | Standard |
| 312 | 299 | 1080p 60fps | H.264 | HFR |
| 311 | 298 | 720p 60fps | H.264 | HFR |
| 232 | 136 | 720p | H.264 | Standard |
| 269 | 160 | 144p | H.264 | Standard |

---

## DETECTION LOGIC FOR BATCH SCRIPT

### Recommended Detection Order

1. **Check for Premium Format IDs** (only if cookies available and Premium subscription active):
   - Format 356 (VP9 1080p Premium)
   - Format 721 (AV1 1080p HFR Premium) - rare
   - Use **strict line-beginning regex**: `findstr /r "^356[ 	]" <file>`
   - Do NOT use generic text search like `findstr /i "premium"`

2. **Check for High-Quality AV1** (1080p):
   - Format 399 (AV1 1080p 30fps)
   - Format 699 (AV1 1080p 60fps HFR)
   - Format 721 (AV1 1080p 60fps Premium) - requires cookies

3. **Check for High-Quality AV1** (720p):
   - Format 398 (AV1 720p 30fps)
   - Format 698 (AV1 720p 60fps HFR)

4. **Check for VP9** (1080p):
   - Format 248 (VP9 1080p)
   - Format 303 (VP9 1080p 60fps HFR)

5. **Check for H.264** (fallback):
   - Format 137 (H.264 1080p)
   - Format 136 (H.264 720p)

### Critical Detection Rules

**DO:**
- Match format IDs **at the beginning of lines** in the format list
- Use regex patterns like `^356[ 	]` or `^399[ 	]`
- Verify matches occur in properly structured format list lines (with columns)
- Consider using yt-dlp's JSON output (`-J` flag) for reliable parsing

**DON'T:**
- Use `findstr /i "premium"` - causes false positives from header text, metadata, codec descriptions
- Search for "enhanced", "bitrate", or other descriptive text in format lists
- Assume "Detected YouTube Premium" subscription message means Premium formats are available
- Match format IDs appearing in non-format-list text (headers, warnings, debug output)

### Example Correct Detection Pattern (Batch)

```batch
rem Check for specific Premium format ID at line beginning
findstr /r "^356[ 	]" "!TEMP_FORMAT_FILE!" >nul 2>&1
if !errorlevel! equ 0 (
    set "PREMIUM_DETECTED=1"
)

rem Check for AV1 1080p formats (exclude low-quality IDs)
findstr /r "^399[ 	]" "!TEMP_FORMAT_FILE!" | findstr /v "243 278 394 242 395 396 244 397" >nul 2>&1
if !errorlevel! equ 0 (
    set "CODEC_TYPE=AV1"
)

rem Check for VP9 1080p formats
findstr /r "^248[ 	]" "!TEMP_FORMAT_FILE!" >nul 2>&1
if !errorlevel! equ 0 (
    set "CODEC_TYPE=VP9"
)
```

---

## AUDIO FORMATS (For Completeness)

| Format ID | Codec | Bitrate | Channels | Status | Notes |
|-----------|-------|---------|----------|--------|-------|
| 139 | AAC (HE v1) | 48 kbps | Stereo | Active | YT Music, DRC optional |
| 140 | AAC (LC) | 128 kbps | Stereo | Active | YT Music, DRC optional |
| 141 | AAC (LC) | 256 kbps | Stereo | Removed | Was YT Music Premium |
| 249 | Opus | ~50 kbps (VBR) | Stereo | Some | DRC optional |
| 250 | Opus | ~70 kbps (VBR) | Stereo | Some | DRC optional |
| 251 | Opus | ~128 kbps (VBR) | Stereo | Active | Most common |
| **774** | Opus | ~256 kbps (VBR) | Stereo | Active | **Premium audio**, requires cookies |
| 256 | AAC (HE v1) | 192 kbps | 5.1 Surround | Rare | Surround sound |
| 258 | AAC (LC) | 384 kbps | 5.1 Surround | Rare | Surround sound |
| 328 | EAC3 | 384 kbps | 5.1 Surround | Rare | Enhanced AC3 |
| 380 | AC3 | 384 kbps | 5.1 Surround | Rare | Dolby Digital |
| 773 | IAMF (Opus) | ~900 kbps (VBR) | 7.1.4 Binaural | Rare | Immersive audio |
| 599 | AAC (HE v1) | 30 kbps | Stereo | Removed | Discontinued Feb 2025 |
| 600 | Opus | ~35 kbps (VBR) | Stereo | Removed | Discontinued Feb 2025 |

---

## REFERENCES AND SOURCES

1. **MartinEesmaa YouTube Format IDs Gist** (Last updated Sep 25, 2025)  
   https://gist.github.com/MartinEesmaa/2f4b261cb90a47e9c41ba115a011a4aa

2. **yt-dlp GitHub Issues:**
   - #14669: Premium 1080p (itag 356) formats missing since Oct 14, 2025
   - #14133: Enhanced bitrate no longer available to download (Aug 2025)
   - #13545: Version 2025.06.25 doesn't get Premium formats with cookies (Jun 2025)
   - #10682: Current version will not detect YouTube premium format 356 (Aug 2024)
   - #13091: How to download Premium Audio from YouTube videos (May 2025)

3. **Reddit r/youtubedl Community Discussions:**
   - "Is yt-dlp no longer capable of downloading Premium formats?" (Aug 2025)
   - "Downloading YouTube Premium Video Formats?" (Aug 2025)
   - "YouTube is again decreasing bitrate now that they added 1080p60 Premium" (May 2025)
   - "Has Youtube completely blocked premium?" (Sep 2025)

4. **yt-dlp Official Documentation:**
   - https://github.com/yt-dlp/yt-dlp

---

## CHANGELOG (2025)

**October 2025:**
- Format 356 (Premium 1080p HTTPS) began experiencing intermittent availability issues

**August 2025:**
- Format 616 (Premium 1080p m3u8) phased out by YouTube
- iOS client access to Premium formats blocked with app attestation
- yt-dlp removed iOS client from default clients for format requests

**May 2025:**
- Format 721 (AV1 1080p HFR Premium) discovered, requires Premium cookies
- YouTube began decreasing bitrates for non-Premium formats

**February 2025:**
- Formats 599 and 600 (low-bitrate audio) discontinued for all new uploads

---

## SUMMARY FOR YOUR BATCH SCRIPT

**Premium Bitrate Format IDs (All require cookies):**
- **356** (VP9 1080p HTTPS) - Primary Premium format
- **616** (VP9 1080p m3u8) - Deprecated, avoid
- **721** (AV1 1080p 60fps) - Rare, testing phase
- **774** (Opus 256kbps audio) - Premium audio only

**1080p AV1 Format IDs:**
- **399** (30fps standard)
- **699** (60fps HFR)
- **721** (60fps Premium, requires cookies)

**720p AV1 Format IDs:**
- **398** (30fps standard)
- **698** (60fps HFR)

**1080p VP9 Format IDs:**
- **248** (30fps standard)
- **303** (60fps HFR)
- **356** (30fps Premium, requires cookies)

**Detection Priority (Highest to Lowest Quality):**
1. Premium: 356, 721 (requires cookies)
2. AV1 1080p: 399, 699
3. VP9 1080p: 248, 303
4. AV1 720p: 398, 698
5. VP9 720p: 247, 302
6. H.264: 137, 136 (skip re-encoding)
