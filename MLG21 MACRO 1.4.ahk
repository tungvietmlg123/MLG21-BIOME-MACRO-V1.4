; <=======================================================================>
; SAVE INSTRUCTIONS: Open Notepad -> Paste code -> Click File > Save As 
; Select Encoding as "UTF-8 with BOM" and save your .ahk file!
; <=======================================================================>

#Requires AutoHotkey v1.1
#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

global IniFile          := A_ScriptDir . "\config.ini"
global iniFilePath      := A_ScriptDir . "\..\settings.ini"
global WebhookURL       := ""
global PSLink           := ""
global IsRunning        := false
global MacroStartTime   := 0
global AntiAfkEnabled   := 0
global AutoCraftEnabled := 0

global craftState       := "ADDING" ; IDLE, ADDING, CRAFTING
global craftTimer       := 0

global prevBiome    := "None"
global prevState    := "None"
global biomeColors  := { "NORMAL":16777215, "SAND STORM":16040572, "HELL":6033945, "STARFALL":6784224, "CORRUPTION":9454335, "NULL":0, "GLITCHED":6684517, "WINDY":9566207, "SNOWY":12908022, "RAINY":4425215, "DREAMSPACE":16743935, "PUMPKIN MOON":13983497, "GRAVEYARD":16777215, "BLOOD RAIN":16711680, "CYBERSPACE":2904999, "EGGLAND":65535, "SINGULARITY":14716000, "INCINERATOR":16736031, "BLAZING SUN":16760650}

EnvGet, LocalAppData, LOCALAPPDATA

OnExit("ExitHandler")

IniRead, SavedWebhook, %IniFile%, Settings, WebhookURL, %A_Space%
IniRead, SavedPSLink, %IniFile%, Settings, PSLink, %A_Space%
IniRead, SavedAntiAfk, %IniFile%, Settings, AntiAfk, 0
IniRead, SavedAutoCraft, %IniFile%, Settings, AutoCraft, 0

if (SavedWebhook = "ERROR" || InStr(SavedWebhook, "http") = 0)
    SavedWebhook := ""
if (SavedPSLink = "ERROR" || InStr(SavedPSLink, "http") = 0)
    SavedPSLink := ""

; ==============================================================================
; USER INTERFACE (V1.4)
; ==============================================================================
Gui, Color, 0x0A0B0E, 0x15171E
Gui, +Resize -MaximizeBox

; Header Title
Gui, Font, s14 Bold, Segoe UI
Gui, Add, Text, x15 y10 w440 h24 +Center c0x00FFC8, MLG21 MACRO v1.4
Gui, Font, s8 Italic, Segoe UI
Gui, Add, Text, x15 y32 w440 h16 +Center c0x6C727D, Sol's RNG Biome Detector For Beginner (F1: Start | F2: Stop)

