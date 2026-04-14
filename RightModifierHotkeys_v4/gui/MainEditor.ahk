#Requires AutoHotkey v2.0

class MainEditor {
    static instance := ""

    static Open(app) {
        if IsObject(MainEditor.instance) {
            MainEditor.instance.gui.Show()
            WinActivate("ahk_id " MainEditor.instance.gui.Hwnd)
            return MainEditor.instance
        }

        MainEditor.instance := MainEditor(app)
        MainEditor.instance.Show()
        return MainEditor.instance
    }

    static RefreshOpenEditor() {
        if IsObject(MainEditor.instance) {
            MainEditor.instance.ReloadFromDisk()
        }
    }

    __New(app) {
        this.app := app
        this.store := app["store"]
        this.modifiers := this.store.GetModifiers()
        this.actionTypes := Schema.BindingTypes
        this.userActionsPath := A_ScriptDir "\\RightModifierHotkeys_v4.user-actions.ahk"
        this.selectedKeyId := ""
        this.filteredRows := []
        this.BuildGui()
        this.ReloadFromDisk()
    }

    Show() {
        this.gui.Show("w1320 h760")
    }

    BuildGui() {
        this.gui := Gui("+Resize", "RightModifierHotkeys v4 Editor")
        this.gui.SetFont("s9", "Segoe UI")
        this.gui.OnEvent("Close", ObjBindMethod(this, "OnClose"))
        this.gui.OnEvent("Escape", ObjBindMethod(this, "OnClose"))

        this.tabs := this.gui.AddTab3("x10 y10 w1298 h700", ["Mappings", "Custom Actions", "Settings"])

        this.tabs.UseTab(1)
        this.gui.AddText("x24 y48 w40 h23 +0x200", "Filter")
        this.filterEdit := this.gui.AddEdit("x70 y45 w410 h24")
        this.filterEdit.OnEvent("Change", ObjBindMethod(this, "OnFilterChange"))

        headers := ["Key", "Scan Code"]
        for _, modifierInfo in this.modifiers {
            headers.Push(modifierInfo["id"])
        }

        this.mappingList := this.gui.AddListView("x24 y78 w970 h560 -Multi Grid", headers)
        this.mappingList.OnEvent("ItemSelect", ObjBindMethod(this, "OnMappingRowSelect"))

        this.gui.AddGroupBox("x1008 y78 w278 h560", "Binding Editor")
        this.selectedKeyText := this.gui.AddText("x1022 y108 w248 h40", "Select a key from the mappings list.")
        this.gui.AddText("x1022 y162 w64 h23 +0x200", "Modifier")
        this.modifierDropDown := this.gui.AddDropDownList("x1092 y160 w178", this.GetModifierLabels())
        this.modifierDropDown.OnEvent("Change", ObjBindMethod(this, "OnModifierChanged"))

        this.gui.AddText("x1022 y202 w64 h23 +0x200", "Type")
            this.typeDropDown := this.gui.AddDropDownList("x1092 y200 w178 Choose1", this.actionTypes)
        this.typeDropDown.OnEvent("Change", ObjBindMethod(this, "OnTypeChanged"))

        this.valueLabel := this.gui.AddText("x1022 y242 w248 h23 +0x200", "Value / Action ID")
        this.valueEdit := this.gui.AddEdit("x1022 y268 w248 h220 WantTab")

        this.saveBindingButton := this.gui.AddButton("x1022 y506 w118 h30", "Save Binding")
        this.saveBindingButton.OnEvent("Click", ObjBindMethod(this, "OnSaveBinding"))

        this.reloadSelectionButton := this.gui.AddButton("x1152 y506 w118 h30", "Reload Row")
        this.reloadSelectionButton.OnEvent("Click", ObjBindMethod(this, "OnReloadSelection"))

        this.revertOverrideButton := this.gui.AddButton("x1022 y544 w248 h30", "Revert Override")
        this.revertOverrideButton.OnEvent("Click", ObjBindMethod(this, "OnRevertOverride"))

        this.tabs.UseTab(2)
        this.userActionsEdit := this.gui.AddEdit("x24 y48 w1246 h510 WantTab +Multi")

        this.validateActionsButton := this.gui.AddButton("x24 y570 w110 h30", "Validate")
        this.validateActionsButton.OnEvent("Click", ObjBindMethod(this, "OnValidateUserActions"))

        this.saveActionsButton := this.gui.AddButton("x146 y570 w110 h30", "Save")
        this.saveActionsButton.OnEvent("Click", ObjBindMethod(this, "OnSaveUserActions"))

        this.reloadActionsButton := this.gui.AddButton("x268 y570 w140 h30", "Reload From Disk")
        this.reloadActionsButton.OnEvent("Click", ObjBindMethod(this, "OnReloadUserActions"))

        this.userActionsOutput := this.gui.AddEdit("x24 y612 w1246 h90 ReadOnly +Multi")

        this.tabs.UseTab(3)
        this.gui.AddText("x24 y54 w140 h23 +0x200", "Config JSON")
        this.configPathEdit := this.gui.AddEdit("x170 y50 w1100 h24 ReadOnly", this.store.GetConfigPath())

        this.gui.AddText("x24 y94 w140 h23 +0x200", "Defaults JSON")
        this.defaultsPathEdit := this.gui.AddEdit("x170 y90 w1100 h24 ReadOnly", this.store.GetDefaultsPath())

        this.gui.AddText("x24 y134 w140 h23 +0x200", "User Actions")
        this.userActionsPathEdit := this.gui.AddEdit("x170 y130 w1100 h24 ReadOnly", this.userActionsPath)

        this.gui.AddText("x24 y174 w140 h23 +0x200", "Backup Folder")
        this.backupPathEdit := this.gui.AddEdit("x170 y170 w1100 h24 ReadOnly", this.store.GetBackupDir())

        this.reloadConfigButton := this.gui.AddButton("x24 y222 w120 h30", "Reload Config")
        this.reloadConfigButton.OnEvent("Click", ObjBindMethod(this, "OnReloadConfig"))

        this.openBackupFolderButton := this.gui.AddButton("x156 y222 w140 h30", "Open Backup Folder")
        this.openBackupFolderButton.OnEvent("Click", ObjBindMethod(this, "OnOpenBackupFolder"))

        this.tabs.UseTab()

        this.statusText := this.gui.AddText("x18 y720 w1288 h23 +0x200", "Ready.")
    }

