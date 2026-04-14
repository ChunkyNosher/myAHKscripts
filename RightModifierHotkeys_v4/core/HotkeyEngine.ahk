#Requires AutoHotkey v2.0

class HotkeyEngine {
    __New(store, registry) {
        this.store := store
        this.registry := registry
        this.modifierState := Map(
            "RCtrl", false,
            "RAlt", false,
            "RShift", false
        )
        this.installed := false
    }

    Install() {
        if this.installed {
            return
        }

        this.InstallModifierHotkeys()
        this.InstallPrimaryHotkeys()
        this.installed := true
    }

    InstallModifierHotkeys() {
        Hotkey("$*RCtrl", ObjBindMethod(this, "OnModifierDown", "RCtrl"))
        Hotkey("$*RCtrl Up", ObjBindMethod(this, "OnModifierUp", "RCtrl"))
        Hotkey("$*RAlt", ObjBindMethod(this, "OnModifierDown", "RAlt"))
        Hotkey("$*RAlt Up", ObjBindMethod(this, "OnModifierUp", "RAlt"))
        Hotkey("$*RShift", ObjBindMethod(this, "OnModifierDown", "RShift"))
        Hotkey("$*RShift Up", ObjBindMethod(this, "OnModifierUp", "RShift"))
    }

    InstallPrimaryHotkeys() {
        HotIf(ObjBindMethod(this, "HasActiveModifiers"))
        for _, keyInfo in this.store.GetKeyInventory() {
            hotkeyName := keyInfo.Get("hotkey", keyInfo["id"])
            Hotkey("$*" hotkeyName, ObjBindMethod(this, "OnPrimaryKey", keyInfo["id"]))
        }
        HotIf()
    }

    OnModifierDown(modifierId, *) {
        this.modifierState[modifierId] := true
    }

    OnModifierUp(modifierId, *) {
        this.modifierState[modifierId] := false
    }

    HasActiveModifiers(*) {
        return this.modifierState["RCtrl"] || this.modifierState["RAlt"] || this.modifierState["RShift"]
    }

    OnPrimaryKey(keyId, *) {
        modifierId := this.GetActiveModifierId()
        if (modifierId = "") {
            return
        }

        bindingSpec := this.store.GetBindingSpec(keyId, modifierId)
        if !IsObject(bindingSpec) {
            return
        }

        resolved := this.registry.Resolve(bindingSpec)
        if !IsObject(resolved) {
            return
        }

        try {
            resolved.Execute()
        } catch as err {
            OutputDebug("RightModifierHotkeys_v4: failed to execute " keyId "/" modifierId ": " err.Message)
        }
    }

    GetActiveModifierId() {
        rctrl := this.modifierState["RCtrl"]
        ralt := this.modifierState["RAlt"]
        rshift := this.modifierState["RShift"]

        if (rctrl && ralt && rshift) {
            return "RCtrl_RAlt_RShift"
        }

        if (rctrl && ralt) {
            return "RCtrl_RAlt"
        }

        if (rctrl && rshift) {
            return "RCtrl_RShift"
        }

        if (ralt && rshift) {
            return "RAlt_RShift"
        }

        if rctrl {
            return "RCtrl"
        }

        if ralt {
            return "RAlt"
        }

        if rshift {
            return "RShift"
        }

        return ""
    }
}