#Requires AutoHotkey v2.0

class ActionRegistry {
    __New(databasePath := "", backupStore := "", defaultsPath := "") {
        this.databasePath := databasePath
        this.backupStore := backupStore
        this.defaultsPath := defaultsPath
        this.actionDoc := Schema.CreateActionDocument()
        this.actions := Map()
        this.callbacks := Map()
        this.batchPids := Map()
        this.loadWarningMessage := ""

        if (this.databasePath != "") {
            this.Reload()
        }
    }

    Register(actionId, callback) {
        if (Type(actionId) != "String" || actionId = "") {
            throw ValueError("Action ID must be a non-empty string.", -1, actionId)
        }

        if !HasMethod(callback, "Call") {
            throw TypeError("Callback must be callable.")
        }

        this.callbacks[actionId] := callback
        return callback
    }

    Reload() {
        this.loadWarningMessage := ""

        if (this.databasePath = "") {
            this.actionDoc := Schema.CreateActionDocument()
            this.actions := Map()
            return this.actions
        }

        if !FileExist(this.databasePath) {
            this.WriteDocument(this.databasePath, this.LoadDefaultDocument())
        }

        this.actionDoc := this.LoadActionDocument()
        this.IndexActions()
        return this.actions
    }

    GetLoadWarning() {
        return this.loadWarningMessage
    }

    GetActionDatabasePath() {
        return this.databasePath
    }

    EnumerateActionRecords() {
        records := []
        for _, actionRecord in this.actionDoc["actions"] {
            records.Push(Schema.CloneValue(actionRecord))
        }
        return records
    }

    GetActionRecord(actionId) {
        if !this.actions.Has(actionId) {
            return ""
        }

        return Schema.CloneValue(this.actions[actionId])
    }

    UpsertActionRecord(actionRecord) {
        normalized := Schema.NormalizeActionRecord(actionRecord)
        if !IsObject(normalized) {
            throw ValueError("Action record is invalid.")
        }

        index := this.FindActionIndex(normalized["id"])
        if (index > 0) {
            this.actionDoc["actions"][index] := normalized
        } else {
            this.actionDoc["actions"].Push(normalized)
        }

        this.IndexActions()
        return Schema.CloneValue(normalized)
    }

    DeleteActionRecord(actionId) {
        if (Type(actionId) != "String" || actionId = "") {
            return false
        }

        index := this.FindActionIndex(actionId)
        if (index = 0) {
            return false
        }

        this.actionDoc["actions"].RemoveAt(index)
        this.IndexActions()
        return true
    }

    SaveActionDatabase() {
        backupPath := ""
        if FileExist(this.databasePath) && IsObject(this.backupStore) && HasMethod(this.backupStore, "CreateBackup") {
            backupPath := this.backupStore.CreateBackup(this.databasePath, "actions")
        }

        this.WriteDocument(this.databasePath, this.actionDoc)
        return backupPath
    }

    SaveActionDatabaseText(rawText) {
        result := this.ValidateActionDatabaseText(rawText, true)
        if !result["ok"] {
            throw Error(result["message"])
        }

        this.actionDoc := result["document"]
        this.IndexActions()
        backupPath := this.SaveActionDatabase()

        return Map(
            "backupPath", backupPath,
            "actionCount", this.actionDoc["actions"].Length
        )
    }

    ValidateActionDatabaseText(rawText, includeDocument := false) {
        try {
            document := this.ParseDocumentText(rawText)
            result := Map(
                "ok", true,
                "message", "Validation passed for " document["actions"].Length " action(s)."
            )
            if includeDocument {
                result["document"] := document
            }
            return result
        } catch as err {
            result := Map(
                "ok", false,
                "message", err.Message
            )
            if includeDocument {
                result["document"] := ""
            }
            return result
        }
    }

    Resolve(bindingSpec) {
        normalized := Schema.NormalizeBindingSpec(bindingSpec)
        if !IsObject(normalized) {
            return ""
        }

        if (normalized["type"] = "action") {
            return ResolvedBinding(normalized, this)
        }

        return ResolvedBinding(normalized)
    }

    ExecuteActionById(actionId) {
        if this.callbacks.Has(actionId) {
            this.callbacks[actionId].Call()
            return true
        }

        if !this.actions.Has(actionId) {
            OutputDebug("RightModifierHotkeys_v4: unknown action ID '" actionId "'.")
            return false
        }

        return this.ExecuteActionRecord(this.actions[actionId])
    }

