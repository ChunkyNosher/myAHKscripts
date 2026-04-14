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
        this.registry := app["registry"]
        this.modifiers := this.store.GetModifiers()
        this.actionTypes := Schema.BindingTypes
        this.actionsPath := this.registry.GetActionDatabasePath()
        this.selectedKeyId := ""
        this.selectedModifierId := this.modifiers.Length ? this.modifiers[1]["id"] : ""
        this.cellEditRowNumber := 0
        this.cellEditColumnNumber := 0
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

        this.tabs := this.gui.AddTab3("x10 y10 w1298 h700", ["Mappings", "Action Database", "Settings"])

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
        this.mappingList.OnNotify(-2, ObjBindMethod(this, "OnMappingListClickNotify"))

        this.gui.AddGroupBox("x1008 y78 w278 h560", "Binding Editor")
        this.selectedKeyText := this.gui.AddText("x1022 y108 w248 h40", "Select a key from the mappings list.")
        this.gui.AddText("x1022 y162 w64 h23 +0x200", "Modifier")
        this.modifierDropDown := this.gui.AddDropDownList("x1092 y160 w178 Choose1", this.GetModifierLabels())
        this.modifierDropDown.OnEvent("Change", ObjBindMethod(this, "OnModifierChanged"))
        this.modifierDropDown.Enabled := false

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
        this.actionDatabaseEdit := this.gui.AddEdit("x24 y48 w1246 h510 WantTab +Multi")

        this.validateActionsButton := this.gui.AddButton("x24 y570 w110 h30", "Validate")
        this.validateActionsButton.OnEvent("Click", ObjBindMethod(this, "OnValidateActionDatabase"))

        this.saveActionsButton := this.gui.AddButton("x146 y570 w110 h30", "Save")
        this.saveActionsButton.OnEvent("Click", ObjBindMethod(this, "OnSaveActionDatabase"))

        this.reloadActionsButton := this.gui.AddButton("x268 y570 w140 h30", "Reload From Disk")
        this.reloadActionsButton.OnEvent("Click", ObjBindMethod(this, "OnReloadActionDatabase"))

        this.actionDatabaseOutput := this.gui.AddEdit("x24 y612 w1246 h90 ReadOnly +Multi")

        this.tabs.UseTab(3)
        this.gui.AddText("x24 y54 w140 h23 +0x200", "Config JSON")
        this.configPathEdit := this.gui.AddEdit("x170 y50 w1100 h24 ReadOnly", this.store.GetConfigPath())

        this.gui.AddText("x24 y94 w140 h23 +0x200", "Defaults JSON")
        this.defaultsPathEdit := this.gui.AddEdit("x170 y90 w1100 h24 ReadOnly", this.store.GetDefaultsPath())

        this.gui.AddText("x24 y134 w140 h23 +0x200", "Action Database")
        this.actionsPathEdit := this.gui.AddEdit("x170 y130 w1100 h24 ReadOnly", this.actionsPath)

        this.gui.AddText("x24 y174 w140 h23 +0x200", "Backup Folder")
        this.backupPathEdit := this.gui.AddEdit("x170 y170 w1100 h24 ReadOnly", this.store.GetBackupDir())

        this.reloadConfigButton := this.gui.AddButton("x24 y222 w120 h30", "Reload Config")
        this.reloadConfigButton.OnEvent("Click", ObjBindMethod(this, "OnReloadConfig"))

        this.openBackupFolderButton := this.gui.AddButton("x156 y222 w140 h30", "Open Backup Folder")
        this.openBackupFolderButton.OnEvent("Click", ObjBindMethod(this, "OnOpenBackupFolder"))

        this.tabs.UseTab()

        this.cellEdit := this.gui.AddEdit("x0 y0 w0 h23 Hidden")
        this.cellEdit.OnEvent("LoseFocus", ObjBindMethod(this, "OnCellEditLoseFocus"))

        this.defaultButton := this.gui.AddButton("x0 y0 w0 h0 Hidden Default", "Commit")
        this.defaultButton.OnEvent("Click", ObjBindMethod(this, "OnDefaultButtonClick"))

        this.statusText := this.gui.AddText("x18 y720 w1288 h23 +0x200", "Ready.")
    }

    ReloadFromDisk() {
        this.HideCellEdit()
        this.store.Reload()
        this.registry.Reload()
        this.actionDatabaseEdit.Value := FileRead(this.actionsPath, "UTF-8")
        this.actionDatabaseOutput.Value := ""
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
            targetRow := this.FindFilteredRowIndex(this.selectedKeyId)
            if (targetRow = 0) {
                targetRow := 1
            }
            this.mappingList.Modify(targetRow, "Select Focus Vis")
        } else {
            this.selectedKeyId := ""
            this.selectedKeyText.Value := "No keys match the current filter."
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
        this.selectedKeyText.Value := row["keyLabel"] " (" row["keyId"] ")"
        this.SyncModifierIndicator()
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
        if (this.selectedModifierId != "") {
            return this.selectedModifierId
        }

        index := this.modifierDropDown.Value
        if (index < 1 || index > this.modifiers.Length) {
            return this.modifiers.Length ? this.modifiers[1]["id"] : ""
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
        this.HideCellEdit()
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

    OnMappingListClickNotify(ctrl, lParam) {
        cell := this.GetClickedCell(ctrl, lParam)
        if !IsObject(cell) {
            this.CommitCellEdit()
            return
        }

        this.CommitCellEdit()
        this.selectedKeyId := this.filteredRows[cell["row"]]["keyId"]
        this.SetSelectedModifierByColumn(cell["column"])
        this.mappingList.Modify(cell["row"], "Select Focus Vis")
        this.SyncSelectedBinding()

        if (cell["column"] >= 3) {
            this.BeginCellEdit(cell["row"], cell["column"])
        }
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
        this.HideCellEdit()

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
        this.HideCellEdit()
        this.SyncSelectedBinding()
        this.SetStatus("Selection reloaded from current store state.")
    }

    OnRevertOverride(*) {
        this.HideCellEdit()

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

    OnValidateActionDatabase(*) {
        result := this.registry.ValidateActionDatabaseText(this.actionDatabaseEdit.Value)
        this.actionDatabaseOutput.Value := result["message"]
        this.SetStatus(result["ok"] ? "Action database validation passed." : "Action database validation failed.")
    }

    OnSaveActionDatabase(*) {
        result := this.registry.ValidateActionDatabaseText(this.actionDatabaseEdit.Value)
        this.actionDatabaseOutput.Value := result["message"]
        if !result["ok"] {
            this.SetStatus("Action database was not saved.")
            return
        }

        try {
            saveResult := this.registry.SaveActionDatabaseText(this.actionDatabaseEdit.Value)
            this.actionDatabaseEdit.Value := FileRead(this.actionsPath, "UTF-8")
            this.actionDatabaseOutput.Value := "Saved action database." (saveResult["backupPath"] != "" ? "`r`nBackup: " saveResult["backupPath"] : "")
            this.SetStatus("Action database saved.")
        } catch as err {
            MsgBox(err.Message, "Save Action Database Failed", "Iconx")
            this.SetStatus("Action database save failed.")
        }
    }

    OnReloadActionDatabase(*) {
        this.registry.Reload()
        this.actionDatabaseEdit.Value := FileRead(this.actionsPath, "UTF-8")
        this.actionDatabaseOutput.Value := "Reloaded action database from disk."
        this.SetStatus("Action database reloaded from disk.")
    }

    OnReloadConfig(*) {
        try {
            this.HideCellEdit()
            this.store.Reload()
            this.registry.Reload()
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
        this.statusText.Value := message
    }

    SyncModifierIndicator() {
        modifierId := this.GetSelectedModifierId()
        for index, modifierInfo in this.modifiers {
            if (modifierInfo["id"] = modifierId) {
                this.modifierDropDown.Choose(index)
                return
            }
        }
    }

    SetSelectedModifierByColumn(columnNumber) {
        modifierIndex := columnNumber - 2
        if (modifierIndex < 1 || modifierIndex > this.modifiers.Length) {
            this.selectedModifierId := this.modifiers.Length ? this.modifiers[1]["id"] : ""
            return
        }

        this.selectedModifierId := this.modifiers[modifierIndex]["id"]
        this.modifierDropDown.Choose(modifierIndex)
    }

    GetClickedCell(ctrl, lParam) {
        if (ctrl != this.mappingList) {
            return ""
        }

        pointOffset := (A_PtrSize = 8) ? 44 : 32
        hitX := NumGet(lParam + pointOffset, "Int")
        hitY := NumGet(lParam + pointOffset + 4, "Int")

        hitInfo := Buffer(24, 0)
        NumPut("Int", hitX, hitInfo, 0)
        NumPut("Int", hitY, hitInfo, 4)

        SendMessage(0x1039, 0, hitInfo.Ptr, ctrl)
        rowIndex := NumGet(hitInfo, 12, "Int") + 1
        columnIndex := NumGet(hitInfo, 16, "Int") + 1

        if (rowIndex < 1 || rowIndex > this.filteredRows.Length) {
            return ""
        }

        if (columnIndex < 1 || columnIndex > this.mappingList.GetCount("Column")) {
            return ""
        }

        return Map(
            "row", rowIndex,
            "column", columnIndex
        )
    }

    GetCellRect(rowNumber, columnNumber) {
        rect := Buffer(16, 0)
        NumPut("Int", 0, rect, 0)
        NumPut("Int", columnNumber - 1, rect, 4)

        if !SendMessage(0x1038, rowNumber - 1, rect.Ptr, this.mappingList) {
            return ""
        }

        return Map(
            "x", NumGet(rect, 0, "Int"),
            "y", NumGet(rect, 4, "Int"),
            "w", NumGet(rect, 8, "Int") - NumGet(rect, 0, "Int"),
            "h", NumGet(rect, 12, "Int") - NumGet(rect, 4, "Int")
        )
    }

    BeginCellEdit(rowNumber, columnNumber) {
        cellRect := this.GetCellRect(rowNumber, columnNumber)
        if !IsObject(cellRect) {
            return
        }

        this.cellEditRowNumber := rowNumber
        this.cellEditColumnNumber := columnNumber

        this.mappingList.GetPos(&listX, &listY)
        this.cellEdit.Move(listX + cellRect["x"] + 1, listY + cellRect["y"] + 1, Max(cellRect["w"] - 2, 48), Max(cellRect["h"] - 2, 22))
        this.cellEdit.Value := this.valueEdit.Value
        this.cellEdit.Visible := true
        this.cellEdit.Focus()
    }

    HideCellEdit() {
        if !IsObject(this.cellEdit) {
            return
        }

        this.cellEdit.Visible := false
        this.cellEditRowNumber := 0
        this.cellEditColumnNumber := 0
    }

    OnCellEditLoseFocus(*) {
        this.CommitCellEdit()
    }

    OnDefaultButtonClick(*) {
        if (this.gui.FocusedCtrl = this.cellEdit) {
            this.CommitCellEdit()
            return
        }

        if (this.gui.FocusedCtrl = this.valueEdit) {
            this.OnSaveBinding()
        }
    }

    CommitCellEdit() {
        if !this.cellEdit.Visible {
            return
        }

        rowNumber := this.cellEditRowNumber
        columnNumber := this.cellEditColumnNumber
        typedValue := this.cellEdit.Value
        this.HideCellEdit()

        if (rowNumber < 1 || rowNumber > this.filteredRows.Length || columnNumber < 3) {
            return
        }

        this.selectedKeyId := this.filteredRows[rowNumber]["keyId"]
        this.SetSelectedModifierByColumn(columnNumber)

        try {
            bindingSpec := this.BuildBindingSpecFromTypedValue(typedValue)
            this.store.UpdateBindingSpec(this.selectedKeyId, this.GetSelectedModifierId(), bindingSpec)
            backupPath := this.store.SaveConfig()
            this.LoadMappingRows()
            this.SyncSelectedBinding()
            this.SetStatus("Saved " this.selectedKeyId " / " this.GetSelectedModifierId() (backupPath != "" ? " with backup." : "."))
        } catch as err {
            MsgBox(err.Message, "Save Binding Failed", "Iconx")
            this.SyncSelectedBinding()
            this.SetStatus("Binding save failed.")
        }
    }

    BuildBindingSpecFromTypedValue(rawValue) {
        typedValue := Trim(rawValue)
        lowered := StrLower(typedValue)

        if (typedValue = "") {
            this.typeDropDown.Choose(this.FindActionTypeIndex("empty"))
            return Schema.CreateBindingSpec("empty")
        }

        for _, prefix in [["action:", "action"], ["keys:", "send_keys"], ["send_keys:", "send_keys"], ["text:", "send_text"], ["send_text:", "send_text"]] {
            if (SubStr(lowered, 1, StrLen(prefix[1])) = prefix[1]) {
                value := LTrim(SubStr(typedValue, StrLen(prefix[1]) + 1))
                this.typeDropDown.Choose(this.FindActionTypeIndex(prefix[2]))
                return Schema.CreateBindingSpec(prefix[2], value)
            }
        }

        bindingType := this.GetSelectedActionType()
        if (bindingType = "empty") {
            if IsObject(this.registry.GetActionRecord(typedValue)) {
                bindingType := "action"
            } else if this.LooksLikeSendKeys(typedValue) {
                bindingType := "send_keys"
            } else {
                bindingType := "send_text"
            }
            this.typeDropDown.Choose(this.FindActionTypeIndex(bindingType))
        }

        return Schema.CreateBindingSpec(bindingType, typedValue)
    }

    LooksLikeSendKeys(value) {
        return RegExMatch(value, "[\^!+#{}]") || RegExMatch(value, "i)\b(F\d+|Numpad\w+|Tab|Enter|Esc|Escape|Home|End|PgUp|PgDn|Up|Down|Left|Right|Delete|Insert)\b")
    }
}