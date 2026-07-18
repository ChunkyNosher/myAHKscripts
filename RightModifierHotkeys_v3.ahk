; This if statement makes the script run as admin. Without it, trying to use this script while having Task Manager (and probably any other Windows Menu active, but I haven't tested it) open causes a bug where it will make you unable to type on your keyboard even after clicking out of Task Manager until you press down RCtrl again
if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}



; Custom modifier tracking system
global rctrlPressed := false
global raltPressed := false
global rshiftPressed := false

; =============================================
; HOTKEY CONFIGURATION - OBJECT NOTATION WITH ALL MODIFIERS
; =============================================

global HotkeyConfig := {}

; === NUMBER ROW ===
HotkeyConfig["SC002"] := { "RCtrl": "^{F14}", "RAlt": "!{F14}", "RShift": "+{F14}", "RCtrl_RAlt": "^!{F14}", "RCtrl_RShift": "^+{F14}", "RAlt_RShift": "!+{F14}", "RCtrl_RAlt_RShift": "^!+{F14}" } ; "1"
HotkeyConfig["SC003"] := { "RCtrl": "^{F15}", "RAlt": "!{F15}", "RShift": "+{F15}", "RCtrl_RAlt": "^!{F15}", "RCtrl_RShift": "^+{F15}", "RAlt_RShift": "!+{F15}", "RCtrl_RAlt_RShift": "^!+{F15}" } ; "2"
HotkeyConfig["SC004"] := { "RCtrl": "^{F16}", "RAlt": "!{F16}", "RShift": "+{F16}", "RCtrl_RAlt": "^!{F16}", "RCtrl_RShift": "^+{F16}", "RAlt_RShift": "!+{F16}", "RCtrl_RAlt_RShift": "^!+{F16}" } ; "3"
HotkeyConfig["SC005"] := { "RCtrl": "^{F17}", "RAlt": "!{F17}", "RShift": "+{F17}", "RCtrl_RAlt": "^!{F17}", "RCtrl_RShift": "^+{F17}", "RAlt_RShift": "!+{F17}", "RCtrl_RAlt_RShift": "^!+{F17}" } ; "4"
HotkeyConfig["SC006"] := { "RCtrl": "^{F18}", "RAlt": "!{F18}", "RShift": "+{F18}", "RCtrl_RAlt": "^!{F18}", "RCtrl_RShift": "^+{F18}", "RAlt_RShift": "!+{F18}", "RCtrl_RAlt_RShift": "^!+{F18}" } ; "5"
HotkeyConfig["SC007"] := { "RCtrl": "^{F19}", "RAlt": "!{F19}", "RShift": "+{F19}", "RCtrl_RAlt": "^!{F19}", "RCtrl_RShift": "^+{F19}", "RAlt_RShift": "!+{F19}", "RCtrl_RAlt_RShift": "^!+{F19}" } ; "6"
HotkeyConfig["SC008"] := { "RCtrl": "^{F20}", "RAlt": "!{F20}", "RShift": "+{F20}", "RCtrl_RAlt": "^!{F20}", "RCtrl_RShift": "^+{F20}", "RAlt_RShift": "!+{F20}", "RCtrl_RAlt_RShift": "^!+{F20}" } ; "7"
HotkeyConfig["SC009"] := { "RCtrl": "^{F21}", "RAlt": "!{F21}", "RShift": "+{F21}", "RCtrl_RAlt": "^!{F21}", "RCtrl_RShift": "^+{F21}", "RAlt_RShift": "!+{F21}", "RCtrl_RAlt_RShift": "^!+{F21}" } ; "8"
HotkeyConfig["SC00A"] := { "RCtrl": "^{F22}", "RAlt": "!{F22}", "RShift": "+{F22}", "RCtrl_RAlt": "^!{F22}", "RCtrl_RShift": "^+{F22}", "RAlt_RShift": "!+{F22}", "RCtrl_RAlt_RShift": "^!+{F22}" } ; "9"
HotkeyConfig["SC00B"] := { "RCtrl": "^{F13}", "RAlt": "!{F13}", "RShift": "+{F13}", "RCtrl_RAlt": "^!{F13}", "RCtrl_RShift": "^+{F13}", "RAlt_RShift": "!+{F13}", "RCtrl_RAlt_RShift": "^!+{F13}" } ; "0"