    ReloadFromDisk() {
        this.store.Reload()
        this.userActionsEdit.Value := FileRead(this.userActionsPath, "UTF-8")
        this.userActionsOutput.Value := ""
        this.LoadMappingRows()
        this.SyncSelectedBinding()
        this.SetStatus("Editor data reloaded.")
    }

    LoadMappingRows() {
        selectedKeyId := this.selectedKeyId
        filterText := Trim(this.filterEdit.Value)
        this.filteredRows := []
        this.mappingList.Delete()

        for _, row in this.store.EnumerateMergedBindings() {
            if !this.RowMatchesFilter(row, filterText) {
                continue
            }

            values := [row["keyLabel"], row["scanCode"]]
            for _, modifierInfo in this.modifiers {
                values.Push(Schema.DescribeBindingSpec(row["bindings"][modifierInfo["id"]]))
            }

            this.mappingList.Add("", values*)
            this.filteredRows.Push(row)
        }

        this.mappingList.ModifyCol(1, 110)
        this.mappingList.ModifyCol(2, 90)
        loop 7 {
            this.mappingList.ModifyCol(A_Index + 2, 108)
        }

        if (selectedKeyId != "") {
            rowIndex := this.FindFilteredRowIndex(selectedKeyId)
            if (rowIndex > 0) {
                this.mappingList.Modify(rowIndex, "Select Focus Vis")
                return
            }
        }

        if (this.filteredRows.Length > 0) {
            this.mappingList.Modify(1, "Select Focus Vis")
        } else {
            this.selectedKeyId := ""
            this.selectedKeyText.Text := "No keys match the current filter."
            this.typeDropDown.Choose(this.FindActionTypeIndex("empty"))
            this.valueEdit.Value := ""
            this.valueEdit.Enabled := false
        }
    }

    RowMatchesFilter(row, filterText) {
        if (filterText = "") {
            return true
        }

        searchText := row["keyLabel"] " " row["keyId"] " " row["scanCode"] " " row["group"]
        return InStr(searchText, filterText, false) > 0
    }