    ExecuteActionRecord(actionRecord) {
        kind := actionRecord["kind"]
        actionData := actionRecord["data"]

        switch kind {
            case "launch_batch_script":
                return this.ExecuteLaunchBatchScript(actionRecord["id"], actionData)
            case "launch_or_activate":
                return this.ExecuteLaunchOrActivate(actionData)
            case "launch_or_cycle_group":
                return this.ExecuteLaunchOrCycleGroup(actionData)
            case "send_sequence_if_active":
                return this.ExecuteSendSequenceIfActive(actionData)
            case "toggle_always_on_top":
                return this.ExecuteToggleAlwaysOnTop()
            case "open_folders":
                return this.ExecuteOpenFolders(actionData)
            case "premiere_slide_preset":
                return this.ApplyPremiereSlidePreset(actionData["presetName"])
            case "script":
                return this.ExecuteScript(actionData)
        }

        OutputDebug("RightModifierHotkeys_v4: unsupported action kind '" kind "'.")
        return false
    }

    LoadDocument(path) {
        return this.ParseDocumentText(FileRead(path, "UTF-8"))
    }

    LoadDefaultDocument() {
        if (this.defaultsPath != "" && FileExist(this.defaultsPath)) {
            return this.LoadDocument(this.defaultsPath)
        }

        return Schema.CreateActionDocument()
    }

    LoadActionDocument() {
        try {
            return this.LoadDocument(this.databasePath)
        } catch as err {
            backupPath := ""
            if FileExist(this.databasePath) && IsObject(this.backupStore) && HasMethod(this.backupStore, "CreateBackup") {
                backupPath := this.backupStore.CreateBackup(this.databasePath, "actions-invalid")
            }

            repaired := this.LoadDefaultDocument()
            this.WriteDocument(this.databasePath, repaired)

            this.loadWarningMessage := "Action database JSON was invalid and has been reset: " this.databasePath
            if (backupPath != "") {
                this.loadWarningMessage .= "`nBackup: " backupPath
            }
            this.loadWarningMessage .= "`nOriginal error: " err.Message

            return repaired
        }
    }

    ParseDocumentText(rawText) {
        text := rawText
        if (SubStr(text, 1, 1) = Chr(0xFEFF)) {
            text := SubStr(text, 2)
        }

        if (Trim(text) = "") {
            throw Error("Action database JSON is empty.")
        }

        document := Json.Parse(text)
        normalized := Schema.NormalizeActionDocument(document)
        if !IsObject(normalized) {
            throw Error("Action database JSON is invalid.")
        }

        return normalized
    }

    WriteDocument(path, document) {
        file := FileOpen(path, "w", "UTF-8-RAW")
        if !IsObject(file) {
            throw Error("Unable to open JSON file for writing: " path)
        }

        file.Write(Json.Dump(document, 2))
        file.Close()
    }

    IndexActions() {
        this.actions := Map()
        for _, actionRecord in this.actionDoc["actions"] {
            this.actions[actionRecord["id"]] := actionRecord
        }
    }

    FindActionIndex(actionId) {
        for index, actionRecord in this.actionDoc["actions"] {
            if (actionRecord["id"] = actionId) {
                return index
            }
        }

        return 0
    }

    ExecuteLaunchBatchScript(actionId, actionData) {
        batchPid := this.batchPids.Has(actionId) ? this.batchPids[actionId] : 0
        if batchPid && ProcessExist(batchPid) {
            if WinExist("ahk_pid " batchPid) {
                WinActivate("ahk_pid " batchPid)
            }
            return batchPid
        }

        this.batchPids[actionId] := 0
        Run(actionData["scriptPath"], , , &batchPid)
        Sleep(1000)

        if !batchPid {
            try {
                if WinWait("ahk_class ConsoleWindowClass",, 3) {
                    batchPid := WinGetPID("A")
                }
            }
        }

        this.batchPids[actionId] := batchPid
        return batchPid
    }

    ExecuteLaunchOrActivate(actionData) {
        if !WinExist(actionData["target"]) {
            Run(actionData["run"])
        }

        WinActivate(actionData["target"])
        return true
    }

    ExecuteLaunchOrCycleGroup(actionData) {
        if (actionData["run"] != "" && !WinExist(actionData["target"])) {
            Run(actionData["run"])
        }

        for _, groupTarget in actionData["groupTargets"] {
            GroupAdd(actionData["groupName"], groupTarget)
        }

        if (actionData["activeTarget"] != "" && WinActive(actionData["activeTarget"])) {
            GroupActivate(actionData["groupName"], "R")
        } else {
            WinActivate(actionData["target"])
        }

        return true
    }

