#Requires AutoHotkey v2.0

class ActionRegistry {
    __New() {
        this.actions := Map()
    }

    Register(actionId, callback) {
        if (Type(actionId) != "String" || actionId = "") {
            throw ValueError("Action ID must be a non-empty string.", -1, actionId)
        }

        if !HasMethod(callback, "Call") {
            throw TypeError("Callback must be callable.")
        }

        this.actions[actionId] := callback
        return callback
    }

    Resolve(bindingSpec) {
        normalized := Schema.NormalizeBindingSpec(bindingSpec)
        if !IsObject(normalized) {
            return ""
        }

        if (normalized["type"] = "action") {
            actionId := normalized["actionId"]
            callback := this.actions.Has(actionId) ? this.actions[actionId] : ""
            return ResolvedBinding(normalized, callback)
        }

        return ResolvedBinding(normalized)
    }
}

class ResolvedBinding {
    __New(bindingSpec, callback := "") {
        this.bindingSpec := bindingSpec
        this.callback := callback
    }

    Execute() {
        bindingType := this.bindingSpec["type"]

        switch bindingType {
            case "action":
                if !HasMethod(this.callback, "Call") {
                    OutputDebug("RightModifierHotkeys_v4: unknown action ID '" this.bindingSpec["actionId"] "'.")
                    return false
                }

                this.callback.Call()
                return true
            case "send_keys":
                Send(this.bindingSpec["value"])
                return true
            case "send_text":
                SendText(this.bindingSpec["value"])
                return true
        }

        return false
    }
}