#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#Include %A_ScriptDir%\ui\image\Gdip_ResizeBitmap.ahk
#Include %A_ScriptDir%\ui\image\Gdip_RotateBitmap.ahk

ShowPlayer(mapGuiWidth, scale, leftMargin, topMargin, mapData, gameMemoryData, uiData) {
    StartTime := A_TickCount
    serverScale := 2 
    Angle := 45
    opacity := 0.9
    padding := 150

    ; get relative position of player in world
    ; xpos is absolute world pos in game
    ; each map has offset x and y which is absolute world position
    xPosDot := ((gameMemoryData["xPos"] - mapData["mapOffsetX"]) * serverScale) + padding
    yPosDot := ((gameMemoryData["yPos"] - mapData["mapOffsetY"]) * serverScale) + padding
    ; WriteLog("xPos raw " gameMemoryData["xPos"] " yPos raw " gameMemoryData["yPos"])
    ; WriteLog("xPosDot " xPosDot " yPosDot " yPosDot)
    ; WriteLog("xPosDot no trim " ((gameMemoryData["xPos"] - mapData["mapOffsetX"]) * serverScale) " yPosDot no trim " ((gameMemoryData["yPos"] - mapData["mapOffsetY"]) * serverScale))
    ; WriteLog("leftTrimmed: " mapData["leftTrimmed"] " topTrimmed: " mapData["topTrimmed"] )
    ; WriteLog("leftTrimmed: " mapDatca["leftTrimmed"] " topTrimmed: " mapData["topTrimmed"] )
    
    ;WriteLog("X playerpos " xPosDot " Y playerpos " yPosDot)
    


    
    sFile := mapData["sFile"] ; downloaded map image
    Width := uiData["sizeWidth"]
    Height := uiData["sizeHeight"]
    ; FileGetSize, sFileSize, %sFile%
    ; WriteLogDebug("Showing map " sFile " " sFileSize)
   

    If !pToken := Gdip_Startup()
    {
        MsgBox "Gdiplus failed to start. Please ensure you have gdiplus on your system"
        ExitApp
    }
    
    Gui, 3: -Caption +E0x20 +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
    hwnd1 := WinExist()
    
    pBitmap := Gdip_CreateBitmap(Width, Height)
    If !pBitmap
    {
        WriteLog("ERROR: Could not load map image " sFile)
        ExitApp
    }

    Gdip_GetRotatedDimensions(Width, Height, Angle, RWidth, RHeight)
    Gdip_GetRotatedTranslation(Width, Height, Angle, xTranslation, yTranslation)


    scaledWidth := (RWidth * scale)
    scaleAdjust := 1 ; need to adjust the scale for oversized maps
    if (scaledWidth > mapGuiWidth) {
        scaleAdjust := mapGuiWidth / (RWidth * scale)
        scaledWidth := mapGuiWidth
        WriteLog("OverSized map, reducing scale to " scale ", maxWidth set to " mapGuiWidth)
    }
    scaledHeight := (RHeight * 0.5) * scale * scaleAdjust
    rotatedWidth := RWidth * scale * scaleAdjust
    rotatedHeight := RHeight * scale * scaleAdjust
    

    hbm := CreateDIBSection(rotatedWidth, rotatedHeight)
    hdc := CreateCompatibleDC()
    obm := SelectObject(hdc, hbm)
    G := Gdip_GraphicsFromImage(pBitmap)
    
    ; ;draw player dot
    pPen := Gdip_CreatePen(0xff00FF00, 5)
    Gdip_DrawRectangle(G, pPen, xPosDot-1, yPosDot-1, 5, 5)
    ;Gdip_DrawRectangle(G, pPen, 0, 0, Width, Height) ;outline
    Gdip_DeletePen(pPen)

    ; ;draw way point line
    waypointHeader := mapData["waypoint"]
    if (waypointHeader) {
        wparray := StrSplit(waypointHeader, ",")
        waypointX := (wparray[1] * serverScale) + padding
        wayPointY := (wparray[2] * serverScale) + padding
    
        pPen := Gdip_CreatePen(0xffffFF00, 3)
        Gdip_DrawLine(G, pPen, xPosDot, yPosDot, waypointX, wayPointY) ; Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2), which have been set by using left mouse button
        
        ;Gdip_DrawRectangle(G, pPen, 0, 0, Width, Height) ;outline
        Gdip_DeletePen(pPen)
    }
    
    
    ; ;draw exit lines
    exitsHeader := mapData["exits"]
    if (exitsHeader) {

        
        Loop, parse, exitsHeader, `|
        {
            
            WriteLog(A_LoopField)
            exitArray := StrSplit(A_LoopField, ",")
            ;exitArray[1] ; name of exit
            exitX := (exitArray[2] * serverScale) + padding
            exitY := (exitArray[3] * serverScale) + padding

            ; MsgBox, Color number %A_Index% is %A_LoopField%.
            ; waypointX := (wparray[1] * serverScale) + padding
            ; wayPointY := (wparray[2] * serverScale) + padding
        
            pPen := Gdip_CreatePen(0xffFF00FF, 3)
            Gdip_DrawLine(G, pPen, xPosDot, yPosDot, exitX, exitY)
            
            ;Gdip_DrawRectangle(G, pPen, 0, 0, Width, Height) ;outline
            Gdip_DeletePen(pPen)
        }
        
    }
    
    

    G2 := Gdip_GraphicsFromHDC(hdc)
    pBitmap := Gdip_RotateBitmap(pBitmap, Angle) ; rotates bitmap for 45 degrees. Disposes of pBitmap.

    Gdip_DrawImage(G2, pBitmap, 0, 0, scaledWidth, scaledHeight, 0, 0, RWidth, RHeight, opacity)
    UpdateLayeredWindow(hwnd1, hdc, leftMargin, topMargin, rotatedWidth, rotatedHeight)
    
    ElapsedTime := A_TickCount - StartTime
    ;WriteLog("Draw players " ElapsedTime " ms taken")
    SelectObject(hdc, obm)
    DeleteObject(hbm)
    DeleteDC(hdc)
    Gdip_DeleteGraphics(G)
    Gdip_DeleteGraphics(G2)
    Gdip_DisposeImage(pBitmap)
}