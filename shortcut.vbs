Set WshShell = CreateObject("WScript.Shell")
desktop = WshShell.SpecialFolders("Desktop")

Set shortcut = WshShell.CreateShortcut(desktop & "\背诵表.lnk")
shortcut.TargetPath = "A:\艾宾浩斯曲线\start.bat"
shortcut.WindowStyle = 7
shortcut.Description = "艾宾浩斯记忆曲线背诵表"
shortcut.Save()

MsgBox "桌面快捷方式已创建！双击「背诵表」即可打开。", 64, "完成"
