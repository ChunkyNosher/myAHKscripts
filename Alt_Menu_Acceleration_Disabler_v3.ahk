Menu, Tray, Icon, shell32.dll, 110
#SingleInstance force
#InstallKeybdHook

; ORIGINAL WORKING SCRIPT WITH ALT-UP REPEAT FUNCTIONALITY
global LAltDisabled := false
global LetterKeyPressed := false
global CurrentLetter := ""
global ProcessingCombo := false
global SendingAltUp := false

; EXPANDED: Application-specific suspension list
; Add any applications you want to disable the script for (use window titles or ahk_exe)
; Examples of different formats you can use:
SuspensionList := 
(
"ahk_exe FortniteClient-Win64-Shipping.exe
ahk_exe notepad.exe
ahk_exe chrome.exe
Calculator
Microsoft Word
ahk_exe Overwatch.exe
ahk_exe GeometryDash.exe
ahk_exe OneCommander.exe
ahk_exe WindowsTerminal.exe
ahk_exe zen.exe"
)

SetTimer, CheckActiveWindow, 100  ; Check every second
CheckActiveWindow:
    ; Check if active window matches any in our suspension list
    ShouldSuspend := false
    Loop, Parse, SuspensionList, `n, `r  ; Parse by newlines, ignore blank lines
    {
        if (A_LoopField = "")  ; Skip empty lines
            continue
            
        if (WinActive(A_LoopField)) {
            ShouldSuspend := true
            break
        }
    }
    
    if (ShouldSuspend) {
        if (!A_IsSuspended) {
            Suspend, On
            ; Reset all states when suspending
            LAltDisabled := false
            LetterKeyPressed := false
            CurrentLetter := ""
            ProcessingCombo := false
            SendingAltUp := false
            SetTimer, WatchForLetters, Off
            SetTimer, WaitForLetterRelease, Off
            SetTimer, SendAltUpLoop, Off
            SetTimer, StartAltUpLoop, Off
            ; Optional: Show tooltip notification
            ; ToolTip, Alt Menu Disabler SUSPENDED
            ; SetTimer, RemoveToolTip, -2000
        }
    } else {
        if (A_IsSuspended) {
            Suspend, Off
            ; Optional: Show tooltip notification
            ; ToolTip, Alt Menu Disabler ACTIVE
            ; SetTimer, RemoveToolTip, -2000
        }
    }
return

; Optional: Remove tooltip after 2 seconds
RemoveToolTip:
    ToolTip
return

~LAlt::
    if (ProcessingCombo)
        return
    SetTimer, WatchForLetters, 1
    return

~LAlt up::
    SetTimer, WatchForLetters, Off
    SetTimer, WaitForLetterRelease, Off
    ; Stop sending AltUp if active
    SendingAltUp := false
    SetTimer, SendAltUpLoop, Off
    if (LAltDisabled) {
        LAltDisabled := false
        LetterKeyPressed := false
        CurrentLetter := ""
    }
    return

WatchForLetters:
    if (GetKeyState("LAlt", "P") && !ProcessingCombo) {
        letters := "abcdefghijklmnopqrstuvwxyz"
        Loop, Parse, letters
        {
            if (GetKeyState(A_LoopField, "P")) {
                if (!LetterKeyPressed || CurrentLetter != A_LoopField) {
                    ProcessingCombo := true
                    LetterKeyPressed := true
                    CurrentLetter := A_LoopField
                    LAltDisabled := true
                    
                    ; Send the Alt+letter combination manually
                    SendInput {Alt down}{%A_LoopField%}{Alt up}
                    
                    ; Start monitoring for long press to send repeated AltUp
                    SetTimer, StartAltUpLoop, -400
                    
                    ; If LAlt is still physically pressed, keep it disabled
                    if (GetKeyState("LAlt", "P")) {
                        ; Continue monitoring for this letter's release
                        SetTimer, WaitForLetterRelease, 1
                    } else {
                        ; LAlt was released, re-enable it
                        LAltDisabled := false
                        LetterKeyPressed := false
                        SendingAltUp := false
                        SetTimer, SendAltUpLoop, Off
                    }
                    ProcessingCombo := false
                }
                break
            }
        }
    }
    return

; Start sending AltUp after 400ms hold
StartAltUpLoop:
    ; Check if both keys are still held after 400ms
    if (GetKeyState("LAlt", "P") && GetKeyState(CurrentLetter, "P")) {
        SendingAltUp := true
        SetTimer, SendAltUpLoop, 10  ; Start sending AltUp every 10ms
    }
    return

; Loop that sends AltUp while keys are held
SendAltUpLoop:
    if (SendingAltUp && GetKeyState("LAlt", "P") && GetKeyState(CurrentLetter, "P")) {
        SendInput, {Alt up}
        Sleep, 5 ; Small delay to ensure the release is registered
        SendInput, {Alt down} ; Immediately press Alt down again to maintain state
    } else {
        ; Stop the loop if keys are released or SendingAltUp is false
        SetTimer, SendAltUpLoop, Off
        SendingAltUp := false
        ; Ensure Alt is in the correct state when we stop
        if (GetKeyState("LAlt", "P")) {
            SendInput, {Alt down}
        }
    }
    return

WaitForLetterRelease:
    ; Wait for the letter key to be released
    if (!GetKeyState(CurrentLetter, "P")) {
        ; Letter was released - stop AltUp loop
        SendingAltUp := false
        SetTimer, SendAltUpLoop, Off
        
        ; Ensure Alt state is correct
        if (GetKeyState("LAlt", "P")) {
            SendInput, {Alt down}
            LAltDisabled := false
            LetterKeyPressed := false
            ; Continue monitoring for new letters
            SetTimer, WatchForLetters, 1
        } else {
            ; LAlt was also released - clean up
            LAltDisabled := false
            LetterKeyPressed := false
            CurrentLetter := ""
        }
        SetTimer, WaitForLetterRelease, Off
    }
    return

; DYNAMIC LALT HOTKEY - Only active when LAltDisabled = true
#If LAltDisabled
LAlt::return
#If

LAlt & RAlt::Suspend, Toggle
^!r::Reload
^!x::ExitApp