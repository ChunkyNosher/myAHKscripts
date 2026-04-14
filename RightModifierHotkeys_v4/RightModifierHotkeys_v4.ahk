#Requires AutoHotkey v2.0
#SingleInstance Force

SetWorkingDir(A_ScriptDir)

#Include %A_ScriptDir%\lib\Json.ahk
#Include %A_ScriptDir%\core\Schema.ahk
#Include %A_ScriptDir%\core\BindingStore.ahk
#Include %A_ScriptDir%\core\ActionRegistry.ahk
#Include %A_ScriptDir%\core\HotkeyEngine.ahk
#Include %A_ScriptDir%\gui\MainEditor.ahk

#Include %A_ScriptDir%\actions\BuiltInActions.ahk
#Include %A_ScriptDir%\actions\OpenFoldersActions.ahk
#Include %A_ScriptDir%\actions\PremiereActions.ahk
#Include %A_ScriptDir%\RightModifierHotkeys_v4.user-actions.ahk

global g_App := App_Boot()

if g_App["validateOnly"] {
    ExitApp
}

return

App_Boot() {
    validateOnly := App_HasFlag("--validate-only")

    if App_ShouldElevate(validateOnly) {
        App_RelaunchAsAdmin()
    }

    store := BindingStore(A_ScriptDir "\RightModifierHotkeys_v4.config.json", A_ScriptDir "\RightModifierHotkeys_v4.defaults.json")
    registry := ActionRegistry()

    RegisterBuiltInActions(registry)
    RegisterOpenFoldersActions(registry)
    RegisterPremiereActions(registry)
    RegisterUserActions(registry)

    engine := HotkeyEngine(store, registry)
    engine.Install()

    App_SetupTrayMenu()

    return Map(
        "validateOnly", validateOnly,
        "store", store,
        "registry", registry,
        "engine", engine
    )
}

App_HasFlag(flag) {
    for _, arg in A_Args {
        if (arg = flag) {
            return true
        }
    }
    return false
}

App_ShouldElevate(validateOnly) {
    if validateOnly {
        return false
    }

    if A_IsAdmin {
        return false
    }

    return !App_HasFlag("--no-elevate")
}

App_RelaunchAsAdmin() {
    argsText := ""
    for _, arg in A_Args {
        argsText .= (argsText = "" ? "" : " ") arg
    }

    command := '*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"'
    if (argsText != "") {
        command .= " " argsText
    }

    Run(command)
    ExitApp
}

App_SetupTrayMenu() {
    A_IconTip := "RightModifierHotkeys v4"
    A_TrayMenu.Add()
    A_TrayMenu.Add("Open Editor", App_OpenEditor)
    A_TrayMenu.Add("Reload Config", App_ReloadConfig)
    A_TrayMenu.Add("Suspend Hotkeys", App_ToggleSuspend)
    A_TrayMenu.Add("Exit", App_Exit)
}

App_OpenEditor(*) {
    global g_App
    MainEditor.Open(g_App)
}

App_ReloadConfig(*) {
    global g_App
    try {
        g_App["store"].Reload()
        MainEditor.RefreshOpenEditor()
        App_ShowStatus("RightModifierHotkeys v4 config reloaded")
    } catch as err {
        MsgBox(err.Message, "Reload Config Failed", "Iconx")
    }
}

App_ToggleSuspend(*) {
    Suspend(-1)
    App_ShowStatus(A_IsSuspended ? "RightModifierHotkeys v4 suspended" : "RightModifierHotkeys v4 active")
}

App_Exit(*) {
    ExitApp
}

App_ShowStatus(message) {
    ToolTip(message)
    SetTimer(App_ClearStatus, -1500)
}

App_ClearStatus() {
    ToolTip()
}