; Native Tab Control (Chỉ còn SETTINGS và CREDITS)
Gui, Font, s9 Bold, Segoe UI
Gui, Add, Tab2, x15 y55 w440 h225 +Buttons c0x00FFC8, SETTINGS|CREDITS

    ; --------------------------------------------------------------------------
    ; TAB 1: SETTINGS (Mục Anti-AFK nằm dưới Test Webhook)
    ; --------------------------------------------------------------------------
    Gui, Tab, SETTINGS
    Gui, Font, s9 Normal, Segoe UI
    Gui, Add, Text, x28 y85 w415 h16 c0xA2A6B0, Discord Webhook URL:
    Gui, Add, Edit, x28 y102 w415 h22 vtxtWebhook c0xFFFFFF Background0x1C1F2B, %SavedWebhook%

    Gui, Add, Text, x28 y130 w415 h16 c0xA2A6B0, Roblox Private Server (PS) Link:
    Gui, Add, Edit, x28 y147 w415 h22 vtxtPSLink c0xFFFFFF Background0x1C1F2B, %SavedPSLink%

    Gui, Font, s9 Bold, Segoe UI
    Gui, Add, Button, x28 y176 w415 h30 gTestWebhook c0xF1C40F, TEST WEBHOOK CONNECTION

    isCheckedAntiAfk := SavedAntiAfk ? "Checked" : ""
    Gui, Add, CheckBox, x28 y215 w415 h24 vchkAntiAfk %isCheckedAntiAfk% c0x00FFC8, Enable Anti-AFK (Auto click every 1s)

    ; --------------------------------------------------------------------------
    ; TAB 2: CREDITS (Đã cập nhật đầy đủ thông tin & Macro Tester)
    ; --------------------------------------------------------------------------
    Gui, Tab, CREDITS
    Gui, Font, s9 Bold, Segoe UI
    Gui, Add, Text, x28 y80 w415 h18 c0x00FFC8, • 『Biome Hunter 367』
    Gui, Add, Text, x28 y100 w415 h18 c0xA2A6B0, • BY @MLG21 (Ping4help) & Huaejo (Co-Owner)
    Gui, Font, s9 Normal, Segoe UI
    Gui, Add, Text, x28 y122 w415 h18 c0x3498DB, • Macro Testers: Mouche, Dante, ohthatspebble
    Gui, Add, Text, x28 y144 w415 h18 c0xE67E22, • What We Offer: Glitched, Dreamspace, Cyberspace & more!
    Gui, Add, Text, x28 y166 w415 h18 c0x2ECC71, • Active community to help cook up rare biomes!
    Gui, Add, Text, x28 y188 w415 h35 c0xF1C40F, • Want to help cook? Create a ticket for request!

; End of Tabs container
Gui, Tab

; ------------------------------------------------------------------------------
; SYSTEM STATUS (Always visible)
; ------------------------------------------------------------------------------
Gui, Font, s9 Bold, Segoe UI
Gui, Add, GroupBox, x15 y290 w440 h50 c0x2A2E3D,  SYSTEM STATUS  
Gui, Font, s9 Italic Bold, Segoe UI
Gui, Add, Text, x25 y309 w420 h20 vtxtStatus +Center c0xF1C40F, Status: Waiting to start... (Press F1 / F2)

; ------------------------------------------------------------------------------
; CONTROL BUTTONS (Always visible)
; ------------------------------------------------------------------------------
Gui, Font, s9 Bold, Segoe UI
Gui, Add, Button, x15 y350 w214 h38 vBtnStart +Default gStartMacro c0x2ECC71, START MACRO [F1]
Gui, Add, Button, x241 y350 w214 h38 vBtnStop gStopManage c0xE74C3C, STOP MACRO [F2]

Gui, Show, w470 h405, MLG21 Biome Macro V1.4

SetTimer, CheckBiomeTask, Off
SetTimer, UpdateGuiTimer, Off
SetTimer, AntiAfkTask, Off
return

GuiClose:
ExitApp

ExitHandler(ExitReason, ExitCode) {
    global WebhookURL, IsRunning
    if (IsRunning && WebhookURL != "" && InStr(WebhookURL, "discord.com/api/webhooks/") > 0) {
        SendStopStatusAlert("Application Closed")
    }
    return 0
}

; ==============================================================================
; HOTKEYS (F1 to Start, F2 to Stop)
; ==============================================================================
F1::
    Gosub, StartMacro
return

F2::
    Gosub, StopMacro
return

; ==============================================================================
; BUTTON ANIMATION HELPER
; ==============================================================================
AnimateButton(ctrlHwnd) {
    SoundBeep, 700, 40
    SendMessage, 0xF3, 1, 0,, ahk_id %ctrlHwnd%
    Sleep, 100
    SendMessage, 0xF3, 0, 0,, ahk_id %ctrlHwnd%
}

