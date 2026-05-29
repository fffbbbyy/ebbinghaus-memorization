Set ws = CreateObject("WScript.Shell")
desktop = ws.SpecialFolders("Desktop")
target = "A:\艾宾浩斯曲线\index.html"
shortcut = desktop & "\艾宾浩斯背诵表.lnk"
Set link = ws.CreateShortcut(shortcut)
link.TargetPath = target
link.Description = "艾宾浩斯遗忘曲线背诵计划表"
link.Save
WScript.Echo "OK: " & shortcut