    ExecuteSendSequenceIfActive(actionData) {
        if !WinActive(actionData["target"]) {
            return false
        }

        for _, step in actionData["sequence"] {
            if (actionData["sendMode"] = "text") {
                SendText(step)
            } else {
                SendInput(step)
            }
        }

        return true
    }

    ExecuteToggleAlwaysOnTop() {
        hwnd := WinExist("A")
        if !hwnd {
            return false
        }

        exStyle := WinGetExStyle("ahk_id " hwnd)
        WinSetAlwaysOnTop(-1, "ahk_id " hwnd)
        ToolTip((exStyle & 0x8) ? "Always On Top: OFF" : "Always On Top: ON")
        SetTimer(ActionRegistry_ClearToolTip, -1500)
        return true
    }

    ExecuteOpenFolders(actionData) {
        waits := actionData["waits"]
        Run(actionData["launchTarget"])
        WinActivate(actionData["activateTarget"])
        Sleep(waits["long"])

        totalFolders := actionData["folderPaths"].Length
        for index, folderPath in actionData["folderPaths"] {
            SendInput("!d")
            Sleep(waits["quick"])
            SendText(folderPath)
            Sleep(waits["quick"])
            SendInput("{Enter}")
            Sleep(waits["short"])

            if (index != totalFolders) {
                SendInput("^t")
                Sleep(waits["short"])
            }

            if (index = 1) {
                Sleep(waits["med"])
            }
        }

        return totalFolders
    }

    ApplyPremiereSlidePreset(presetName) {
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

            if !this.WaitForCaret() {
                return false
            }

            Send("{BS}")
            SendText(presetName)

            if !this.WaitForCaret(&caretX, &caretY) {
                return false
            }

            MouseMove(caretX, caretY)
            MouseMove(caretX + 41, caretY + 63)
            MouseGetPos(&fxX, &fxY)
            MouseClickDrag("L", fxX, fxY, origX, origY, 0)
            return true
        } finally {
            BlockInput("MouseMoveOff")
            BlockInput("Off")
        }
    }

    WaitForCaret(&caretX := "", &caretY := "", maxChecks := 40, sleepMs := 33) {
        if CaretGetPos(&caretX, &caretY) {
            return true
        }

        loop maxChecks {
            Sleep(sleepMs)
            if CaretGetPos(&caretX, &caretY) {
                return true
            }
        }

        caretX := ""
        caretY := ""
        return false
    }

    ExecuteScript(actionData) {
        filePath := actionData["filePath"]
        code := actionData["code"]
        arguments := actionData["arguments"]
        workingDir := actionData["workingDir"]
        waitForExit := actionData["wait"]

        if (code != "") {
            tempPath := A_Temp "\\RightModifierHotkeys_v4_action_" A_TickCount ".ahk"
            file := FileOpen(tempPath, "w", "UTF-8-RAW")
            if !IsObject(file) {
                throw Error("Unable to open temporary script file for writing.")
            }

            file.Write(code)
            file.Close()

            try {
                return this.RunScriptFile(tempPath, arguments, workingDir, waitForExit)
            } finally {
                if waitForExit {
                    try FileDelete(tempPath)
                }
            }
        }

        return (filePath != "") ? this.RunScriptFile(filePath, arguments, workingDir, waitForExit) : false
    }

    RunScriptFile(filePath, arguments, workingDir, waitForExit) {
        lowerPath := StrLower(filePath)
        command := (SubStr(lowerPath, -4) = ".ahk") ? this.QuoteArgument(A_AhkPath) " " this.QuoteArgument(filePath) : this.QuoteArgument(filePath)
        for _, arg in arguments {
            command .= " " this.QuoteArgument(arg)
        }

        if waitForExit {
            RunWait(command, workingDir = "" ? unset : workingDir)
        } else {
            Run(command, workingDir = "" ? unset : workingDir)
        }

        return true
    }

    QuoteArgument(text) {
        return '"' StrReplace(text, '"', '""') '"'
    }
}

ActionRegistry_ClearToolTip() {
    ToolTip()
}

class ResolvedBinding {
    __New(bindingSpec, registry := "") {
        this.bindingSpec := bindingSpec
        this.registry := registry
    }

    Execute() {
        bindingType := this.bindingSpec["type"]

        switch bindingType {
            case "action":
                if !IsObject(this.registry) {
                    return false
                }

                return this.registry.ExecuteActionById(this.bindingSpec["actionId"])
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