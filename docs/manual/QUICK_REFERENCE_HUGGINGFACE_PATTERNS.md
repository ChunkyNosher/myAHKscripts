# HuggingFace Space Patterns: Quick Reference

This is a **quick lookup guide** for the 7 architectural patterns used in the working HuggingFace Spaces implementation. Keep this open while implementing.

---

## Pattern 1: Audio Format Normalization

**Purpose:** Explicitly validate and normalize audio format before transcription

**What It Does:**
- Load audio with librosa (auto-detects format)
- Check sample rate matches model expectation (16kHz)
- Convert stereo to mono if needed
- Validate duration is reasonable (100ms - 24h)
- Validate audio is not corrupted (RMS check)

**Why It Matters:**
- Models expect exact format; preprocessing guarantees it
- Catches format issues upfront, not during transcription
- Prevents silent failures from format mismatches

**Key Code Pattern:**
```python
# Load and detect format
y, sr = librosa.load(path, sr=None)  # sr=None preserves original

# Validate duration
duration = librosa.get_duration(y=y, sr=sr)
if duration < 0.1 or duration > 86400:  # 100ms to 24h
    raise ValueError("Duration out of range")

# Resample to 16kHz if needed
if sr != 16000:
    y = librosa.resample(y, orig_sr=sr, target_sr=16000)

# Convert to mono if stereo
if y.ndim > 1:  # If 2D (stereo)
    y = librosa.to_mono(y)

# Check for silent audio
rms = librosa.feature.rms(y=y)
if rms.max() < 0.01:  # Very quiet
    print("⚠️ Audio is very quiet")
```

---

## Pattern 2: Pre-Access Output Validation

**Purpose:** Validate transcription result structure BEFORE accessing .text

**What It Does:**
1. Check result is not None
2. Check result is list
3. Check result is not empty
4. Check hypothesis has .text attribute
5. Check .text is string
6. Check .text is non-empty

**Why It Matters:**
- model.transcribe() sometimes returns malformed results
- Accessing .text without checks causes AttributeError
- Defensive checks catch NeMo edge cases gracefully

**Key Code Pattern:**
```python
def validate_transcription_result(result, idx=0):
    """Validate transcription result before accessing."""
    
    if result is None:
        return False, "", "Result is None"
    
    if not isinstance(result, list):
        return False, "", f"Result is {type(result)}, not list"
    
    if len(result) == 0:
        return False, "", "Result is empty list"
    
    if idx >= len(result):
        return False, "", f"Index {idx} out of range"
    
    hypothesis = result[idx]
    
    if not hasattr(hypothesis, 'text'):
        return False, "", "Hypothesis has no .text attribute"
    
    if not isinstance(hypothesis.text, str):
        return False, "", f".text is {type(hypothesis.text)}, not string"
    
    if len(hypothesis.text) == 0:
        return False, "", ".text is empty string"
    
    return True, hypothesis.text, ""
```

---

## Pattern 3: Explicit Device Management

**Purpose:** Manage GPU VRAM by moving models between devices

**What It Does:**
- When loading new model, unload old one from VRAM
- Move old model to CPU (saves VRAM)
- Delete reference to free memory
- Empty CUDA cache
- Force garbage collection
- Load new model to CUDA

**Why It Matters:**
- Multiple models in VRAM → OOM errors
- Explicit cleanup allows seamless model switching
- Essential for long-running Gradio interfaces

**Key Code Pattern:**
```python
def load_model_with_device_management(model_key):
    """Load model with explicit device management."""
    
    # Check if different model already cached
    if 'current_model_key' in globals():
        if current_model_key != model_key:
            # Unload old model
            old_model = models_cache.get(current_model_key)
            if old_model is not None:
                old_model = old_model.to("cpu")
                del old_model
                del models_cache[current_model_key]
                torch.cuda.empty_cache()
                gc.collect()
    
    # Load new model
    if model_key not in models_cache:
        model = ASRModel.from_pretrained(MODEL_CONFIGS[model_key]['hf_model_id'])
        if torch.cuda.is_available():
            model = model.to("cuda")
        models_cache[model_key] = model
    
    return models_cache[model_key]
```

---

## Pattern 4: Defensive Timestamp Extraction

**Purpose:** Extract timestamps with graceful fallbacks when data unavailable

**What It Does:**
1. Try to extract word-level timestamps
2. If missing, fallback to segment-level
3. If both missing, return empty list
4. Use try/except around all attribute access

**Why It Matters:**
- Different models produce different timestamp granularity
- Accessing non-existent keys raises KeyError
- Graceful degradation ensures users get something

**Key Code Pattern:**
```python
def extract_timestamps(hypothesis, include_timestamps=False):
    """Extract timestamps with word→segment→none fallback."""
    
    if not include_timestamps:
        return [], 'none'
    
    # Try word-level
    try:
        if hasattr(hypothesis, 'timestamp') and hypothesis.timestamp:
            if isinstance(hypothesis.timestamp, dict):
                if 'word' in hypothesis.timestamp:
                    word_ts = hypothesis.timestamp['word']
                    if isinstance(word_ts, list) and len(word_ts) > 0:
                        return word_ts, 'word'
    except (AttributeError, KeyError, TypeError):
        pass
    
    # Fallback to segment-level
    try:
        if hasattr(hypothesis, 'timestamp') and hypothesis.timestamp:
            if isinstance(hypothesis.timestamp, dict):
                if 'segment' in hypothesis.timestamp:
                    segment_ts = hypothesis.timestamp['segment']
                    if isinstance(segment_ts, list) and len(segment_ts) > 0:
                        return segment_ts, 'segment'
    except (AttributeError, KeyError, TypeError):
        pass
    
    # Both failed, return empty
    return [], 'none'
```

