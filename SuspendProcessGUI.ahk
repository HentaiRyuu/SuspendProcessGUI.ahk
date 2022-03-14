#NoEnv
#SingleInstance, force
#Include, SuspendProcess.ahk
#Include, RunCMD.ahk
#Include, Log_System.ahk

global PList, last_pname, PNEdit


LoadLogSetting("Setting.ini", 1)
CreateLogGUI()

Gui, Add, ListView, w700 h300 vProcLV HwndProcLV_Hwnd, |PID|Process Path|Status
fn := Func("Suspend").bind()
GuiControl, +g, %ProcLV_Hwnd% , %fn%
Gui, Add, ComboBox, w235 vPNEdit HwndPNHwnd, chrome||mspaint|notepad|discord|steam|notepad++
fn:=Func("PNameEdit").bind()
GuiControl, +g, %PNHwnd% , %fn%
Gui,Add, Button, x+5 y+-23 w150 HwndRefresh, Refresh
fn:=Func("Refresh").bind()
GuiControl, +g, %Refresh% , %fn%
Gui,Add, Button, x+5 y+-23 w150 HwndSuspendAll, Suspend All
fn:=Func("SuspendAll").bind()
GuiControl, +g, %SuspendAll% , %fn%
Gui,Add, Button, x+5 y+-23 w150 HwndResumeAll, Resume All
fn:=Func("ResumeAll").bind()
GuiControl, +g, %ResumeAll% , %fn%
Gui,Show,, Suspend Process List

LV_ModifyCol(1, 24)
LV_ModifyCol(2, 50)
LV_ModifyCol(3, 620)
LV_ModifyCol(4, 0)

ImageListID := IL_Create()
LV_SetImageList(ImageListID)
IL_Add(ImageListID, "shell32.dll", 177) 
IL_Add(ImageListID, "shell32.dll", 28) 

; Edit Process NO exe here

Gui, Submit, NoHide
GetUpdate(PNEdit)
Return

PNameEdit(){
    Gui, Submit, NoHide
    last_pname := PNEdit
}

GetUpdate(ProcessName){
    
    last_pname := ProcessName

    PList:={}
    PList.PID:=[]
    PList.PName:=[]
    PList.Hwnd:=[]
    ; Edit Command Here
    cmd =
    (
    $aaa = get-process %ProcessName%
    foreach($p in $aaa) {
    Write-Host -NoNewline $p.Path ':' $p.Id
    $temp_status = 1
    foreach($pt in $p.Threads) {
        if($pt.WaitReason -eq 'Suspended' ) {
        Write-Output ':1'
        $temp_status = 0
        break 
        }
    }
    if($temp_status) {
        Write-Output ':0'
    }
    }
    )

    cmdout:=RunCMD("powershell " . cmd)
    ;Clipboard := cmdout


    ; Edit your Regex here
    regex=O)(.*\.exe)\s:\s(\d+):(\d)

    Loop, Parse, cmdout, `r
    {
        if RegExMatch(A_LoopField, regex, Match)
        {
            Match1 := Match.value(1) ; Process Full Path
            Match2 := Match.value(2) ; PID
            Match3 := Match.value(3) ; Suspend Status (0/1)
            PList.Path.Push(Match1)
            PList.PID.Push(Match2)
            PList.PS.Push(Match3)
            
            If (Match3 = 0){
                SIcon := 1
            }
            Else{
                SIcon := 2
            }
            LV_Add("Icon" . SIcon,, Match2, Match1, Match3)
        }
    }
}


;====================

Suspend(PID,varName)
{
    Gui, Submit, NoHide

    if (A_GuiEvent = "DoubleClick")
    {
        LV_GetText(PID, A_EventInfo, 2)
        LV_GetText(Status, A_EventInfo, 4)
        
        If (Status=0)
        {
            Process_Suspend(PID)
            
            LV_Modify(A_EventInfo , "Icon2", ,,, 1)
            LogAdd("User", [1], "Suspend PID: " . PID)
        }
        Else
        {
            Process_Resume(PID)
            LV_Modify(A_EventInfo , "Icon1", ,,, 0)
            LogAdd("User", [1], "Resume PID: " . PID)
        }
    }


}

SuspendAll()
{
    LogAdd("User", [1], "Suspend All")
    for i,v in PList.PID{
        Process_Suspend(v)
    }
    Refresh()
}

ResumeAll()
{
    LogAdd("User", [1], "Resume All")
    for i,v in PList.PID{
        Process_Resume(v)
    }
    Refresh()
}

Refresh()
{
    LV_Delete()
    GetUpdate(last_pname)
}

;====================

GuiClose:
ExitApp
return
