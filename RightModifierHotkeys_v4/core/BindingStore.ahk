#Requires AutoHotkey v2.0

class BindingStore {
    __New(configPath, defaultsPath) {
        this.configPath := configPath
        this.defaultsPath := defaultsPath
        this.rootDir := RegExReplace(configPath, "\\[^\\]+$", "")
        this.backupDir := this.rootDir "\\backups"
        this.Reload()
    }

    Reload() {
        this.defaultsDoc := this.LoadDocument(this.defaultsPath, true)

        if !FileExist(this.configPath) {
            this.WriteDocument(this.configPath, Schema.CreateConfigDocument())
        }

        this.configDoc := this.LoadConfigDocument()
        this.keys := this.defaultsDoc["keys"]
        this.modifiers := this.defaultsDoc["modifiers"]
        this.bindings := Schema.MergeBindings(this.defaultsDoc["bindings"], this.configDoc["bindings"])
        return this.bindings
    }

    LoadConfigDocument() {
        try {
            return this.LoadDocument(this.configPath, false)
        } catch {
            if FileExist(this.configPath) {
                this.CreateBackup(this.configPath, "config-invalid")
            }

            repaired := Schema.CreateConfigDocument()
            this.WriteDocument(this.configPath, repaired)
            return repaired
        }
    }

    GetConfigPath() {
        return this.configPath
    }

    GetDefaultsPath() {
        return this.defaultsPath
    }

    GetBackupDir() {
        return this.backupDir
    }

    GetKeyInventory() {
        return this.keys
    }

    GetModifiers() {
        return this.modifiers
    }

    GetBindingSpec(keyId, modifierId) {
        if !this.bindings.Has(keyId) {
            return ""
        }

        keyBindings := this.bindings[keyId]
        if !(keyBindings is Map) || !keyBindings.Has(modifierId) {
            return ""
        }

        return keyBindings[modifierId]
    }

    EnumerateMergedBindings() {
        rows := []

        for _, keyInfo in this.keys {
            row := Map(
                "keyId", keyInfo["id"],
                "keyLabel", keyInfo.Get("label", keyInfo["id"]),
                "scanCode", keyInfo.Get("hotkey", keyInfo["id"]),
                "group", keyInfo.Get("group", ""),
                "bindings", Map()
            )

            for _, modifierInfo in this.modifiers {
                modifierId := modifierInfo["id"]
                row["bindings"][modifierId] := Schema.CloneValue(this.GetBindingSpec(keyInfo["id"], modifierId))
            }

            rows.Push(row)
        }

        return rows
    }

    UpdateBindingSpec(keyId, modifierId, bindingSpec) {
        normalized := Schema.NormalizeBindingSpec(bindingSpec)
        if !IsObject(normalized) {
            throw ValueError("Binding spec is invalid.")
        }

        keyBindings := this.EnsureConfigKeyBindings(keyId)
        keyBindings[modifierId] := normalized
        this.bindings := Schema.MergeBindings(this.defaultsDoc["bindings"], this.configDoc["bindings"])
        return Schema.CloneValue(normalized)
    }

    RemoveBindingSpec(keyId, modifierId) {
        configBindings := this.configDoc["bindings"]
        if !configBindings.Has(keyId) || !(configBindings[keyId] is Map) {
            return false
        }

        keyBindings := configBindings[keyId]
        if !keyBindings.Has(modifierId) {
            return false
        }

        keyBindings.Delete(modifierId)
        if (keyBindings.Count = 0) {
            configBindings.Delete(keyId)
        }

        this.bindings := Schema.MergeBindings(this.defaultsDoc["bindings"], this.configDoc["bindings"])
        return true
    }

    SaveConfig() {
        backupPath := ""
        if FileExist(this.configPath) {
            backupPath := this.CreateBackup(this.configPath, "config")
        }

        this.WriteDocument(this.configPath, this.configDoc)
        return backupPath
    }

    CreateBackup(sourcePath, label := "") {
        if !FileExist(sourcePath) {
            return ""
        }

        this.EnsureBackupDir()
        SplitPath(sourcePath, &fileName, , &fileExt, &fileNameNoExt)
        timestamp := FormatTime(, "yyyyMMdd_HHmmss") "_" A_TickCount
        backupName := (label != "" ? label : fileNameNoExt) "_" timestamp
        if (fileExt != "") {
            backupName .= "." fileExt
        }

        backupPath := this.backupDir "\\" backupName
        FileCopy(sourcePath, backupPath, true)
        return backupPath
    }

    LoadDocument(path, requireInventory) {
        text := this.ReadJsonText(path)
        if (Trim(text) = "") {
            throw Error("JSON document is empty: " path)
        }

        document := Json.Parse(text)
        if !(document is Map) {
            throw TypeError("JSON root must be an object: " path)
        }

        if (document.Get("schemaVersion", 0) != Schema.Version) {
            throw ValueError("Unsupported schema version in " path)
        }

        if !document.Has("bindings") || !(document["bindings"] is Map) {
            throw ValueError("Bindings object missing from " path)
        }

        if requireInventory {
            if !document.Has("keys") || !(document["keys"] is Array) {
                throw ValueError("Key inventory missing from " path)
            }

            if !document.Has("modifiers") || !(document["modifiers"] is Array) {
                throw ValueError("Modifier inventory missing from " path)
            }
        }

        return document
    }

    WriteDocument(path, document) {
        file := FileOpen(path, "w", "UTF-8-RAW")
        if !IsObject(file) {
            throw Error("Unable to open JSON file for writing: " path)
        }

        file.Write(Json.Dump(document, 2))
        file.Close()
    }

    EnsureBackupDir() {
        if !DirExist(this.backupDir) {
            DirCreate(this.backupDir)
        }
    }

    ReadJsonText(path) {
        text := FileRead(path, "UTF-8")
        if (SubStr(text, 1, 1) = Chr(0xFEFF)) {
            text := SubStr(text, 2)
        }
        return text
    }

    EnsureConfigKeyBindings(keyId) {
        configBindings := this.configDoc["bindings"]
        if !configBindings.Has(keyId) || !(configBindings[keyId] is Map) {
            configBindings[keyId] := Map()
        }

        return configBindings[keyId]
    }
}