; ==============================================================================
; CONTROL BUTTONS
; ==============================================================================
StartMacro:
    GuiControlGet, hBtn, Hwnd, BtnStart
    AnimateButton(hBtn)
    Gui, Submit, NoHide

    if (IsRunning) {
        return
    }

    if (!ProcessExist("RobloxPlayerBeta.exe")) {
        MsgBox, 16, MLG21 Macro Error, You do not have Roblox open! How can the macro function without it? =))
        return
    }

    WebhookURL       := txtWebhook
    PSLink           := txtPSLink
    AntiAfkEnabled   := chkAntiAfk

    if (WebhookURL = "" || InStr(WebhookURL, "discord.com/api/webhooks/") == 0) {
        MsgBox, 48, MLG21 Macro Warning, Please enter a valid Discord Webhook URL first!
        return
    }

    IniWrite, %WebhookURL%, %IniFile%, Settings, WebhookURL
    IniWrite, %PSLink%, %IniFile%, Settings, PSLink
    IniWrite, %AntiAfkEnabled%, %IniFile%, Settings, AntiAfk

    IsRunning := true
    MacroStartTime := A_TickCount
    prevBiome := "None"
    prevState := "None"
    
    SendStartStatusAlert()

    GuiControl, +c0x2ECC71, txtStatus
    SetTimer, CheckBiomeTask, 1000
    SetTimer, UpdateGuiTimer, 1000
    
    if (AntiAfkEnabled) {
        SetTimer, AntiAfkTask, 1000
    }
return

StopMacro:
StopManage:
    GuiControlGet, hBtn, Hwnd, BtnStop
    AnimateButton(hBtn)
    Gui, Submit, NoHide
    
    if (!IsRunning) {
        return
    }

    SetTimer, CheckBiomeTask, Off
    SetTimer, UpdateGuiTimer, Off
    SetTimer, AntiAfkTask, Off
    IsRunning := false

    if (WebhookURL != "" && InStr(WebhookURL, "discord.com/api/webhooks/") > 0) {
        SendStopStatusAlert("User Stopped")
    }

    MacroStartTime := 0
    GuiControl, +c0xE74C3C, txtStatus
    GuiControl,, txtStatus, Status: Stopped.
return

TestWebhook:
    GuiControlGet, hBtn, Hwnd, BtnTest
    AnimateButton(hBtn)
    Gui, Submit, NoHide
    WebhookURL    := txtWebhook
    PSLink        := txtPSLink

    if (WebhookURL = "" || InStr(WebhookURL, "discord.com/api/webhooks/") == 0) {
        MsgBox, 48, MLG21 Macro Warning, Please enter a valid Discord Webhook URL first!
        return
    }

    SendTestAlert("Webhook Successfully Tested", 65535)
return

; ==============================================================================
; GUI TIMER & DURATION FORMATTER
; ==============================================================================
UpdateGuiTimer:
    if (!IsRunning || !MacroStartTime)
        return

    elapsedSec := Floor((A_TickCount - MacroStartTime) / 1000)
    days := Floor(elapsedSec / 86400)
    hours := Floor(Mod(elapsedSec, 86400) / 3600)
    minutes := Floor(Mod(elapsedSec, 3600) / 60)
    seconds := Mod(elapsedSec, 60)

    timeStr := ""
    if (days > 0)
        timeStr := days . "d " . hours . "h " . minutes . "m " . seconds . "s"
    else if (hours > 0)
        timeStr := hours . "h " . minutes . "m " . seconds . "s"
    else if (minutes > 0)
        timeStr := minutes . "m " . seconds . "s"
    else
        timeStr := seconds . "s"

    GuiControl,, txtStatus, Status: Running [%timeStr%]
return

GetFormattedCurrentTime() {
    FormatTime, outTime,, yyyy-MM-dd HH:mm:ss
    return outTime
}

GetISOTimeStamp() {
    return SubStr(A_NowUTC,1,4) . "-" . SubStr(A_NowUTC,5,2) . "-" . SubStr(A_NowUTC,7,2) . "T" . SubStr(A_NowUTC,9,2) . ":" . SubStr(A_NowUTC,11,2) . ":" . SubStr(A_NowUTC,13,2) . ".000Z"
}

