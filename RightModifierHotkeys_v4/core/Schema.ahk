#Requires AutoHotkey v2.0

class Schema {
    static Version := 1
    static BindingTypes := ["action", "send_keys", "send_text", "empty"]

    static CreateConfigDocument() {
        return Map(
            "schemaVersion", Schema.Version,
            "bindings", Map()
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
}