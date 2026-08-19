#Requires AutoHotkey v2.0

RegisterBuiltInActions(registry) {
    BuiltIn_RegisterAction(registry, "launch_yt_dlp_batch", LaunchYtDlpBatch)
    BuiltIn_RegisterAction(registry, "launch_yt_dlp_batch_checker", LaunchYtDlpBatchChecker)
    BuiltIn_RegisterAction(registry, "launch_arc", LaunchArc)
    BuiltIn_RegisterAction(registry, "launch_zen", LaunchZen)
    BuiltIn_RegisterAction(registry, "launch_focusrite", LaunchFocusrite)
    BuiltIn_RegisterAction(registry, "activate_explorer", ActivateExplorer)
    BuiltIn_RegisterAction(registry, "launch_premiere", LaunchPremiere)
    BuiltIn_RegisterAction(registry, "launch_one_commander", LaunchOneCommander)
    BuiltIn_RegisterAction(registry, "activate_notepad_plus_plus", ActivateNotepadPlusPlus)
    BuiltIn_RegisterAction(registry, "activate_vscode", ActivateVSCode)
    BuiltIn_RegisterAction(registry, "toggle_random_wiggler_premiere", ToggleRandomWigglerPremiere)
    BuiltIn_RegisterAction(registry, "toggle_always_on_top", ToggleAlwaysOnTop)
}

LaunchYtDlpBatch() {
    static batchPid := 0
    return BuiltIn_LaunchBatchScript("E:\chunky-dev\myEditingScripts\yt-dlp batch downloader.bat", &batchPid)
}

LaunchYtDlpBatchChecker() {
    static batchPid := 0
    return BuiltIn_LaunchBatchScript("E:\chunky-dev\myEditingScripts\yt-dlp-format-checker.bat", &batchPid)
}

LaunchArc() {
    if !WinExist("ahk_exe Arc.exe") {
        Run("Arc.exe")
    }
    WinActivate("ahk_exe Arc.exe")
}

LaunchZen() {
    if !WinExist("ahk_exe zen.exe") {
        Run("Zen.exe")
    }
    WinActivate("ahk_exe zen.exe")
}

LaunchFocusrite() {
    if !WinExist("ahk_exe Focusrite Notifier.exe") {
        Run("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Focusrite Drivers\Focusrite Device Settings.lnk")
    }
    WinActivate("ahk_exe Focusrite Notifier.exe")
}

ActivateExplorer() {
    if !WinExist("ahk_class CabinetWClass") {
        Run("explorer.exe")
    }
    GroupAdd(BUILTIN_FILES_GROUP_NAME, "ahk_class CabinetWClass")
    if WinActive("ahk_exe explorer.exe") {
        GroupActivate(BUILTIN_FILES_GROUP_NAME, "R")
    } else {
        WinActivate("ahk_class CabinetWClass")
    }
}

LaunchPremiere() {
    if !WinExist("ahk_exe Adobe Premiere Pro.exe") {
        Run("Adobe Premiere Pro.exe")
    }
    WinActivate("ahk_exe Adobe Premiere Pro.exe")
}

LaunchOneCommander() {
    if !WinExist("ahk_exe OneCommander.exe") {
        Run("OneCommander.exe")
    }
    GroupAdd(BUILTIN_FILES_GROUP_NAME, "ahk_exe OneCommander.exe")
    if WinActive("ahk_exe OneCommander.exe") {
        GroupActivate(BUILTIN_FILES_GROUP_NAME, "R")
    } else {
        WinActivate("ahk_exe OneCommander.exe")
    }
}

ActivateNotepadPlusPlus() {
    if !WinExist("ahk_exe notepad++.exe") {
        Run("Notepad++.exe")
    }
    WinActivate("ahk_exe notepad++.exe")
}

ActivateVSCode() {
    if !WinExist("ahk_exe Code - Insiders.exe") {
        Run("Visual Studio Code - Insiders")
    }
    GroupAdd(BUILTIN_VSCODE_GROUP_NAME, "ahk_exe Code - Insiders.exe")
    if WinActive("ahk_exe Code - Insiders.exe") {
        GroupActivate(BUILTIN_VSCODE_GROUP_NAME, "R")
    } else {
        WinActivate("ahk_exe Code - Insiders.exe")
    }
}

ToggleRandomWigglerPremiere() {
    if !WinActive("ahk_exe Adobe Premiere Pro.exe") {
        return false
    }

    SendInput("{Alt}")
    SendInput("w")
    SendInput("e")
    SendInput("{Right}")
    SendInput("r")
    return true
}

ToggleAlwaysOnTop() {
    hwnd := WinExist("A")
    if !hwnd {
        return false
    }

    exStyle := WinGetExStyle("ahk_id " hwnd)
    WinSetAlwaysOnTop(-1, "ahk_id " hwnd)

    ; 0x8 indicates the topmost extended window style before the toggle.
    ToolTip((exStyle & 0x8) ? "Always On Top: OFF" : "Always On Top: ON")
    SetTimer(BuiltIn_RemoveAlwaysOnTopToolTip, -1500)
    return true
}

BuiltIn_RegisterAction(registry, actionId, callback) {
    if HasMethod(registry, "Register") {
        registry.Register(actionId, callback)
        return
    }

    if registry is Map {
        registry[actionId] := callback
        return
    }

    throw TypeError("Registry must expose Register() or be a Map.")
}

BuiltIn_LaunchBatchScript(scriptPath, &batchPid) {
    if batchPid && ProcessExist(batchPid) {
        if WinExist("ahk_pid " batchPid) {
            WinActivate("ahk_pid " batchPid)
        }
        return batchPid
    }

    batchPid := 0
    Run(scriptPath, , , &batchPid)
    Sleep(1000)

    if !batchPid {
        try {
            if WinWait("ahk_class ConsoleWindowClass",, 3) {
                batchPid := WinGetPID("A")
            }
        }
    }

    return batchPid
}

BuiltIn_RemoveAlwaysOnTopToolTip() {
    ToolTip()
}

global BUILTIN_FILES_GROUP_NAME := "RightModifierHotkeysV4_Files"
global BUILTIN_VSCODE_GROUP_NAME := "RightModifierHotkeysV4_VSCode"