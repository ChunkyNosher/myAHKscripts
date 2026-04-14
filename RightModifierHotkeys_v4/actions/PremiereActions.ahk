#Requires AutoHotkey v2.0

RegisterPremiereActions(registry) {
    Premiere_RegisterAction(registry, "slide_in_from_left", SlideInFromLeft)
}

ApplySlidePreset(presetName) {
    if !WinActive("ahk_exe Adobe Premiere Pro.exe") {
        return false
    }

    CoordMode("Mouse", "Screen")
    CoordMode("Caret", "Screen")

    BlockInput("SendAndMouse")
    BlockInput("MouseMove")
    BlockInput("On")

    try {
        MouseGetPos(&origX, &origY)
        Send("^+E")
        Send("^!+F")

        if !Premiere_WaitForCaret() {
            return false
        }

        Send("{BS}")
        SendText(presetName)

        if !Premiere_WaitForCaret() {
            return false
        }

        MouseMove(A_CaretX, A_CaretY)
        MouseMove(A_CaretX + 41, A_CaretY + 63)
        MouseGetPos(&fxX, &fxY)
        MouseClickDrag("L", fxX, fxY, origX, origY, 0)
        return true
    } finally {
        BlockInput("MouseMoveOff")
        BlockInput("Off")
    }
}

SlideInFromLeft() {
    return ApplySlidePreset("Slide in from left")
}

Premiere_RegisterAction(registry, actionId, callback) {
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

Premiere_WaitForCaret(maxChecks := 40, sleepMs := 33) {
    if A_CaretX != "" {
        return true
    }

    loop maxChecks {
        Sleep(sleepMs)
        if A_CaretX != "" {
            return true
        }
    }

    return false
}