; === LETTERS ===
HotkeyConfig["SC01E"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "a"
HotkeyConfig["SC030"] := { "RCtrl": "LaunchZen", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "b"
HotkeyConfig["SC02E"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "c"
HotkeyConfig["SC020"] := { "RCtrl": "", "RAlt": "", "RShift": "^c", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "d"
HotkeyConfig["SC012"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "e"
HotkeyConfig["SC021"] := { "RCtrl": "LaunchFocusrite", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "f"
HotkeyConfig["SC022"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "g"
HotkeyConfig["SC023"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "h"
HotkeyConfig["SC017"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "i"
HotkeyConfig["SC024"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "j"
HotkeyConfig["SC025"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "k"
HotkeyConfig["SC026"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "l"
HotkeyConfig["SC032"] := { "RCtrl": "LaunchOneCommander", "RAlt": "!{F23}", "RShift": "+{F23}", "RCtrl_RAlt": "", "RCtrl_RShift": "OpenAllFolders", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "m"
HotkeyConfig["SC031"] := { "RCtrl": "LaunchPremiere", "RAlt": "", "RShift": "ActivateNotepadPlusPlus", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "n"
HotkeyConfig["SC018"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "o"
HotkeyConfig["SC019"] := { "RCtrl": "ActivateNotepadPlusPlus", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "p"
HotkeyConfig["SC010"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "q"
HotkeyConfig["SC013"] := { "RCtrl": "ToggleRandomWigglerPremiere", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "r"
HotkeyConfig["SC01F"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "s"
HotkeyConfig["SC014"] := { "RCtrl": "ToggleAlwaysOnTop", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "t"
HotkeyConfig["SC016"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "u"
HotkeyConfig["SC02F"] := { "RCtrl": "ActivateVSCode", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "v"
HotkeyConfig["SC011"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "w"
HotkeyConfig["SC02D"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "x"
HotkeyConfig["SC015"] := { "RCtrl": "LaunchYTDlpBatch", "RAlt": "LaunchYTDlpBatchChecker", "RShift": "yt-dlp -t mp4", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "y"
HotkeyConfig["SC02C"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "z"

; === FUNCTION KEYS ===
HotkeyConfig["SC03B"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F1"
HotkeyConfig["SC03C"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F2"
HotkeyConfig["SC03D"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F3"
HotkeyConfig["SC03E"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F4"
HotkeyConfig["SC03F"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F5"
HotkeyConfig["SC040"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F6"
HotkeyConfig["SC041"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F7"
HotkeyConfig["SC042"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F8"
HotkeyConfig["SC043"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F9"
HotkeyConfig["SC044"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F10"
HotkeyConfig["SC057"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F11"
HotkeyConfig["SC058"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "F12"

; === SYMBOLS ===
HotkeyConfig["SC027"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; ";"
HotkeyConfig["SC033"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; ","
HotkeyConfig["SC034"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "."
HotkeyConfig["SC035"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "/"
HotkeyConfig["SC01A"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "["
HotkeyConfig["SC01B"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "]"
HotkeyConfig["SC02B"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "\"
HotkeyConfig["SC028"] := { "RCtrl": "", "RAlt": "", "RShift": "^x", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "'"
HotkeyConfig["SC00C"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "-"
HotkeyConfig["SC00D"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "="
HotkeyConfig["SC029"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "`"

; === NAVIGATION KEYS ===
HotkeyConfig["SC148"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Up"
HotkeyConfig["SC150"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Down"
HotkeyConfig["SC14B"] := { "RCtrl": "SlideInFromLeft", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Left"
HotkeyConfig["SC14D"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Right"
HotkeyConfig["SC147"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Home"
HotkeyConfig["SC14F"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "End"
HotkeyConfig["SC149"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "PgUp"
HotkeyConfig["SC151"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "PgDn"
HotkeyConfig["SC152"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Insert"
HotkeyConfig["SC153"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Delete"

; === NUMPAD KEYS ===
HotkeyConfig["SC052"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Numpad0"
HotkeyConfig["SC04F"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Numpad1"
HotkeyConfig["SC050"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Numpad2"
HotkeyConfig["SC051"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Numpad3"
HotkeyConfig["SC04B"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Numpad4"
HotkeyConfig["SC04C"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Numpad5"
HotkeyConfig["SC04D"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Numpad6"
HotkeyConfig["SC047"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Numpad7"
HotkeyConfig["SC048"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Numpad8"
HotkeyConfig["SC049"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "Numpad9"
HotkeyConfig["SC053"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "NumpadDot"
HotkeyConfig["NumpadEnter"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "NumpadEnter"
HotkeyConfig["SC04E"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "NumpadAdd"
HotkeyConfig["SC04A"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "NumpadSub"
HotkeyConfig["SC037"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "NumpadMult"
HotkeyConfig["NumpadDiv"] := { "RCtrl": "", "RAlt": "", "RShift": "", "RCtrl_RAlt": "", "RCtrl_RShift": "", "RAlt_RShift": "", "RCtrl_RAlt_RShift": "" } ; "NumpadDiv"

; =============================================
; MODIFIER TRACKING
; =============================================

; Track RCtrl without using GetKeyState
$RCtrl::
    rctrlPressed := true
    KeyWait, RCtrl, T2.0
    if (ErrorLevel = 0) {
        ; Released within 2 seconds - block input
        rctrlPressed := false
    } else {
        ; Held longer - wait for natural release
        KeyWait, RCtrl
        rctrlPressed := false
    }
return

; Track RAlt
$RAlt::
    raltPressed := true
    KeyWait, RAlt, T2.0
    if (ErrorLevel = 0) {
        raltPressed := false
    } else {
        KeyWait, RAlt
        raltPressed := false
    }
return

; Track RShift
$RShift::
    rshiftPressed := true
    KeyWait, RShift, T2.0
    if (ErrorLevel = 0) {
        rshiftPressed := false
    } else {
        KeyWait, RShift
        rshiftPressed := false
    }
return

; =============================================
; HOTKEY HANDLER FUNCTION
; =============================================

HandleHotkey(key) {
    global rctrlPressed, raltPressed, rshiftPressed, HotkeyConfig
    
    config := HotkeyConfig[key]
    if (!IsObject(config)) {
        return
    }
    
    ; Determine modifier combination and build lookup key
    lookupKey := ""
    if (rctrlPressed && raltPressed && rshiftPressed) {
        lookupKey := "RCtrl_RAlt_RShift"
    } else if (rctrlPressed && raltPressed) {
        lookupKey := "RCtrl_RAlt"
    } else if (rctrlPressed && rshiftPressed) {
        lookupKey := "RCtrl_RShift"
    } else if (raltPressed && rshiftPressed) {
        lookupKey := "RAlt_RShift"
    } else if (rctrlPressed) {
        lookupKey := "RCtrl"
    } else if (raltPressed) {
        lookupKey := "RAlt"
    } else if (rshiftPressed) {
        lookupKey := "RShift"
    }
    
    ; Execute action if defined for this modifier combination
    if (lookupKey != "" && config[lookupKey] != "") {
        action := config[lookupKey]
        if (IsFunc(action)) {
            %action%()
			return
        } else {
            SendInput, %action%
			return
        }
    }
}

; =============================================
; CUSTOM ACTION FUNCTIONS
; =============================================

#Include Premiere Preset Hotkeys.ahk

LaunchYTDlpBatch() {
    static batchPID := 0
    
    ; Check if we already have a stored PID and if the process still exists
    if (batchPID != 0) {
        Process, Exist, %batchPID%
        if (ErrorLevel = batchPID) {
            ; Process exists, activate its window
            WinActivate, ahk_pid %batchPID%
            return
        } else {
            ; Process no longer exists, reset PID
            batchPID := 0
        }
    }
    
    ; No existing process found, launch a new one
    Run, "E:\Chunky's Master Folder\myEditingScripts\yt-dlp batch downloader.bat", , , batchPID
    
    ; Wait a bit for the process to start and store the PID
    Sleep, 1000
    if (batchPID = 0) {
        ; If Run didn't give us a PID, try to find it by window class
        WinWait, ahk_class ConsoleWindowClass, , 3
        if (ErrorLevel = 0) {
            WinGet, batchPID, PID, A
        }
    }
}

LaunchYTDlpBatchChecker() {
    static batchPID := 0
    
    ; Check if we already have a stored PID and if the process still exists
    if (batchPID != 0) {
        Process, Exist, %batchPID%
        if (ErrorLevel = batchPID) {
            ; Process exists, activate its window
            WinActivate, ahk_pid %batchPID%
            return
        } else {
            ; Process no longer exists, reset PID
            batchPID := 0
        }
    }
    
    ; No existing process found, launch a new one
    Run, "E:\Chunky's Master Folder\myEditingScripts\yt-dlp-format-checker.bat", , , batchPID
    
    ; Wait a bit for the process to start and store the PID
    Sleep, 1000
    if (batchPID = 0) {
        ; If Run didn't give us a PID, try to find it by window class
        WinWait, ahk_class ConsoleWindowClass, , 3
        if (ErrorLevel = 0) {
            WinGet, batchPID, PID, A
        }
    }
}

LaunchArc() {
    IfWinNotExist, ahk_exe Arc.exe
        Run, Arc.exe
    WinActivate, ahk_exe Arc.exe
}

LaunchZen() {
    IfWinNotExist, ahk_exe zen.exe
        Run, Zen.exe
    WinActivate, ahk_exe zen.exe
}

LaunchFocusrite() {
    IfWinNotExist, ahk_exe Focusrite Notifier.exe
        Run, C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Focusrite Drivers\Focusrite Device Settings.lnk
    WinActivate, ahk_exe Focusrite Notifier.exe
}

ActivateExplorer() {
    IfWinNotExist, ahk_class CabinetWClass
        Run, explorer.exe
    GroupAdd, ChunkyFiles, ahk_class CabinetWClass
    if WinActive("ahk_exe explorer.exe")
        GroupActivate, ChunkyFiles, r
    else
        WinActivate ahk_class CabinetWClass
}

LaunchPremiere() {
    IfWinNotExist, ahk_exe Adobe Premiere Pro.exe
        Run, Adobe Premiere Pro.exe
    WinActivate, ahk_exe Adobe Premiere Pro.exe
}

LaunchOneCommander() {
    IfWinNotExist, ahk_exe OneCommander.exe
        Run, OneCommander.exe
    GroupAdd, ChunkyFiles, ahk_exe OneCommander.exe
    if WinActive("ahk_exe OneCommander.exe")
        GroupActivate, ChunkyFiles, r
    else
        WinActivate, ahk_exe OneCommander.exe
}

ActivateNotepadPlusPlus() {
    IfWinNotExist, ahk_exe notepad++.exe
        Run, Notepad++.exe
    WinActivate, ahk_exe notepad++.exe
}

ActivateVSCode() {
    IfWinNotExist, ahk_exe Code - Insiders.exe
        Run, Visual Studio Code - Insiders
    GroupAdd, ChunkyVSCodeWindows, ahk_exe Code - Insiders.exe
    if WinActive("ahk_exe Code - Insiders.exe")
        GroupActivate, ChunkyVSCodeWindows, r
    else
        WinActivate, ahk_exe Code - Insiders.exe
}

ToggleRandomWigglerPremiere() {
	if WinActive("ahk_exe Adobe Premiere Pro.exe")
	{	
		SendInput, {Alt}
		SendInput, w
		SendInput, e
		SendInput, {Right}
		SendInput, r
	}
	else
		return
}
		

ToggleAlwaysOnTop() {
    ; Get the active window's HWND for reliable identification
    WinGet, activeHwnd, ID, A
    
    ; Check current always-on-top state BEFORE toggling
    WinGet, ExStyle, ExStyle, ahk_id %activeHwnd%
    
    ; Toggle the always-on-top state
    WinSet, AlwaysOnTop, Toggle, ahk_id %activeHwnd%
    
    ; Provide visual feedback via tooltip
    if (ExStyle & 0x8) {
        ; Was on top, now turned OFF
        ToolTip, Always On Top: OFF
    } else {
        ; Was not on top, now turned ON
        ToolTip, Always On Top: ON
    }
    
    ; Auto-hide tooltip after 1.5 seconds using label (v1.1 compatible)
    SetTimer, RemoveToolTip, -1500
}

RemoveToolTip:
    ToolTip
return




; =============================================
; HOTKEY DEFINITIONS
; =============================================

#If rctrlPressed || raltPressed || rshiftPressed

; === NUMBER ROW ===
SC002:: HandleHotkey("SC002") ; "1"
SC003:: HandleHotkey("SC003") ; "2"
SC004:: HandleHotkey("SC004") ; "3"
SC005:: HandleHotkey("SC005") ; "4"
SC006:: HandleHotkey("SC006") ; "5"
SC007:: HandleHotkey("SC007") ; "6"
SC008:: HandleHotkey("SC008") ; "7"
SC009:: HandleHotkey("SC009") ; "8"
SC00A:: HandleHotkey("SC00A") ; "9"
SC00B:: HandleHotkey("SC00B") ; "0"

; === LETTERS ===
SC01E:: HandleHotkey("SC01E") ; "a"
SC030:: HandleHotkey("SC030") ; "b"
SC02E:: HandleHotkey("SC02E") ; "c"
SC020:: HandleHotkey("SC020") ; "d"
SC012:: HandleHotkey("SC012") ; "e"
SC021:: HandleHotkey("SC021") ; "f"
SC022:: HandleHotkey("SC022") ; "g"
SC023:: HandleHotkey("SC023") ; "h"
SC017:: HandleHotkey("SC017") ; "i"
SC024:: HandleHotkey("SC024") ; "j"
SC025:: HandleHotkey("SC025") ; "k"
SC026:: HandleHotkey("SC026") ; "l"
SC032:: HandleHotkey("SC032") ; "m"
SC031:: HandleHotkey("SC031") ; "n"
SC018:: HandleHotkey("SC018") ; "o"
SC019:: HandleHotkey("SC019") ; "p"
SC010:: HandleHotkey("SC010") ; "q"
SC013:: HandleHotkey("SC013") ; "r"
SC01F:: HandleHotkey("SC01F") ; "s"
SC014:: HandleHotkey("SC014") ; "t"
SC016:: HandleHotkey("SC016") ; "u"
SC02F:: HandleHotkey("SC02F") ; "v"
SC011:: HandleHotkey("SC011") ; "w"
SC02D:: HandleHotkey("SC02D") ; "x"
SC015:: HandleHotkey("SC015") ; "y"
SC02C:: HandleHotkey("SC02C") ; "z"

; === FUNCTION KEYS ===
SC03B:: HandleHotkey("SC03B") ; "F1"
SC03C:: HandleHotkey("SC03C") ; "F2"
SC03D:: HandleHotkey("SC03D") ; "F3"
SC03E:: HandleHotkey("SC03E") ; "F4"
SC03F:: HandleHotkey("SC03F") ; "F5"
SC040:: HandleHotkey("SC040") ; "F6"
SC041:: HandleHotkey("SC041") ; "F7"
SC042:: HandleHotkey("SC042") ; "F8"
SC043:: HandleHotkey("SC043") ; "F9"
SC044:: HandleHotkey("SC044") ; "F10"
SC057:: HandleHotkey("SC057") ; "F11"
SC058:: HandleHotkey("SC058") ; "F12"

; === SYMBOLS ===
SC027:: HandleHotkey("SC027") ; ";"
SC033:: HandleHotkey("SC033") ; ","
SC034:: HandleHotkey("SC034") ; "."
SC035:: HandleHotkey("SC035") ; "/"
SC01A:: HandleHotkey("SC01A") ; "["
SC01B:: HandleHotkey("SC01B") ; "]"
SC02B:: HandleHotkey("SC02B") ; "\"
SC028:: HandleHotkey("SC028") ; "'"
SC00C:: HandleHotkey("SC00C") ; "-"
SC00D:: HandleHotkey("SC00D") ; "="
SC029:: HandleHotkey("SC029") ; "`"

; === NAVIGATION KEYS ===
SC148:: HandleHotkey("SC148") ; "Up"
SC150:: HandleHotkey("SC150") ; "Down"
SC14B:: HandleHotkey("SC14B") ; "Left"
SC14D:: HandleHotkey("SC14D") ; "Right"
SC147:: HandleHotkey("SC147") ; "Home"
SC14F:: HandleHotkey("SC14F") ; "End"
SC149:: HandleHotkey("SC149") ; "PgUp"
SC151:: HandleHotkey("SC151") ; "PgDn"
SC152:: HandleHotkey("SC152") ; "Insert"
SC153:: HandleHotkey("SC153") ; "Delete"

; === NUMPAD KEYS ===
SC052:: HandleHotkey("SC052") ; "Numpad0"
SC04F:: HandleHotkey("SC04F") ; "Numpad1"
SC050:: HandleHotkey("SC050") ; "Numpad2"
SC051:: HandleHotkey("SC051") ; "Numpad3"
SC04B:: HandleHotkey("SC04B") ; "Numpad4"
SC04C:: HandleHotkey("SC04C") ; "Numpad5"
SC04D:: HandleHotkey("SC04D") ; "Numpad6"
SC047:: HandleHotkey("SC047") ; "Numpad7"
SC048:: HandleHotkey("SC048") ; "Numpad8"
SC049:: HandleHotkey("SC049") ; "Numpad9"
SC053:: HandleHotkey("SC053") ; "NumpadDot"
NumpadEnter:: HandleHotkey("NumpadEnter") ; "NumpadEnter"
SC04E:: HandleHotkey("SC04E") ; "NumpadAdd"
SC04A:: HandleHotkey("SC04A") ; "NumpadSub"
SC037:: HandleHotkey("SC037") ; "NumpadMult"
NumpadDiv:: HandleHotkey("NumpadDiv") ; "NumpadDiv"

#If