GetElapsedTimeFormatted() {
    if (!MacroStartTime)
        return "0s"
    
    elapsedSec := Floor((A_TickCount - MacroStartTime) / 1000)
    days := Floor(elapsedSec / 86400)
    hours := Floor(Mod(elapsedSec, 86400) / 3600)
    minutes := Floor(Mod(elapsedSec, 3600) / 60)
    seconds := Mod(elapsedSec, 60)

    timeStr := ""
    if (days > 0)
        timeStr := days . "d " . hours . "h " . minutes . "m " . seconds . "s"
    else if (hours > 0)
        timeStr := hours . "h " . minutes . "m " . seconds . "s"
    else if (minutes > 0)
        timeStr := minutes . "m " . seconds . "s"
    else
        timeStr := seconds . "s"
    
    return timeStr
}

; ==============================================================================
; WEBHOOK SENDER FUNCTIONS
; ==============================================================================
SendTestAlert(titleText, embedColor) {
    req := ComObjCreate("Msxml2.XMLHTTP")
    req.open("POST", WebhookURL, false)
    req.setRequestHeader("Content-Type", "application/json")
    currentTime := GetFormattedCurrentTime()

    payload =
    (
    {
      "embeds": [
        {
          "author": {
            "name": "MLG21macro v1.4 by tungvietmlg"
          },
          "title": "%titleText%",
          "color": %embedColor%,
          "description": "Private Server Link:\n%PSLink%",
          "fields": [
            {"name": "Biome Hunter 367", "value": "%currentTime%", "inline": false}
          ]
        }
      ]
    }
    )
    try {
        req.send(payload)
    } catch e {
    }
}

SendStartStatusAlert() {
    req := ComObjCreate("Msxml2.XMLHTTP")
    req.open("POST", WebhookURL, false)
    req.setRequestHeader("Content-Type", "application/json")
    currentTime := GetFormattedCurrentTime()

    payload =
    (
    {
      "content": "MLG21 BIOME MACRO STARTED!(v1.4)",
      "embeds": [
        {
          "author": {
            "name": "mlg21macro v1.4 by tungvietmlg"
          },
          "title": "Macro Status: Active",
          "color": 65280,
          "fields": [
            {"name": "Biome Hunter 367", "value": "%currentTime%", "inline": false}
          ]
        }
      ]
    }
    )
    try {
        req.send(payload)
    } catch e {
    }
}

SendStopStatusAlert(reason := "Stopped") {
    req := ComObjCreate("Msxml2.XMLHTTP")
    req.open("POST", WebhookURL, false)
    req.setRequestHeader("Content-Type", "application/json")
    currentTime := GetFormattedCurrentTime()
    totalTimeRan := GetElapsedTimeFormatted()

    payload =
    (
    {
      "content": "MLG21 BIOME MACRO STOPPED!",
      "embeds": [
        {
          "author": {
            "name": "mlg21macro v1.4 by tungvietmlg"
          },
          "title": "Macro Status: Inactive",
          "color": 16711680,
          "fields": [
            {"name": "Total Uptime", "value": "%totalTimeRan%", "inline": false},
            {"name": "Reason", "value": "%reason%", "inline": false},
            {"name": "Biome Hunter 367", "value": "%currentTime%", "inline": false}
          ]
        }
      ]
    }
    )
    try {
        req.send(payload)
    } catch e {
    }
}

ProcessExist(Name) {
    for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
        if (process.Name = Name)
            return true
    return false
}

; ==============================================================================
; ANTI-AFK TASK (Auto click left mouse every 1s)
; ==============================================================================
AntiAfkTask:
    if (!IsRunning || !AntiAfkEnabled) {
        SetTimer, AntiAfkTask, Off
        return
    }

    if (!ProcessExist("RobloxPlayerBeta.exe"))
        return

    if (IsRunning && AntiAfkEnabled) {
        Click, Left
    }
return

