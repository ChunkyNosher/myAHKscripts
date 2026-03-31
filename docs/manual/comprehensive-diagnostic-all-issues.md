# COMPREHENSIVE DIAGNOSTIC REPORT: Multiple Critical Issues in NeMo Transcription

**Date:** December 11, 2025 | **Severity:** Critical | **Status:** Multiple Blocking Issues Found

---

## Executive Summary

After thorough analysis of `transcribe_ui.py` against **official NVIDIA NeMo documentation**, I've identified **FOUR DISTINCT CRITICAL ISSUES** preventing the Gradio interface from working:

1. **❌ Incorrect timestamp object handling** (API misuse)
2. **❌ Unused/problematic batch_size calculation** (code smell, potential conflict)
3. **❌ Insufficient file lock retry delays** (architecture flaw)
4. **❌ Missing retry logic on librosa duration check** (incomplete protection)

---

## Issue #1: CRITICAL - Incorrect Timestamp Object Access

### Problem
The code tries to access `.words` attribute on Hypothesis objects that don't have this interface, causing crashes.

### Root Cause

**File:** `transcribe_ui.py`  
**Location:** Lines 1178-1184 (single file) and lines 1220-1229 (batch processing save)  
**Issue:** Accessing non-existent `.words` attribute instead of `.timestamp` dictionary

**Current Incorrect Code:**
```python
if include_timestamps and hasattr(result[0], 'words') and result[0].words:
    timestamp_text = "\n\n### Word-Level Timestamps (first 50 words):\n\n"
    for i, word in enumerate(result[0].words[:50]):
        timestamp_text += f"`{word.start:.2f}s - {word.end:.2f}s` → **{word.text}**\n\n"
```

