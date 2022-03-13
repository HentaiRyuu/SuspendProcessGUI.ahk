#NoEnv
#SingleInstance, force
#Include, SuspendProcess.ahk
#Include, RunCMD.ahk
#Include, Log_System.ahk

global PList
PList:={}
PList.PID:=[]
PList.PName:=[]
PList.Hwnd:=[]

LoadLogSetting("Setting.ini", 1)
CreateLogGUI()

; Edit Process exe here
ProcExe= python.exe

; Edit Command Here
CMD = WMIC path win32_process where "caption='%ProcExe%'" get Processid,Commandline

cmdout:=RunCMD(CMD)

; Edit your Regex here
regex=O)(\".*\").*\s(\d+)

Loop, Parse, cmdout, `r
{
    if RegExMatch(A_LoopField, regex, Match)
    {
        If RegExMatch(Match.value(1) . Match.value(2), "(\r|\n)")
            Continue
        Match1 := Match.value(1) ; Process Full Path
        Match2 := Match.value(2) ; PID
        PList.PName.Push(Match1)
        PList.PID.Push(Match2)
        LogAdd("User", [1], "Found PID: " Match.value(2) " " Match.value(1))
        Gui, Add, Checkbox, w400 vProcV%A_Index% hwndProc%A_Index%, %Match2% - %Match1%
        fn:=Func("Suspend").bind(Match2,A_Index)
        hwnd := Proc%A_Index%
        PList.Hwnd.Push("ProcV" . A_Index)
        GuiControl, +g, %hwnd% , %fn%
    }
}
Gui,Add, Button, w200 HwndSuspendAll, Suspend All
fn:=Func("SuspendAll").bind()
GuiControl, +g, %SuspendAll% , %fn%
Gui,Add, Button, x+5 y+-23 w200 HwndResumeAll, Resume All
fn:=Func("ResumeAll").bind()
GuiControl, +g, %ResumeAll% , %fn%
Gui,Show,, Suspend Process List
Return

;====================

Suspend(PID,varName)
{
    Gui, Submit, NoHide
    IsChecked := ProcV%varName%
If (IsChecked)
{
    Process_Suspend(PID)
    LogAdd("User", [1], "Suspend PID: " . PID)
}
Else
{
    Process_Resume(PID)
    LogAdd("User", [1], "Resume PID: " . PID)
}
}

SuspendAll()
{
    LogAdd("User", [1], "Suspend All")
    for i,v in PList.Hwnd{
        GuiControl, , %v%, 1
        PID := PList.PID[i]
        Process_Suspend(PID)
    }
}

ResumeAll()
{
    LogAdd("User", [1], "Resume All")
    for i,v in PList.Hwnd{
        GuiControl, , %v%, 0
        PID := PList.PID[i]
        Process_Resume(PID)
    }
}

;====================

GuiClose:
ExitApp
return
