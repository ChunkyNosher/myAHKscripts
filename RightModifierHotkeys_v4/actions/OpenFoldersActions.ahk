#Requires AutoHotkey v2.0

RegisterOpenFoldersActions(registry) {
    OpenFolders_RegisterAction(registry, "open_all_folders", OpenAllFolders)
}

OpenAllFolders() {
    longWait := 2000
    medWait := 1000
    shortWait := 550
    quickWait := 350

    folderPaths := [
        "D:\Chunky's Master Folder External Drive",
        "Downloads",
        "D:\Chunky's Master Folder External Drive\Chunky Premiere Pro Folder\Video Specific Assets and Footage\LIMC video\Images",
        "D:\Chunky's Master Folder External Drive\Chunky Premiere Pro Folder\Video Specific Assets and Footage\LIMC video\Video",
        "D:\Chunky's Master Folder External Drive\Chunky Premiere Pro Folder\Video Specific Assets and Footage\LIMC video\Footage and Audio Clips",
        "E:\Chunky's Master Folder\Snipping Tool and Screenshots\Screenshots",
        "E:\Chunky's Master Folder\Chunky Photoshop Folder\Final Project",
        "E:\Chunky's Master Folder\Recordings",
        "D:\Chunky's Master Folder External Drive\Chunky Premiere Pro Folder\Universal Assets",
        "D:\Chunky's Master Folder External Drive\Chunky Premiere Pro Folder\Universal Assets\Universal Video Assets",
        "D:\Chunky's Master Folder External Drive\Chunky Premiere Pro Folder\Universal Assets\Universal Image Assets",
        "D:\Chunky's Master Folder External Drive\Chunky Premiere Pro Folder\Universal Assets\Universal Audio Assets",
        "D:\Chunky's Master Folder External Drive\Chunky Premiere Pro Folder\Universal Assets\Universal Audio Assets\Music",
        "D:\Chunky's Master Folder External Drive\Chunky Premiere Pro Folder\Universal Assets\Universal Audio Assets\SFX",
        "E:\Chunky's Master Folder\Chunky Audition Folder\Final Recordings",
        "E:\Chunky's Master Folder\Chunky After Effects Folder\Final Projects"
    ]

    Run("explorer.exe")
    WinActivate("ahk_exe explorer.exe")
    Sleep(longWait)

    totalFolders := folderPaths.Length
    for index, folderPath in folderPaths {
        SendInput("!d")
        Sleep(quickWait)
        SendText(folderPath)
        Sleep(quickWait)
        SendInput("{Enter}")
        Sleep(shortWait)

        if index != totalFolders {
            SendInput("^t")
            Sleep(shortWait)
        }

        if index = 1 {
            Sleep(medWait)
        }
    }

    return totalFolders
}

OpenFolders_RegisterAction(registry, actionId, callback) {
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