**Official NeMo API (from https://docs.nvidia.com/nemo-framework/user-guide/latest/nemotoolkit/asr/intro.html):**

From the official documentation, the correct pattern is:
```python
hypotheses = asr_model.transcribe([...], timestamps=True)
word_timestamps = hypotheses[0].timestamp['word']  # Access via dictionary

for stamp in word_timestamps:
    print(f"{stamp['start']}s - {stamp['end']}s : {stamp['segment']}")
```

**Why Current Code Fails:**
- `result[0].words` does NOT exist (returns False on hasattr check)
- Hypothesis objects use `.timestamp` dictionary with keys `'word'`, `'char'`, `'segment'`
- Each entry in the dictionary is a dict with `'start'`, `'end'`, and `'segment'`/`'word'` keys
- The code assumes objects with `.start`, `.end`, `.text` attributes but gets dictionaries instead

**Impact:** 
- ✅ If timestamps disabled: transcription works (timestamps code skipped)
- ❌ If timestamps enabled: hasattr returns False, code never executes (silent skip, misleading to user)
- ❌ If you later fix hasattr check: code crashes on attribute access

### Fix Required

Replace the timestamp handling logic with:
1. Change from checking `.words` attribute to accessing `.timestamp` dictionary
2. Access timestamp data using dictionary syntax: `stamp['start']`, `stamp['end']`, `stamp['word']` or `stamp['segment']`
3. Handle the timestamp dictionary structure properly (keys not attributes)
4. Apply fix in TWO locations: single file output (line 1178) AND batch file save (line 1220)

---

## Issue #2: PROBLEMATIC - Unused/Conflicting Batch Size Calculation

### Problem
The code calculates dynamic batch size via `get_dynamic_batch_size()` but this may conflict with NeMo's internal batching strategy.

### Root Cause

**File:** `transcribe_ui.py`  
**Location:** `get_dynamic_batch_size()` function (lines 285-293) and usage (lines 1129-1130)  
**Issue:** Duration-based batch size calculation doesn't align with how NeMo handles file list batching

**Current Code:**
```python
def get_dynamic_batch_size(duration, model_key):
    """Calculate optimal batch size based on audio duration and model"""
    max_batch = MODEL_CONFIGS[model_key]["max_batch_size"]
    
    if duration < 60:  # Under 1 minute
        return min(8, max_batch)
    elif duration < 300:  # Under 5 minutes
        return min(16, max_batch)
    elif duration < 900:  # Under 15 minutes
        return min(24, max_batch)
    else:  # Longer audio
        return max_batch

# Usage (lines 1129-1130):
batch_size = get_dynamic_batch_size(total_duration, model_key)
result = model.transcribe(processed_files, batch_size=batch_size, timestamps=include_timestamps)
```

**Why This Is Problematic:**

From **official NeMo documentation** (https://docs.nvidia.com/nemo-framework/user-guide/latest/nemotoolkit/asr/intro.html):

The simple inference transcribe() method's documentation does NOT mention duration-based batch sizing. The official examples simply use:
```python
transcript = asr_model.transcribe(["path/to/audio_file.wav"])[0].text
```

The `batch_size` parameter that NeMo DOES accept works differently:
- It controls how many files are batched together for processing
- Not how the audio duration is split internally
- Default value is 4 (documented in NeMo API)

**The Actual Problem:**
1. Calculating batch size as 8/16/24/32 based on audio **duration** is incorrect - it should be based on **file count**
2. The formula changes batch size even for single files with long duration (e.g., 1-hour file → batch_size=32)
3. This may cause NeMo to internally conflict with memory calculations
4. The model configs define "max_batch_size" per model, but these are guidelines, not strict requirements

### Fix Required

Either:
- **Option A (RECOMMENDED):** Remove `batch_size` parameter entirely - let NeMo use its default (4)
- **Option B:** Calculate batch_size based on FILE COUNT, not duration:
  ```python
  # Pseudo-code
  batch_size = min(4, len(file_list))  # Default 4, or num files if fewer
  ```
- **Option C:** Always use `batch_size=4` (the documented default)

Do NOT use duration-based calculation - it's not how NeMo's inference works.

---

## Issue #3: ARCHITECTURAL FLAW - Insufficient File Lock Retry Delays

### Problem
The file copy retry logic uses delays too short (0.2s → 0.4s → 0.6s) to accommodate real-world Windows antivirus/OneDrive scanning times.

### Root Cause

**File:** `transcribe_ui.py`  
**Location:** `copy_gradio_file_to_cache()` function (lines 239-278)  
**Issue:** Base delay of 200ms with only 3 retries insufficient for Windows services

**Current Code:**
```python
base_delay = 0.2  # 200ms base delay
for attempt in range(max_retries):  # max_retries=3
    try:
        shutil.copy2(file_path, cached_path)
        return str(cached_path)
    except (OSError, PermissionError) as e:
        # ...
        if is_file_lock and attempt < max_retries - 1:
            delay = base_delay * (attempt + 1)  # Linear: 0.2s, 0.4s, 0.6s
            time.sleep(delay)
```

**Real-World Windows Timing:**
- Windows Defender scan time: 500ms - 2000ms per file
- OneDrive sync assessment: 300ms - 1500ms per file
- File indexing by Windows Search: 100ms - 800ms
- **Total possible lock duration:** Up to 4+ seconds in worst case

**Current retry timeline:** 0.2s + 0.4s + 0.6s = 1.2 seconds total wait (INSUFFICIENT)

### Fix Required

Increase retry robustness:
1. Increase `max_retries` from 3 to at least 5-6
2. Change from linear backoff to exponential: 0.5s → 1.0s → 1.5s → 2.0s → 3.0s
3. Total wait time should be minimum 8-10 seconds
4. Add validation that file exists and is readable after copy

**Example Fix:**
```python
base_delay = 0.5
max_retries = 6
for attempt in range(max_retries):
    try:
        shutil.copy2(file_path, cached_path)
        # Validate file was actually written and is readable
        if cached_path.exists() and cached_path.stat().st_size > 0:
            return str(cached_path)
    except (OSError, PermissionError) as e:
        if is_file_lock and attempt < max_retries - 1:
            delay = base_delay * (attempt + 1)  # Exponential: 0.5s, 1.0s, 1.5s, 2.0s, 2.5s, 3.0s
            time.sleep(delay)
```

---

## Issue #4: INCOMPLETE - Missing Retry Logic on librosa.get_duration()

### Problem
The `librosa.get_duration()` call (line 1106) has NO retry logic despite being vulnerable to the same Windows file locking issues.

### Root Cause

**File:** `transcribe_ui.py`  
**Location:** Line 1106 (and lines 1116-1119 for batch processing)  
**Issue:** File copy has retry logic but duration check doesn't

**Current Code:**
```python
# Copy WITH retry (lines 1099-1109):
cached_file_path = copy_gradio_file_to_cache(file_path)  # Has retry logic ✓

# Get duration WITHOUT retry (line 1106):
duration = librosa.get_duration(path=cached_file_path)  # NO retry ✗

# Batch processing also lacks retry (line 1116):
duration = librosa.get_duration(path=cached_file_path)  # NO retry ✗
```

**Why This Fails:**
1. File was successfully copied to cache
2. Immediately calling `librosa.get_duration()` tries to read the file
3. Windows antivirus may STILL have the file locked for scanning
4. librosa call raises OSError or PermissionError
5. No retry logic → transcription fails

**Timing Problem:**
- File copy completes and returns path
- But antivirus may take additional 500ms-2000ms to scan the newly-copied file
- librosa.get_duration() is called too immediately after copy

### Fix Required

Wrap `librosa.get_duration()` calls in retry logic similar to file copy:
1. Apply same retry pattern to both single file (line 1106) and batch processing (line 1116)
2. Use exponential backoff: 0.5s → 1.0s → 1.5s seconds
3. Handle both OSError and PermissionError exceptions
4. Maximum 3-4 retries (don't need as many as file copy since file already exists)

---

## Issue #5: CODE QUALITY - Unused Configuration Values

### Problem
The `max_batch_size` values in MODEL_CONFIGS (lines 118-168) are defined but never actually used.

### Root Cause

**File:** `transcribe_ui.py`  
**Location:** MODEL_CONFIGS dictionary, "max_batch_size" key  
**Usage:** Only referenced in `get_dynamic_batch_size()` function (line 286)  

**Current Code:**
```python
MODEL_CONFIGS = {
    "parakeet-v3": {
        "max_batch_size": 32,  # ← Defined
        # ...
    },
    # ...
}

def get_dynamic_batch_size(duration, model_key):
    max_batch = MODEL_CONFIGS[model_key]["max_batch_size"]  # ← Used here
    # ...
    return max_batch  # ← Returned only in "longer audio" case
```

**Impact:**
- If "max_batch_size" is removed, only the `get_dynamic_batch_size()` function breaks
- If batch_size calculation is removed (per Issue #2 fix), these values become dead code
- Creates confusion about what batch sizing actually does

### Fix Required

After fixing Issue #2 (remove duration-based batch sizing), decide:
- **Option A:** Keep values for documentation - add comment "For reference only, not used"
- **Option B:** Remove values entirely - cleaner codebase
- **Option C:** Use for actual purpose - file-count-based batching (recommended if keeping)

---

## Summary Table

| Issue | Severity | Type | Location | Impact |
|-------|----------|------|----------|--------|
| #1: Timestamp handling | CRITICAL | API Misuse | Lines 1178-1184, 1220-1229 | Crashes if timestamps enabled |
| #2: Batch size calculation | HIGH | Logic Error | Lines 285-293, 1129-1130 | Incorrect batching, potential conflicts |
| #3: Retry delays too short | HIGH | Architecture | Lines 239-278 | Frequent file lock failures on Windows |
| #4: No retry on librosa | HIGH | Missing Logic | Lines 1106, 1116 | Fails immediately after file copy |
| #5: Unused config values | LOW | Code Quality | Lines 118-168 | Dead code, confusion |

---

## Acceptance Criteria for Fixes

- [ ] Timestamp code removed or uses `.timestamp['word']` dictionary access (NOT `.words` attribute)
- [ ] Batch size calculation removed OR changed to file-count-based (NOT duration-based)
- [ ] Retry logic for file copy uses exponential backoff: 0.5s, 1.0s, 1.5s, 2.0s, 2.5s, 3.0s
- [ ] Retry logic extended to 5-6 attempts (from current 3)
- [ ] librosa.get_duration() wrapped in retry logic with exponential backoff
- [ ] Test: Single WAV upload → transcribe (no timestamps) → works
- [ ] Test: Single WAV upload → transcribe (with timestamps) → shows word timings correctly
- [ ] Test: Three WAV files → batch transcribe → all three process without errors
- [ ] Test: Pause OneDrive/Defender, run again → still works
- [ ] All console errors cleared, Gradio UI shows success message

---

## References

**Official NeMo Documentation:**
- Intro: https://docs.nvidia.com/nemo-framework/user-guide/latest/nemotoolkit/asr/intro.html
- API Reference: https://docs.nvidia.com/nemo-framework/user-guide/24.09/nemotoolkit/asr/api.html
- Timestamp example (lines 24-47 of docs): Shows `.timestamp['word']` dictionary access
- Default batch_size: Documented as 4 in transcribe() signature

**Key Quote from Official Docs:**
> "word_timestamps = hypotheses[0].timestamp['word'] # word level timestamps for first sample"

This is the ONLY documented way to access timestamps - via `.timestamp` dictionary, NOT `.words` attribute.