---

## Pattern 5: Per-File Batch Validation

**Purpose:** Process batch files individually with error recovery

**What It Does:**
- Loop through each file individually (not bulk)
- Wrap each file in try/except
- Validate each result before accessing
- Collect successes and errors separately
- Return per-file status

**Why It Matters:**
- One bad file shouldn't break entire batch
- Users need to know which files failed
- Allows partial completion reporting

**Key Code Pattern:**
```python
def transcribe_batch(file_list, model):
    """Transcribe batch with per-file error recovery."""
    
    results = []
    errors = []
    
    for i, file_path in enumerate(file_list):
        try:
            single_result = model.transcribe([file_path])
            
            success, text, error = validate_transcription_result(single_result, 0)
            if not success:
                errors.append({
                    'index': i,
                    'filename': os.path.basename(file_path),
                    'error': error
                })
                results.append(None)
                continue
            
            results.append(text)
            
        except Exception as e:
            errors.append({
                'index': i,
                'filename': os.path.basename(file_path),
                'error': str(e)
            })
            results.append(None)
    
    return results, errors
```

---

## Pattern 6: Stage-Specific Error Messages

**Purpose:** Provide actionable error messages based on failure stage

**What It Does:**
- Define error categories (audio_load, format, model_load, etc.)
- Each category has title and actionable advice
- Return stage-specific message based on where failure occurred

**Why It Matters:**
- Generic "Error During Transcription" doesn't help users
- Stage-specific errors guide exact corrective action
- Reduces support burden

**Key Code Pattern:**
```python
ERROR_MESSAGES = {
    'audio_load_failed': {
        'title': '❌ Could Not Load Audio File',
        'message': 'Check that:\n'
                   '- File format is supported\n'
                   '- File is not corrupted\n'
                   '- File permissions are readable'
    },
    'format_unsupported': {
        'title': '❌ Audio Format Not Supported',
        'message': 'Supported: WAV, MP3, FLAC, M4A, OGG, AAC, WMA\n'
                   'Video: MP4, AVI, MKV, MOV (audio extracted)'
    },
    'duration_invalid': {
        'title': '❌ Invalid Audio Duration',
        'message': 'Audio must be 100ms to 24 hours.\n'
                   'Check for corruption or silence.'
    },
}

def format_error(error_type, detail=""):
    msg = ERROR_MESSAGES.get(error_type, {})
    return f"### {msg['title']}\n\n{msg['message']}\n\n{detail}"
```

---

## Pattern 7: Timestamp Level Indicator in Status

**Purpose:** Show users what timestamp granularity they got

**What It Does:**
- In status message, indicate timestamp level used
- Word-level: "✅ Word-level timestamps available"
- Segment-level: "⚠️ Word-level unavailable, showing segment-level"
- None: "ℹ️ Timestamps not available for this model"

**Why It Matters:**
- Transparent about capabilities
- Users know why they got certain results
- Prevents confusion

**Key Code Pattern:**
```python
# After extracting timestamps
timestamps, level = extract_timestamps(result[0], include_timestamps)

# Build status based on level
timestamp_status = ""
if include_timestamps:
    if level == 'word':
        timestamp_status = "\n✅ **Timestamps:** Word-level available"
    elif level == 'segment':
        timestamp_status = "\n⚠️ **Timestamps:** Segment-level (word-level unavailable)"
    elif level == 'none':
        timestamp_status = "\nℹ️ **Timestamps:** Not available for this model"

status_message += timestamp_status
```

---

## Pattern Checklist

When implementing all 7 patterns:

- [ ] Pattern 1: Audio validation function exists, resamples to 16kHz, converts to mono
- [ ] Pattern 2: Output validation before any .text access
- [ ] Pattern 3: load_model() manages device state explicitly
- [ ] Pattern 4: Timestamp extraction handles word→segment→none fallback
- [ ] Pattern 5: Batch processing validates per-file, collects errors
- [ ] Pattern 6: Error messages are stage-specific with actionable advice
- [ ] Pattern 7: Status shows timestamp level used

---

## Test Each Pattern

| Pattern | Test Case | Expected Result |
|---------|-----------|-----------------|
| 1 | Upload 44kHz stereo MP3 | Auto-resampled to 16kHz mono, success |
| 2 | Model returns None | Error: "Result is None" not crash |
| 3 | Switch Parakeet→Canary | Old model unloaded, VRAM freed, no OOM |
| 4 | Model without word timestamps | Shows segment-level, not empty |
| 5 | Batch with 1 corrupt file | 4 succeed, 1 shows error |
| 6 | Audio load fails | "Could Not Load Audio File" with advice |
| 7 | Timestamps extracted | Status shows "✅ Word-level" or "⚠️ Segment-level" |

---

**Remember:** These patterns aren't complex. They're simple, defensive best practices that prevent silent failures and make debugging easy. HuggingFace Space has been using them successfully in production.