    FindFilteredRowIndex(keyId) {
        for index, row in this.filteredRows {
            if (row["keyId"] = keyId) {
                return index
            }
        }

        return 0
    }

    SyncSelectedBinding() {
        if (this.selectedKeyId = "") {
            if (this.filteredRows.Length > 0) {
                this.selectedKeyId := this.filteredRows[1]["keyId"]
            } else {
                return
            }
        }

        rowIndex := this.FindFilteredRowIndex(this.selectedKeyId)
        if (rowIndex = 0) {
            return
        }

        row := this.filteredRows[rowIndex]
            this.selectedKeyText.Text := row["keyLabel"] " (" row["keyId"] ")"
        bindingSpec := row["bindings"][this.GetSelectedModifierId()]
        bindingType := Schema.GetBindingType(bindingSpec)
        this.typeDropDown.Choose(this.FindActionTypeIndex(bindingType))
        this.valueEdit.Value := Schema.GetBindingValue(bindingSpec)
        this.valueEdit.Enabled := (bindingType != "empty")
    }

    GetModifierLabels() {
        labels := []
        for _, modifierInfo in this.modifiers {
            labels.Push(modifierInfo["label"])
        }
        return labels
    }

    GetSelectedModifierId() {
        index := this.modifierDropDown.Value
        if (index < 1 || index > this.modifiers.Length) {
            return this.modifiers[1]["id"]
        }

        return this.modifiers[index]["id"]
    }

    GetSelectedActionType() {
        index := this.typeDropDown.Value
        if (index < 1 || index > this.actionTypes.Length) {
            return "empty"
        }

        return this.actionTypes[index]
    }

    FindActionTypeIndex(bindingType) {
        for index, typeName in this.actionTypes {
            if (typeName = bindingType) {
                return index
            }
        }

        return this.actionTypes.Length
    }

    OnClose(*) {
        this.gui.Destroy()
        MainEditor.instance := ""
    }

    OnFilterChange(*) {
        this.LoadMappingRows()
    }

    OnMappingRowSelect(ctrl, rowNumber, selected) {
        if !selected {
            return
        }

        if (rowNumber < 1 || rowNumber > this.filteredRows.Length) {
            return
        }

        this.selectedKeyId := this.filteredRows[rowNumber]["keyId"]
        this.SyncSelectedBinding()
    }

    OnModifierChanged(*) {
        this.SyncSelectedBinding()
    }

    OnTypeChanged(*) {
        bindingType := this.GetSelectedActionType()
        this.valueEdit.Enabled := (bindingType != "empty")
        if (bindingType = "empty") {
            this.valueEdit.Value := ""
        }
    }

    OnSaveBinding(*) {
        if (this.selectedKeyId = "") {
            this.SetStatus("Select a key before saving.")
            return
        }

        modifierId := this.GetSelectedModifierId()
        bindingType := this.GetSelectedActionType()

        try {
            bindingSpec := Schema.CreateBindingSpec(bindingType, this.valueEdit.Value)
            if !IsObject(bindingSpec) {
                throw ValueError("Binding value is required for type '" bindingType "'.")
            }

            this.store.UpdateBindingSpec(this.selectedKeyId, modifierId, bindingSpec)
            backupPath := this.store.SaveConfig()
            this.LoadMappingRows()
            this.SyncSelectedBinding()
            this.SetStatus("Saved " this.selectedKeyId " / " modifierId (backupPath != "" ? " with backup." : "."))
        } catch as err {
            MsgBox(err.Message, "Save Binding Failed", "Iconx")
            this.SetStatus("Binding save failed.")
        }
    }

    OnReloadSelection(*) {
        this.SyncSelectedBinding()
        this.SetStatus("Selection reloaded from current store state.")
    }

    OnRevertOverride(*) {
        if (this.selectedKeyId = "") {
            this.SetStatus("Select a key before reverting.")
            return
        }

        modifierId := this.GetSelectedModifierId()
        try {
            changed := this.store.RemoveBindingSpec(this.selectedKeyId, modifierId)
            if changed {
                backupPath := this.store.SaveConfig()
                this.LoadMappingRows()
                this.SyncSelectedBinding()
                this.SetStatus("Reverted override for " this.selectedKeyId " / " modifierId (backupPath != "" ? "." : "."))
            } else {
                this.SetStatus("No user override exists for " this.selectedKeyId " / " modifierId ".")
            }
        } catch as err {
            MsgBox(err.Message, "Revert Override Failed", "Iconx")
            this.SetStatus("Override revert failed.")
        }
    }