; ==============================================================================
; LOG FILE READER TASK (Biome & Aura Checker)
; ==============================================================================
CheckBiomeTask:
    if (!IsRunning) {
        SetTimer, CheckBiomeTask, Off
        return
    }

    if (!ProcessExist("RobloxPlayerBeta.exe")) {
        return
    }
    
    logDir := LocalAppData "\Roblox\logs"
    newestTime := 0
    newestFile := ""

    Loop, Files, %logDir%\*.log, F
    {
        if (A_LoopFileTimeModified > newestTime) {
            newestTime := A_LoopFileTimeModified
            newestFile := A_LoopFileFullPath
        }
    }

    if !newestFile
        return

    file := FileOpen(newestFile, "r")
    if !IsObject(file)
        return

    size := file.Length
    chunkSize := 10240
    if (size > chunkSize)
        file.Seek(-chunkSize, 2)
    contentFile := file.Read()
    file.Close()

    lines := StrSplit(contentFile, "`n")
    regexLine := """state"":""((?:\\.|[^""])*)"".*?""largeImage"":\{""hoverText"":""((?:\\.|[^""])*)"""
    
    state := ""
    biome := ""
    
    Loop % lines.MaxIndex()
    {
        line := lines[lines.MaxIndex() - A_Index + 1]
        if InStr(line, "[BloxstrapRPC]")
        {
            if RegExMatch(line, regexLine, m) {
                state := m1
                biome := m2
                break
            }
        }
    }

    ; -- BIOME CHECKING --
    if (biome && biome != "" && biome != prevBiome && IsRunning)
    {
        biomeKey := "Biome" StrReplace(biome, " ", "")
        IniRead, isBiomeEnabled, %iniFilePath%, "Biomes", %biomeKey%, 1

        if (isBiomeEnabled = 1 || biome = "GLITCHED" || biome = "DREAMSPACE" || biome = "CYBERSPACE") {
            prevBiome := biome
            biome_url := StrReplace(biome, " ", "_")
            thumbnail_url := "https://purestellenium.github.io/biome_thumb/" biome_url ".png"

            color := biomeColors.HasKey(biome) ? biomeColors[biome] : 16777215
            currentTimeStr := GetFormattedCurrentTime()
            isoTime := GetISOTimeStamp()

            if (biome = "GLITCHED" || biome = "DREAMSPACE" || biome = "CYBERSPACE") {
                contentMsg := "@everyone"
            } else {
                contentMsg := "(tungvietmlg) For Any Bug!"
            }

            json =
            (
            {
              "embeds": [
                {
                  "author": {
                    "name": "mlg21macro v1.4 by tungvietmlg"
                  },
                  "description": "> ### Biome Started: %biome%\n> ### [Join Server](%PSLink%)",
                  "color": %color%,
                  "thumbnail": {"url": "%thumbnail_url%"},
                  "fields": [
                    {"name": "Biome Hunter 367", "value": "%currentTimeStr%", "inline": false}
                  ],
                  "timestamp": "%isoTime%"
                }
              ],
              "content": "%contentMsg%"
            }
            )

            http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            http.Open("POST", WebhookURL, false)
            http.SetRequestHeader("Content-Type", "application/json")
            http.Send(json)
        }
    }

    ; -- AURA CHECKING --
    if (state && state != "In Main Menu" && state != "Equipped _None_" && state != "" && state != prevState && IsRunning)
    {
        if (prevState != "None") {
            needle := Chr(92) Chr(34)
            pos1 := InStr(state, needle)
            auraName := (pos1 ? (pos2 := InStr(state, needle, false, pos1 + StrLen(needle))) && pos2>pos1 ? SubStr(state, pos1 + StrLen(needle), pos2 - (pos1 + StrLen(needle))) : state : state)
            currentTimeStr := GetFormattedCurrentTime()
            isoTime := GetISOTimeStamp()

            json =
            (
            {
              "embeds": [
                {
                  "author": {
                    "name": "mlg21macro v1.4 by tungvietmlg"
                  },
                  "description": "> ### Aura Equipped: %auraName%\n> ### [Join Server](%PSLink%)",
                  "color": 16777215,
                  "fields": [
                    {"name": "Biome Hunter 367", "value": "%currentTimeStr%", "inline": false}
                  ],
                  "timestamp": "%isoTime%"
                }
              ],
              "content": ""
            }
            )

            http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            http.Open("POST", WebhookURL, false)
            http.SetRequestHeader("Content-Type", "application/json")
            http.Send(json)
        }
        prevState := state
    }
return