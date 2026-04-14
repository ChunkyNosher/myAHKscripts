#Requires AutoHotkey v2.0

class Schema {
    static Version := 1
    static BindingTypes := ["action", "send_keys", "send_text", "empty"]
    static ActionKinds := ["launch_batch_script", "launch_or_activate", "launch_or_cycle_group", "send_sequence_if_active", "toggle_always_on_top", "open_folders", "premiere_slide_preset", "script"]

    static CreateConfigDocument() {
        return Map(
            "schemaVersion", Schema.Version,
            "bindings", Map()
        )
    }

    static CreateActionDocument() {
        return Map(
            "schemaVersion", Schema.Version,
            "actions", []
        )
    }

    static CreateBindingSpec(bindingType, value := "") {
        switch bindingType {
            case "action":
                return Schema.NormalizeBindingSpec(Map("type", "action", "actionId", value))
            case "send_keys", "send_text":
                return Schema.NormalizeBindingSpec(Map("type", bindingType, "value", value))
            case "empty":
                return Schema.NormalizeBindingSpec(Map("type", "empty"))
        }

        return ""
    }

    static NormalizeBindingSpec(bindingSpec) {
        if !(bindingSpec is Map) {
            return ""
        }

        bindingType := bindingSpec.Get("type", "")
        if (Type(bindingType) != "String" || bindingType = "") {
            return ""
        }

        normalized := Map("type", bindingType)

        switch bindingType {
            case "empty":
                return normalized
            case "action":
                actionId := bindingSpec.Get("actionId", "")
                if (Type(actionId) != "String" || actionId = "") {
                    return ""
                }
                normalized["actionId"] := actionId
                return normalized
            case "send_keys", "send_text":
                value := bindingSpec.Get("value", "")
                if (Type(value) != "String" || value = "") {
                    return ""
                }
                normalized["value"] := value
                return normalized
        }

        return ""
    }

    static NormalizeActionDocument(document) {
        if !(document is Map) {
            return ""
        }

        if (document.Get("schemaVersion", 0) != Schema.Version) {
            return ""
        }

        actions := document.Get("actions", "")
        if !(actions is Array) {
            return ""
        }

        normalized := Schema.CreateActionDocument()
        seenIds := Map()

        for _, actionRecord in actions {
            normalizedRecord := Schema.NormalizeActionRecord(actionRecord)
            if !IsObject(normalizedRecord) {
                return ""
            }

            actionId := normalizedRecord["id"]
            if seenIds.Has(actionId) {
                return ""
            }

            seenIds[actionId] := true
            normalized["actions"].Push(normalizedRecord)
        }

        return normalized
    }

    static NormalizeActionRecord(actionRecord) {
        if !(actionRecord is Map) {
            return ""
        }

        actionId := actionRecord.Get("id", "")
        label := actionRecord.Get("label", "")
        kind := actionRecord.Get("kind", "")

        if (Type(actionId) != "String" || actionId = "") {
            return ""
        }

        if (Type(label) != "String" || label = "") {
            return ""
        }

        if !Schema.ArrayHasValue(Schema.ActionKinds, kind) {
            return ""
        }

        data := actionRecord.Get("data", Map())
        normalizedData := Schema.NormalizeActionData(kind, data)
        if !IsObject(normalizedData) {
            return ""
        }

        return Map(
            "id", actionId,
            "label", label,
            "kind", kind,
            "data", normalizedData
        )
    }