    OnValidateUserActions(*) {
        result := this.ValidateUserActions(this.userActionsEdit.Value)
        this.userActionsOutput.Value := result["message"]
        this.SetStatus(result["ok"] ? "User actions validation passed." : "User actions validation failed.")
    }

    OnSaveUserActions(*) {
        result := this.ValidateUserActions(this.userActionsEdit.Value)
        this.userActionsOutput.Value := result["message"]
        if !result["ok"] {
            this.SetStatus("User actions were not saved.")
            return
        }

        try {
            backupPath := this.store.CreateBackup(this.userActionsPath, "user-actions")
            this.WriteTextFile(this.userActionsPath, this.userActionsEdit.Value)
            this.SetStatus("User actions saved.")
            this.userActionsOutput.Value := "Saved user actions." (backupPath != "" ? "`r`nBackup: " backupPath : "")
            if (MsgBox("User actions saved. Reload RightModifierHotkeys v4 now?", "RightModifierHotkeys v4", "YN Iconi") = "Yes") {
                Reload()
            }
        } catch as err {
            MsgBox(err.Message, "Save User Actions Failed", "Iconx")
            this.SetStatus("User actions save failed.")
        }
    }

    OnReloadUserActions(*) {
        this.userActionsEdit.Value := FileRead(this.userActionsPath, "UTF-8")
        this.userActionsOutput.Value := "Reloaded user-actions from disk."
        this.SetStatus("User actions reloaded from disk.")
    }

    OnReloadConfig(*) {
        try {
            this.store.Reload()
            this.LoadMappingRows()
            this.SyncSelectedBinding()
            this.SetStatus("Config reloaded from disk.")
        } catch as err {
            MsgBox(err.Message, "Reload Config Failed", "Iconx")
            this.SetStatus("Config reload failed.")
        }
    }

    OnOpenBackupFolder(*) {
        backupDir := this.store.GetBackupDir()
        if !DirExist(backupDir) {
            DirCreate(backupDir)
        }

        Run(backupDir)
        this.SetStatus("Opened backup folder.")
    }

    SetStatus(message) {
        this.statusText.Text := message
    }

    ValidateUserActions(content) {
        wrapperPath := A_Temp "\\RightModifierHotkeys_v4_user_actions_validate_" A_TickCount ".ahk"
        outputPath := A_Temp "\\RightModifierHotkeys_v4_user_actions_validate_" A_TickCount ".log"
        wrapper := "#Requires AutoHotkey v2.0`r`n"
        wrapper .= "class ValidationRegistry {`r`n"
        wrapper .= "    Register(actionId, callback) {`r`n"
        wrapper .= "        return callback`r`n"
        wrapper .= "    }`r`n"
        wrapper .= "}`r`n`r`n"
        wrapper .= content
        wrapper .= "`r`n`r`nregistry := ValidationRegistry()`r`n"
        wrapper .= "RegisterUserActions(registry)`r`n"
        wrapper .= "ExitApp`r`n"

        try {
            this.WriteTextFile(wrapperPath, wrapper)
                quote := Chr(34)
                command := A_ComSpec " /C " quote quote A_AhkPath quote " /ErrorStdOut=UTF-8 " quote wrapperPath quote " > " quote outputPath quote " 2>&1" quote
            exitCode := RunWait(command, A_Temp, "Hide")
            outputText := FileExist(outputPath) ? Trim(FileRead(outputPath, "UTF-8")) : ""
            if (exitCode = 0) {
                return Map("ok", true, "message", outputText != "" ? outputText : "Validation passed.")
            }

            return Map("ok", false, "message", outputText != "" ? outputText : "Validation failed with exit code " exitCode ".")
        } catch as err {
            return Map("ok", false, "message", err.Message)
        } finally {
            try FileDelete(wrapperPath)
            try FileDelete(outputPath)
        }
    }

    WriteTextFile(path, text) {
        file := FileOpen(path, "w", "UTF-8")
        if !IsObject(file) {
            throw Error("Unable to open file for writing: " path)
        }

        file.Write(text)
        file.Close()
    }
}