    static NormalizeActionData(kind, data) {
        if !(data is Map) {
            return ""
        }

        switch kind {
            case "launch_batch_script":
                scriptPath := data.Get("scriptPath", "")
                if (Type(scriptPath) != "String" || scriptPath = "") {
                    return ""
                }
                return Map("scriptPath", scriptPath)

            case "launch_or_activate":
                target := data.Get("target", "")
                runTarget := data.Get("run", "")
                if (Type(target) != "String" || target = "") {
                    return ""
                }
                if (Type(runTarget) != "String" || runTarget = "") {
                    return ""
                }
                return Map("target", target, "run", runTarget)

            case "launch_or_cycle_group":
                target := data.Get("target", "")
                groupName := data.Get("groupName", "")
                if (Type(target) != "String" || target = "") {
                    return ""
                }
                if (Type(groupName) != "String" || groupName = "") {
                    return ""
                }

                activeTarget := data.Get("activeTarget", target)
                runTarget := data.Get("run", "")
                groupTargets := Schema.NormalizeStringArray(data.Get("groupTargets", [target]))
                if !(groupTargets is Array) || (groupTargets.Length = 0) {
                    return ""
                }

                return Map(
                    "target", target,
                    "activeTarget", activeTarget,
                    "run", runTarget,
                    "groupName", groupName,
                    "groupTargets", groupTargets
                )

            case "send_sequence_if_active":
                target := data.Get("target", "")
                sequence := Schema.NormalizeStringArray(data.Get("sequence", ""))
                sendMode := data.Get("sendMode", "input")
                if (Type(target) != "String" || target = "") {
                    return ""
                }
                if !(sequence is Array) || (sequence.Length = 0) {
                    return ""
                }
                if !Schema.ArrayHasValue(["input", "text"], sendMode) {
                    return ""
                }
                return Map(
                    "target", target,
                    "sequence", sequence,
                    "sendMode", sendMode
                )

            case "toggle_always_on_top":
                return Map()

            case "open_folders":
                folderPaths := Schema.NormalizeStringArray(data.Get("folderPaths", ""))
                if !(folderPaths is Array) || (folderPaths.Length = 0) {
                    return ""
                }

                waits := Map(
                    "long", Schema.NormalizeInteger(data.Get("waits", Map()).Get("long", 2000), 2000),
                    "med", Schema.NormalizeInteger(data.Get("waits", Map()).Get("med", 1000), 1000),
                    "short", Schema.NormalizeInteger(data.Get("waits", Map()).Get("short", 550), 550),
                    "quick", Schema.NormalizeInteger(data.Get("waits", Map()).Get("quick", 350), 350)
                )

                return Map(
                    "launchTarget", data.Get("launchTarget", "explorer.exe"),
                    "activateTarget", data.Get("activateTarget", "ahk_exe explorer.exe"),
                    "folderPaths", folderPaths,
                    "waits", waits
                )

            case "premiere_slide_preset":
                presetName := data.Get("presetName", "")
                if (Type(presetName) != "String" || presetName = "") {
                    return ""
                }
                return Map("presetName", presetName)

            case "script":
                filePath := data.Get("filePath", "")
                code := data.Get("code", "")
                arguments := Schema.NormalizeStringArray(data.Get("arguments", []))
                workingDir := data.Get("workingDir", "")
                waitForExit := data.Get("wait", false)
                if ((Type(filePath) != "String" || filePath = "") && (Type(code) != "String" || code = "")) {
                    return ""
                }
                if !(arguments is Array) {
                    return ""
                }
                if (Type(workingDir) != "String") {
                    return ""
                }
                return Map(
                    "filePath", filePath,
                    "code", code,
                    "arguments", arguments,
                    "workingDir", workingDir,
                    "wait", !!waitForExit
                )
        }

        return ""
    }

    static GetBindingType(bindingSpec) {
        normalized := Schema.NormalizeBindingSpec(bindingSpec)
        if !IsObject(normalized) {
            return "empty"
        }

        return normalized["type"]
    }

    static GetBindingValue(bindingSpec) {
        normalized := Schema.NormalizeBindingSpec(bindingSpec)
        if !IsObject(normalized) {
            return ""
        }

        switch normalized["type"] {
            case "action":
                return normalized["actionId"]
            case "send_keys", "send_text":
                return normalized["value"]
        }

        return ""
    }

    static DescribeBindingSpec(bindingSpec) {
        normalized := Schema.NormalizeBindingSpec(bindingSpec)
        if !IsObject(normalized) {
            return ""
        }

        switch normalized["type"] {
            case "action":
                return normalized["actionId"]
            case "send_keys", "send_text":
                return normalized["value"]
            case "empty":
                return "(empty)"
        }

        return ""
    }

    static MergeBindings(defaultBindings, configBindings) {
        merged := Schema.CloneValue(defaultBindings)

        if !(merged is Map) {
            merged := Map()
        }

        if !(configBindings is Map) {
            return merged
        }

        for keyId, keyBindings in configBindings {
            if !(keyBindings is Map) {
                continue
            }

            if !merged.Has(keyId) || !(merged[keyId] is Map) {
                merged[keyId] := Map()
            }

            for modifierId, bindingSpec in keyBindings {
                normalized := Schema.NormalizeBindingSpec(bindingSpec)
                if IsObject(normalized) {
                    merged[keyId][modifierId] := normalized
                }
            }
        }

        return merged
    }

    static CloneValue(value) {
        if (value is Map) {
            clone := Map()
            for key, item in value {
                clone[key] := Schema.CloneValue(item)
            }
            return clone
        }

        if (value is Array) {
            clone := []
            for item in value {
                clone.Push(Schema.CloneValue(item))
            }
            return clone
        }

        return value
    }

    static NormalizeStringArray(value) {
        if !(value is Array) {
            return ""
        }

        normalized := []
        for _, item in value {
            if (Type(item) != "String" || item = "") {
                return ""
            }
            normalized.Push(item)
        }

        return normalized
    }

    static NormalizeInteger(value, defaultValue) {
        valueType := Type(value)
        if (valueType = "Integer" || valueType = "Float") {
            return Round(value)
        }

        return defaultValue
    }

    static ArrayHasValue(values, needle) {
        for _, value in values {
            if (value = needle) {
                return true
            }
        }

        return false
    }
}