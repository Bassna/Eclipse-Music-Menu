#NoEnv                            ; Disables the automatic inclusion of parent environment variables in the script.
SetWorkingDir %A_ScriptDir%       ; Sets the working directory of the script to the directory containing the script itself.
#SingleInstance Force             ; Ensures that only a single instance of the script is allowed to run at any given time.
#Persistent                       ; Keeps the script running even after the auto-execute section has finished.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global Application := "GTA5.exe" ; Change this to the game or application you want to use. GTA5.exe for Eclipse, notepad.exe is good for testing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global vMusicList := "MusicList.txt" ; Change this to the new Music text file name, if you choose a different name.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Global Variables - Interface Settings
global activeGuiName
global AddSongButton, RandomSongButton, StopSongButton, EditSongButton, DeleteSongButton, AddFavoriteButton
global compactGuiX := 0, compactGuiY := 0, compactGuiW := 0, compactGuiH := 0, xPos := 0, yPos := 0
global fullSizeGuiX := 0, fullSizeGuiY := 0, fullSizeGuiH := 0, fullSizeGuiW := 0
global listViewX := 10, listViewY := 60, listViewW := 316, listViewH := 86
global listViewMainW := 672, listViewMainH := 335
global resizeBoxX := 0, resizeBoxY := 150, ResizeBox, FullSizeGuiResizeBoxX := 0, resizeBoxMainY := 421
global GUITransparency := 255, TransparencySlider
global HandleDragOrResizeText, IsResizing := 0

; Global Variables - User Settings
global SpeakerNumberSet, tickboxState := 0, tickboxStateCompact := 0, closeOnSelectState := 0
global vMusicVolume := 100

; Global Variables - Search and URL Handling
global URL, query, SearchYT


; This section reads a TXT file and generates a menu structure and link storage based on its contents.
LoadTXTFileAndGenerateMenu:
    ; Declare global variables. These arrays will store menu structure, links, favorites, and sorting data.
    global menuArray, linkStorage, favoriteStorage, sortArray, originalArray

    ; Initialize arrays to be empty.
    menuArray := []
    linkStorage := []
    favoriteStorage := []
    sortArray := []
    originalArray := []

    ; Define the file path to the TXT file and create it if it does not exist.
    txtFilePath := vMusicList
    if (!FileExist(txtFilePath)) {
        FileAppend, , %txtFilePath%
    }

    ; Check if the file is empty before appending lines.
    fileObj := FileOpen(txtFilePath, "r") ; Open the file in read mode
    if (fileObj.Length() = 0) { ; If the file is empty
        fileObj.Close() ; Close the file in read mode
        fileObj := FileOpen(txtFilePath, "a") ; Open the file in append mode
        fileObj.WriteLine("Rick Astley, Whenever You Need Somebody, Never Gonna Give You Up, https://www.youtube.com/watch?v=dQw4w9WgXcQ, 1") ; Line 1
        fileObj.WriteLine("Lonley Island, Favorites Playlist 01, Threw It On The Ground, https://www.youtube.com/watch?v=gAYL5H46QnQ, 0") ; Line 2
        fileObj.WriteLine("Redbone, Wovoka, Come and Get Your Love, https://www.youtube.com/watch?v=bc0KhhjJP98, 0") ; Line 3
        fileObj.Close() ; Close the file in append mode
    } else {
        fileObj.Close() ; Close the file if it's not empty
    }


    ; Read the content of the TXT file and split it into lines.
    FileRead, data, %txtFilePath%
    lines := StrSplit(data, "`n", "`r")

    ; Initialize variables for corrected data and a flag to check if any corrections are needed.
    correctedData := "" 
    correctionsNeeded := false 

    ; Loop through each line, split it into fields and trim whitespaces. Correct any invalid favorites.
    for index, line in lines {
        if (line == "") {
            continue
        }

        row := StrSplit(line, ",")
        artist := Trim(row[1])
        album := Trim(row[2])
        song := Trim(row[3])
        link := Trim(row[4])
        favorite := Trim(row[5])

        if (favorite != "0" and favorite != "1") {
            favorite := "0"
            correctionsNeeded := true 
        }

        ; Reconstruct the corrected line and append it to the corrected data.
        correctedLine := artist . "," . album . "," . song . "," . link . "," . favorite
        correctedData .= correctedLine . "`n"

        ; Push the corrected line to the sort array and the original line to the original array.
        sortArray.Push(correctedLine)
        originalArray.Push(line)

        ; Generate the menu structure and store the song link.
        letter := SubStr(artist, 1, 1)
        if (!menuArray.HasKey(letter)) {
            menuArray[letter] := []
        }
        if (!menuArray[letter].HasKey(artist)) {
            menuArray[letter][artist] := []
        }
        if (!menuArray[letter][artist].HasKey(album)) {
            menuArray[letter][artist][album] := []
        }
        menuArray[letter][artist][album][song] := link

        ; Store the song link and favorite status.
        linkStorage[song] := link
        favoriteStorage[song] := favorite
    }

    ; If any corrections were made, write the corrected data back to the file.
    if (correctionsNeeded) {
        fileObj := FileOpen(txtFilePath, "w")
        fileObj.Write(correctedData)
        fileObj.Close()
    }

    ; Sort the data.
    sortedArray := sortArray.Clone()
    sortString := ""
    for index, line in sortedArray {
        sortString .= line . "`n"
    }
    Sort, sortString
    sortedArray := StrSplit(sortString, "`n", "`r")

    ; Check if the sorted data is different from the original.
    isDifferent := false
    for index, line in sortedArray {
        if (line != originalArray[index]) {
            isDifferent := true
            break
        }
    }

    ; If the sorted data is different, write it back to the file.
    if (isDifferent) {
        fileObj := FileOpen(txtFilePath, "w")
        for index, line in sortedArray {
            if (line != "") { ; Ignore empty lines
                fileObj.Write(line . "`n")
            }
        }
        fileObj.Close()
    }
return


; The F3 key is assigned to open and toggle open/closed the Music Menu GUI. THIS CAN BE CHANGED TO ANY HOTKEY YOU WANT. Simply replace F3 with the button you want.
F3:: 
    ; If the compact GUI is currently active, recreate it and store its size and position values for later use.
    if (activeGuiName = "CompactGui") {
        CompactGui() ; Recreate the compact GUI
        if (compactGuiX = 0 and compactGuiY = 0 and compactGuiW = 0 and compactGuiH = 0) {
            ; If the position and size of the compact GUI have not been set, store the current values.
            Gosub, StoreCompactGuiValues 
        }
    } else {
        ; Otherwise, open the main GUI and store its size and position values if they have not been set.
        Gosub FullSizeGui 
        if (fullSizeGuiX = 0 and fullSizeGuiY = 0 and fullSizeGuiW = 0 and fullSizeGuiH = 0) {
            ; If the position and size of the main GUI have not been set, store the current values.
            Gosub, StoreFullSizeGuiValues 
        }
    }
return


; The CTRL+F3 hotkey plays a random car song. These can also be changed to other hotkeys if required.
^F3::  
    Gosub RandomCarSong ; Go to RandomCarSong subroutine
Return


; The ALT+F3 hotkey plays a random speaker song. These can also be changed to other hotkeys if required.
!F3::  
    Gosub RandomSpeakerSong ; Go to RandomSpeakerSong subroutine
Return


; The SHIFT+F3 hotkey toggles between Full size and Compact size menus. These can also be changed to other hotkeys if required.
+F3::
    ; Check if activeGuiName is not empty
    if (activeGuiName != "") {
        tickboxStateCompact := !tickboxStateCompact
        Gosub, ToggleCompactMode
    }
return


; The F12 hotkey activates the killswitch, which stops all current actions and terminates the script. These can also be changed to other hotkeys if required.
F12::
Gosub, Killswitch ; Go to Killswitch subroutine
Return


; The StoreFullSizeGuiValues subroutine stores the current size and position of the main GUI.
StoreFullSizeGuiValues:
    Gui, FullSizeGui:Submit, NoHide ; Save the current state of the main GUI
    WinGetPos, newX, newY, newW, newH, Music Menu ; Get the current position and size of the main GUI
    fullSizeGuiX := newX ; Store the current x position
    fullSizeGuiY := newY ; Store the current y position
    fullSizeGuiW := newW ; Store the current width
    fullSizeGuiH := newH ; Store the current height
return


; The StoreCompactGuiValues subroutine stores the current size and position of the compact GUI.
StoreCompactGuiValues:
    Gui, CompactGui:Submit, NoHide ; Save the current state of the compact GUI
    WinGetPos, newX, newY, newW, newH, Compact Music Menu ; Get the current position and size of the compact GUI
    compactGuiX := newX ; Store the current x position
    compactGuiY := newY ; Store the current y position
    compactGuiW := newW ; Store the current width
    compactGuiH := newH ; Store the current height
return


; The SetActiveGuiName function sets the name of the currently active GUI for reference.
SetActiveGuiName(guiName) {
    global activeGuiName ; Declare 'activeGuiName' as a global variable to access it throughout the script
    activeGuiName := guiName ; Assign the name of the currently active GUI to the variable
}


; The IsScriptGuiActive function determines if the active GUI window is part of the current script process and thread.
IsScriptGuiActive() {
    hWnd := WinActive("A") ; Get the handle of the active window
    WinGet, pid, PID, % "ahk_id " hWnd ; Get the process ID of the active window
    ; Compare the thread ID of the active window and the current thread, and compare the process ID with the current process ID
    ; Return true if both conditions are met, indicating that the active GUI is from the script
    return DllCall("GetWindowThreadProcessId", "Ptr", hWnd, "UInt*", 0) = DllCall("GetCurrentThreadId") && pid = DllCall("GetCurrentProcessId")
}


; The following hotkey is for closing an active GUI window related to the current script process and thread.
#If IsScriptGuiActive()
    Esc:: ; Escape key
    F3:: ; F3 key
        WinGet, activeGuiHwnd, ID, A ; Get the handle of the active window
        ; Send the close window message to the window
        SendMessage, 0x112, 0xF060,,, % "ahk_id " activeGuiHwnd ; WM_SYSCOMMAND := 0x112, SC_CLOSE := 0xF060
    return
#If


; Main GUI for the Full Size Music Menu
FullSizeGui:
    ; Setup of the FullSize GUI: AlwaysOnTop attribute is determined by the state of closeOnSelectState
    ; If closeOnSelectState is not equal to zero, the GUI will stay on top of all other windows
    if (closeOnSelectState != 0) {
        Gui, FullSizeGui:New, +OwnDialogs -Caption +AlwaysOnTop
    } else {
        Gui, FullSizeGui:New, +OwnDialogs -Caption
    }
    
    ; Create a new GUI with options for custom dialog handling
    Gui, FullSizeGui:Font, s9, Segoe UI Semibold
    Gui, FullSizeGui:Color, C0C0C0

    ; Set the WM_EXITSIZEMOVE Windows messages to trigger specific subroutines
    OnMessage(0x0232, "WM_EXITSIZEMOVE")      ; End of drag/resize event
    OnMessage(0x84, "WM_NCHITTEST") ; Makes the GUI draggable
    OnMessage(0x200, "WM_MOUSEMOVE") ; Handle mouse move events
    OnMessage(0x20, "WM_SETCURSOR") ; Makes the cursor change to resize when hovering over the resize bar

    ; Add a custom title bar and close button
    Gui, Add, Text, x0 y3 w692 h30 vTitleBar cGray +Center, Music Menu
    Gui, Add, Button, x652 y5 w35 h15 gGuiClose , X ; Close button
    
    ; Add buttons for song management: Add, Delete, Random, Edit, and Stop
    Gui, Add, Button, x10 y20 w60 h20 gSongAdd, Add Song
    Gui, Add, Button, x75 y20 w80 h20 gDeleteSelectedSong, Delete Song
    Gui, Add, Button, x75 y50 w82 h20 gRandomSong, Random Song
    Gui, Add, Button, x10 y50 w60 h20 gEditSong, Edit Song
    Gui, FullSizeGui:Font, s14, Segoe UI Semibold
    Gui, Add, Button, x160 y20 w20 h20 gAddFavorite vAddFavoriteButton, ★
    Gui, FullSizeGui:Font, s9, Segoe UI Semibold
    Gui, Add, Button, x160 y50 w40 h20 gStopSong, Stop

    ; Add a checkbox to control visibility of the speaker number input box and label
    Gui, Add, CheckBox, x210 y56 vCheckboxVar gShowHideInput Checked%tickboxState%, Speaker

    ; Add the input box with system default font
    Gui, FullSizeGui:Font, s8, Microsoft Sans Serif
    Gui, Add, Edit, x276 y52 w30 h20 vAdditionalInput +WantReturn, %SpeakerNumberSet%
    Gui, FullSizeGui:Font, s9, Segoe UI Semibold

    ; Add sliders to control music volume and GUI transparency
    Gui, Add, Slider, x588 y26 w100 h20 ToolTip Thick19 vMusicVolume Range0-100 gSetMusicVolumeDelayed
    GuiControl, , MusicVolume, %vMusicVolume%
    Gui, Add, Slider, x588 y52 w100 h20 Thick19 vTransparencySlider Range50-255 gAdjustTransparency Invert
    GuiControl, , TransparencySlider, %GUITransparency%

    ; Add checkboxes to toggle Compact Mode and to control whether the GUI should stay open
    Gui, Add, CheckBox, x410 y56 vCheckboxVar2 gToggleCompactMode Checked%tickboxStateCompact%, Compact Mode
    Gui, Add, CheckBox, x328 y56 vCloseOnSelectVar gToggleCloseOnSelect Checked%closeOnSelectState%, Keep Open

    ; Add labels for sliders, controls and a text prompt for song search
    Gui, Add, Text, x542 y30, Volume:
    Gui, Add, Text, x522 y56, Transparent:
    Gui, Add, Text, x196 y22, Enter song, artist, or album:

    ; Add hidden OK button, ListView to display songs, and a text box for song search
    Gui, Add, Button, Hidden Default gButtonOK, OK

    ; ListView: This is a list of songs displayed in the GUI. It includes several columns for details such as Artist, Album, Song, Link, Favorite and Fav. 
    Gui, Add, ListView, x10 y80 w%listViewMainW% h%listViewMainH% gSelectSongFromListView vMusicList BackgroundE0FFFC, Artist|Album|Song|Link|Favorite|Fav
    LV_ModifyCol(1, 152) ; Sets the width of the 'Artist' column
    LV_ModifyCol(2, 152) ; Sets the width of the 'Album' column
    LV_ModifyCol(3, 192) ; Sets the width of the 'Song' column
    LV_ModifyCol(4, 125) ; Sets the width of the 'Link' column
    LV_ModifyCol(5, 0)  ; Sets the width of the 'Favorite' column, set to 0 for hidden
    LV_ModifyCol(6, 30) ; Sets the width of the 'Fav' column

    ; Query: This text box allows the user to search for songs, artists, or albums. 
    Gui, Add, Edit, x350 y20 w172 h20 vQuery gSearchAll +WantReturn

    ; Custom progress bar to grab and drag at the bottom of the GUI to resize
    Gui, Add, Progress, x%resizeBoxX% y%resizeBoxMainY% w692 h4 Background000000 Disabled vResizeBox,
    Gui, Add, Text, xp yp wp hp BackgroundTrans 0x201 vHandleDragOrResizeText gHandleDragOrResizeFullSizeGui,

    ; Conditionally show or hide the speaker number input box and label based on tickboxState
    if (!tickboxState) {
        GuiControl, Hide, AdditionalInput
    }

    ; Set the ListView to be resizable
    GuiControl, +Resize, MusicList

    ; Add an outline around the GUI
    DRAW_OUTLINEFullSizeGui("FullSizeGui", 0, 0, 692, 425)

    ; Set the active GUI for other functions to use
    SetActiveGuiName("FullSizeGui")

    ; Update the always-on-top state of the GUI
    Gosub, UpdateAlwaysOnTopState

    ; Determine if GUI needs to be shown in a new location or at a previously set one
    if (fullSizeGuiX = 0 and fullSizeGuiY = 0) {
        SetGuiTransparency("FullSizeGui", GUITransparency)
        Gui, Show, w692 h425, Music Menu
        Gosub, StoreFullSizeGuiValues

    } else {
        ; Use stored width and height if available, default to 692 and 425 otherwise
        fullSizeGuiW := (fullSizeGuiW = 0) ? 692 : fullSizeGuiW
        fullSizeGuiH := (fullSizeGuiH = 0) ? 425 : fullSizeGuiH
        SetGuiTransparency("FullSizeGui", GUITransparency)
        Gui, Show, x%fullSizeGuiX% y%fullSizeGuiY% w%fullSizeGuiW% h%fullSizeGuiH%, Music Menu
    }

    ; Set the initial transparency for the main GUI
    SetGuiTransparency("FullSizeGui", GUITransparency)

    ; Perform an initial search to populate the ListView
    Gosub, SearchAll

    ; Sets the curser on the search bar by default
    GuiControl, Focus, Query
return


; This function handles the "AddFavorite" command, which is triggered when the user wants to mark a song as favorite or remove it from favorites.
AddFavorite:
    global activeGuiName

    ; Get the details of the currently selected row in the ListView, including the artist, album, song, link, and whether the song is marked as a favorite.
    SelectedRow := LV_GetNext(0, "Focused") 
    LV_GetText(SelectedArtist, SelectedRow, 1) ; Fetches the current artist status of the song
    LV_GetText(SelectedAlbum, SelectedRow, 2) ; Fetches the current album status of the song
    LV_GetText(SelectedSong, SelectedRow, 3) ; Fetches the current song name status of the song
    LV_GetText(SelectedLink, SelectedRow, 4) ; Fetches the current url link status of the song
    LV_GetText(SelectedFav, SelectedRow, 5) ; Fetches the current favorite status of the song

    ; Toggle the favorite status of the selected song. If the song is already a favorite (favorite value is "1"), change it to "0". Otherwise, change it to "1".
    if (SelectedFav = "1") {
        ModifiedFav := "0"
    } else {
        ModifiedFav := "1"
    }

    ; Update the favorite status of the song in the TXT file where the song details are stored.
    ReplaceSongInTXT(SelectedArtist, SelectedAlbum, SelectedSong, SelectedLink, SelectedFav, SelectedArtist, SelectedAlbum, SelectedSong, SelectedLink, ModifiedFav)

return


; This function handles the recreation of the GUI, allowing changes to be reflected immediately in the interface.
RecreateGUI:
    ; The existing AddSong and Search GUIs are destroyed to make room for the new GUI.
    Gui, AddSongGui:Destroy
    Gui, FullSizeGui:Destroy

    ; Depending on the state of the 'tickboxStateCompact', the GUI is recreated in either Compact or Main (full) mode.
    if (tickboxStateCompact) {
        if (WinExist("Compact Music Menu")) {
            CompactGui()
        }
    } else {
        Gosub, FullSizeGui
    }
return


; This function responds to the WM_EXITSIZEMOVE message, which is sent by the operating system when the user stops moving or resizing a window.
WM_EXITSIZEMOVE(wParam, lParam, msg, hwnd) {
    ; If the window being moved or resized is the Music Menu...
    if (hwnd = WinExist("Music Menu")) { 
        ; Get the new position of the window and update the stored position.
        WinGetPos, newX, newY,,, A 
        fullSizeGuiX := newX 
        fullSizeGuiY := newY

        ; Update the transparency of the GUI to maintain its current level.
        SetGuiTransparency("FullSizeGui", GUITransparency)

        ; Get the new size of the window and update the stored size.
        WinGetPos, , , newW, newH, A
        fullSizeGuiW := newW
        fullSizeGuiH := newH

        ; Calculate the new dimensions for the ListView and ResizeBox button based on the new size of the window.
        listViewMainW := newW - 20
        listViewMainH := newH - 90
        resizeBoxMainY := newH - 4

        ; Update the size and position of the ListView and ResizeBox button based on the new dimensions.
        GuiControl, Move, MusicList, w%listViewMainW% h%listViewMainH%
        GuiControl, Move, ResizeBox, y%resizeBoxMainY%
        GuiControl, Move, HandleDragOrResizeText, y%resizeBoxMainY%

    ; If the window being moved or resized is the Compact Music Menu...
    } else if (hwnd = WinExist("Compact Music Menu")) { 
        ; Get the new position and size of the window and update the stored position and size.
        WinGetPos, newX, newY, newW, newH, A
        compactGuiX := newX
        compactGuiY := newY
        compactGuiW := newW
        compactGuiH := newH

        ; Calculate the new dimensions for the ListView and ResizeBox button based on the new size of the window.
        listViewW := newW - 20
        listViewH := newH - 68
        resizeBoxY := newH - 4

        ; Update the size and position of the ListView and ResizeBox button based on the new dimensions.
        GuiControl, Move, MusicList, w%listViewW% h%listViewH%
        GuiControl, Move, ResizeBox, y%resizeBoxY%
        GuiControl, Move, HandleDragOrResizeText, y%resizeBoxY%
    }
}


; This function alters the 'closeOnSelectState' variable. The closeOnSelectState dictates whether the GUI will close after a song has been selected.
ToggleCloseOnSelect:
    closeOnSelectState := !closeOnSelectState ; Flip the state of 'closeOnSelectState'
    Gosub, UpdateAlwaysOnTopState ; Update the 'Always On Top' state according to the new 'closeOnSelectState'
return


; This function switches the GUI between full size and compact modes.
ToggleCompactMode:
    GuiControlGet, tickboxStateCompact, , CheckboxVar2 ; Fetch the current state of the compact mode toggle

    ; If compact mode is currently enabled
    if (tickboxStateCompact) {
        ; Record the current position of the main GUI before closing it
        if IsScriptGuiActive() ; Check if the active GUI is part of this script
        {
            WinGetPos, FullSizeGuiX, FullSizeGuiY,,, A
            fullSizeGuiX := FullSizeGuiX
            fullSizeGuiY := FullSizeGuiY
        }

        Gui, FullSizeGui:Destroy ; Destroy the current main GUI

        CompactGui() ; Create the compact GUI
    } 
    else {
        ; If compact mode is currently disabled
        ; Record the current position of the compact GUI before closing it
        if IsScriptGuiActive() ; Check if the active GUI is part of this script
        {
            WinGetPos, CompactGuiX, CompactGuiY,,, A
            compactGuiX := CompactGuiX
            compactGuiY := CompactGuiY
        }

        ; Destroy the current compact GUI
        Gui, CompactGui:Destroy 

        ; Open the main GUI
        Gosub, FullSizeGui 

        ; Reset the 'tickboxStateCompact' variable when transitioning from CompactGUI to FullSizeGui
        tickboxStateCompact := 0
    }
return


; Main GUI for the Compact Music Menu
CompactGui() {
    ; Setup of the Compact GUI: AlwaysOnTop attribute is determined by the state of closeOnSelectState
    ; If closeOnSelectState is not equal to zero, the GUI will stay on top of all other windows
    if (closeOnSelectState != 0) {
        Gui, CompactGui:New, +OwnDialogs -Caption +AlwaysOnTop
    } else {
        Gui, CompactGui:New, +OwnDialogs -Caption
    }

    ; Set the font and color of the CompactGui
    Gui, CompactGui:Font, s9, Segoe UI Semibold
    Gui, CompactGui:Color, C0C0C0

    ; Intercept Windows messages to control GUI behavior
    OnMessage(0x84, "WM_NCHITTEST") ; Allows the GUI to be draggable by the user
    OnMessage(0x0232, "WM_EXITSIZEMOVE") ; Updates compactGuiX and compactGuiY values as the GUI is moved
    OnMessage(0x20, "WM_SETCURSOR") ; Changes the cursor when it hovers over the GUI
    OnMessage(0x200, "WM_MOUSEMOVE") ; Handles mouse movement events within the GUI

    ; Add a query input field to search for songs
    Gui, Add, Edit, x8 y8 w100 h20 vQuery gSearchAllCompact +WantReturn

    ; Add a ListView control to display songs
    ; Information includes Artist, Album, Song, Link, Favorite status
    Gui, Add, ListView, x%listViewX% y%listViewY% w%listViewW% h%listViewH% gSelectSongFromListView vMusicList BackgroundE0FFFC, Artist|Album|Song|Link|Favorite|Fav
    LV_ModifyCol(1, 70) ; Set the width of the Artist column
    LV_ModifyCol(2, 70) ; Set the width of the Album column
    LV_ModifyCol(3, 124) ; Set the width of the Song column
    LV_ModifyCol(4, 0) ; Hide the Link column (it's for internal use and not needed for display)
    LV_ModifyCol(5, 0) ; Set the width of the Favorite status column
    LV_ModifyCol(6, 30) ; Set the width of the Favorite status column

    ; Add Compact Mode and "Always On Top" toggles
    Gui, Add, CheckBox, x260 y42 vCheckboxVar2 gToggleCompactMode Checked%tickboxStateCompact%, Compact
    Gui, Add, CheckBox, x112 y42 vCheckboxVar gShowHideInput Checked%tickboxState%, Speaker

    ; Add an additional input box (with its font and label)
    Gui, CompactGui:Font, s8, Microsoft Sans Serif
    Gui, Add, Edit, x142 y8 w30 h20 vAdditionalInput +WantReturn, %SpeakerNumberSet%
    Gui, CompactGui:Font, s8, Segoe UI Semibold

    ; Add a checkbox for keeping the GUI open after a song is selected
    Gui, Add, CheckBox, x178 y42 vCloseOnSelectVar gToggleCloseOnSelect Checked%closeOnSelectState%, Keep Open

    ; Conditionally show or hide the input box and label based on tickboxState
    if (!tickboxState) {
        GuiControl, Hide, SpeakerLabel
        GuiControl, Hide, AdditionalInput
    }

    ; Add volume and transparency sliders
    Gui, Add, Text, x202 y6, Volume:
    Gui, Add, Slider, x246 y3 w80 w80 h18 Tooltip Thick18 vMusicVolume Range0-100 gSetMusicVolumeDelayed
    GuiControl, , MusicVolume, %vMusicVolume%
    Gui, Add, Slider, x246 y20 w80 h18 vTransparencySlider Range50-255 gAdjustTransparency Thick18 +gShowCustomTooltip Invert
    GuiControl, , TransparencySlider, %GUITransparency%
    Gui, Add, Text, x180 y22, Transparent :

    ; Add controls for song manipulation and GUI resize
    Gui, Add, Progress, x%resizeBoxX% y%resizeBoxY% w360 h4 Background000000 Disabled vResizeBox,
    Gui, Add, Text, xp yp wp hp BackgroundTrans 0x201 vHandleDragOrResizeText gHandleDragOrResize,

    ; Add a stop song button
    Gui, Add, GroupBox, x50 y38 w18 h18 Border c000000, ; This is the border around the progress bar
    Gui, Add, Text, x51 y39 w16 h16 0x201 gStopSong vStopSongButton, 
    Gui, Add, Progress, x51 y39 w16 h16 Disabled cFF0000, 100 ; This is the red progress bar

    ; Add the GUI border
    DRAW_OUTLINE("CompactGui", 0, 0, 335, 153)

    ; Add button controls for various song actions such as random play, add song, edit song, delete song, and add to favorites
    Gui, CompactGui:Font, Bold s11, Microsoft Sans Serif 
    Gui, Add, GroupBox, x30 y38 w18 h18 Border c000000, ; This is the border around the progress bar
    Gui, Add, Button, x31 y39 w16 h16 gRandomSong vRandomSongButton, R
    Gui, Add, GroupBox, x10 y38 w18 h18 Border c000000, ; This is the border around the progress bar
    Gui, Add, Button, x11 y39 w16 h16 gSongAdd vAddSongButton, A
    Gui, Add, GroupBox, x70 y38 w18 h18 Border c000000, ; This is the border around the progress bar
    Gui, Add, Button, x71 y39 w16 h16 gEditSong VEditSongButton, E
    Gui, Add, GroupBox, x90 y38 w18 h18 Border c000000, ; This is the border around the progress bar
    Gui, Add, Button, x91 y39 w16 h16 gDeleteSelectedSong vDeleteSongButton, D
    Gui, Add, GroupBox, x115 y9 w18 h18 Border c000000, ; This is the border around the progress bar
    Gui, CompactGui:Font, s18, Times New Roman ; Reset the font to Times New Roman, size 18
    Gui, Add, Button, x116 y10 w16 h16 gAddFavorite vAddFavoriteButton, ★
    Gui, CompactGui:Font, s8, Segoe UI Semibold ; Reset the font to Segoe UI Semibold, size 8


    ; Set the initial transparency for the compact GUI
    SetGuiTransparency("CompactGui", GUITransparency)

    ; Set the active GUI to CompactGui and update the AlwaysOnTop state
    SetActiveGuiName("CompactGui")
    Gosub, UpdateAlwaysOnTopState

    ; Initialize the search in compact mode
    Gosub, SearchAllCompact

    ; Displaying the compact GUI
    ; Checks if the position values for the compact GUI (X and Y coordinates) are set to 0
    if (compactGuiX = 0 and compactGuiY = 0) {
        ; If the position values are not set, it shows the GUI at default position and size, and stores the GUI values
        Gui, Show, w335 h153, Compact Music Menu
        Gosub, StoreCompactGuiValues
    } else {
        ; If the position values are set, it checks if the width and height values for the GUI are set
        compactGuiW := (compactGuiW = 0) ? 335 : compactGuiW
        compactGuiH := (compactGuiH = 0) ? 153 : compactGuiH
        ; If the width and height values are not set, it uses the default width and height values (335 and 153 respectively)
        ; And displays the GUI at the specified position and size
        Gui, Show, x%compactGuiX% y%compactGuiY% w%compactGuiW% h%compactGuiH%, Compact Music Menu
    }

    ; Set the transparency for the compact GUI again after it has been shown
    SetGuiTransparency("CompactGui", GUITransparency)

    ; Sets the curser on the search bar by default
    GuiControl, Focus, Query
}


; This function creates an outline around a GUI.
DRAW_OUTLINE(GUI_NAME, X, Y, W, H, COLOR1:="BLACK", COLOR2:="BLACK", THICKNESS:=3) {
    ; Adding a horizontal progress bar at the top of the GUI for the outline.
    Gui, % GUI_NAME ": ADD", Progress, % "X" X " Y" Y " W" W " H" THICKNESS " BACKGROUND" COLOR1 

    ; Adding a vertical progress bar on the left side of the GUI for the outline.
    Gui, % GUI_NAME ": ADD", Progress, % "X" X " Y" Y " W" THICKNESS " H" H + 10000 " BACKGROUND" COLOR1 

    ; The bottom border of the GUI is currently disabled for dynamic adjustment.
    ; Gui , % GUI_NAME ": ADD" , Progress , % "X" X " Y" Y + H - THICKNESS " W" W " H" THICKNESS " BACKGROUND" COLOR2 

    ; Adding a vertical progress bar on the right side of the GUI for the outline.
    Gui, % GUI_NAME ": ADD", Progress, % "X" X + W - THICKNESS " Y" Y " W" THICKNESS " H" H + 10000 " BACKGROUND" COLOR2     
}


; This function creates an outline around a 'main' GUI.
DRAW_OUTLINEFullSizeGui(GUI_NAME, X, Y, W, H, COLOR1:="BLACK", COLOR2:="BLACK", THICKNESS:=3) {
    ; Adding a horizontal progress bar at the top of the main GUI for the outline.
    Gui, % GUI_NAME ": ADD", Progress, % "X" X " Y" Y " W" W " H" THICKNESS " BACKGROUND" COLOR1 

    ; Adding a vertical progress bar on the left side of the main GUI for the outline.
    Gui, % GUI_NAME ": ADD", Progress, % "X" X " Y" Y " W" THICKNESS " H" H + 10000 " BACKGROUND" COLOR1 

    ; The bottom border of the main GUI is currently disabled for dynamic adjustment.
    ; Gui , % GUI_NAME ": ADD" , Progress , % "X" X " Y" Y + H - THICKNESS " W" W " H" THICKNESS " BACKGROUND" COLOR2 

    ; Adding a vertical progress bar on the right side of the main GUI for the outline.
    Gui, % GUI_NAME ": ADD", Progress, % "X" X + W - THICKNESS " Y" Y " W" THICKNESS " H" H + 10000 " BACKGROUND" COLOR2     
}


; Function for mouse tooltips
WM_MOUSEMOVE() {
    static CurrControl, PrevControl
    CurrControl := A_GuiControl

    ; If the control under the mouse cursor has changed
    if (CurrControl <> PrevControl and not InStr(CurrControl, " ")) {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 500
        PrevControl := CurrControl
    }
    return

    ; Display the tooltip handle
    DisplayToolTip:
    ; Turn off timer for tooltip display
    SetTimer, DisplayToolTip, Off
    ; Declare the global variable activeGuiName
    global activeGuiName

    ; Display a tooltip based on the control under the mouse cursor
    if (CurrControl = "AddSongButton") {
        ToolTip, Add Song
    } else if (CurrControl = "RandomSongButton") {
        ToolTip, Random Song
    } else if (CurrControl = "StopSongButton") {
        ToolTip, Stop Song
    } else if (CurrControl = "EditSongButton") {
        ToolTip, Edit Song
    } else if (CurrControl = "DeleteSongButton") {
        ToolTip, Delete Song
    } else if (CurrControl = "AddFavoriteButton") {
        ToolTip, Favorite Song
    } else if (CurrControl = "AdditionalInput" ) { 
        ToolTip, Speaker Number
    }
    
    ; Remove the tooltip after 6 seconds
    SetTimer, RemoveToolTipCompact, 6000
    return

    ; Remove the Tooltip handle
    RemoveToolTipCompact:
    ; Turn off timer for tooltip removal
    SetTimer, RemoveToolTipCompact, Off
    ; Remove the tooltip by calling the ToolTip function without any text
    ToolTip
    return
}


; Function to handle window resizing and dragging in compact mode
WM_NCHITTEST(wParam, lParam, msg, hwnd) {
    if (IsResizing) {
        return HTBOTTOM
    }
    ; Set the cursor to the default (HTCAPTION = 2) to indicate the GUI should be draggable
    return 2
    if (A_Gui = "CompactGui") {
        ; Get the mouse cursor position in the client area of the window
        CoordMode, Mouse, Client
        MouseGetPos, mouseX, mouseY

        ; Define the boundaries of the resize button
        resizeButtonX1 := resizeBoxX
        resizeButtonY1 := resizeBoxY
        resizeButtonX2 := resizeBoxX + 360
        resizeButtonY2 := resizeBoxY + 10

    }
    return 0
}


; Process the WM_SETCURSOR message to change the cursor when hovering over the resize button in CompactGUI and FullSizeGui
WM_SETCURSOR(wParam, lParam, msg, hwnd) {
    if (A_Gui = "CompactGui" || A_Gui = "FullSizeGui") {
        ; Get the current position of the mouse cursor relative to the client area of the window
        CoordMode, Mouse, Client
        MouseGetPos, mouseX, mouseY

        ; Define the boundaries of the resize button for the CompactGUI
        if (A_Gui = "CompactGui") {
            resizeButtonX1 := resizeBoxX
            resizeButtonY1 := resizeBoxY
            resizeButtonX2 := resizeBoxX + 360
            resizeButtonY2 := resizeBoxY + 10
        }
        
        ; Define the boundaries of the resize button for the FullSizeGui
        else if (A_Gui = "FullSizeGui") {
            resizeButtonX1 := resizeBoxX
            resizeButtonY1 := resizeBoxMainY
            resizeButtonX2 := resizeBoxX + 692
            resizeButtonY2 := resizeBoxMainY + 4
        }
        
        ; Check if the cursor is currently over the resize button
        if (mouseX >= resizeButtonX1 && mouseX <= resizeButtonX2 && mouseY >= resizeButtonY1 && mouseY <= resizeButtonY2) {
            ; Load the vertical resize cursor and set the cursor to it
            cursorResize := DllCall("LoadCursor", "Ptr", 0, "Int", 32645, "Ptr") ; 32645 is the ID of the vertical resize cursor
            DllCall("SetCursor", "Ptr", cursorResize)
            return 1 ; Prevent the system from setting the cursor
        } else {
            ; Load the default cursor and set the cursor to it
            cursorNormal := DllCall("LoadCursor", "Ptr", 0, "Int", 32512, "Ptr") ; 32512 is the ID of the default cursor
            DllCall("SetCursor", "Ptr", cursorNormal)
            return 1 ; Prevent the system from setting the cursor
        }
    }
    return 0 ; Allow the system to set the cursor
}


; Function to start resizing the compact menu
StartResize() {
    ; Declare global variables
    global hwnd, IsResizing, compactGuiX, compactGuiY, compactGuiH, compactGuiW, listViewW, listViewH, resizeBoxY
    ; Get the current position of the mouse and the ID of the window under the cursor
    MouseGetPos, startX, startY, hwnd
    ; Get the current position and size of the window
    WinGetPos, guiX, guiY, guiW, guiH, ahk_id %hwnd%

    ; Define minimum and maximum height constraints
    minHeight := 155 ; Adjust the value as needed
    maxHeight := 6000 ; Adjust the value as needed

    ; Continue resizing as long as the left mouse button is held down
    while (GetKeyState("LButton", "P")) {
        Sleep 10
        ; Get the current position of the mouse
        MouseGetPos, endX, endY
        ; Calculate the new height of the window
        newHeight := guiH + (endY - startY)

        ; Ensure the new height is within the defined constraints
        newHeight := (newHeight < minHeight) ? minHeight : (newHeight > maxHeight) ? maxHeight : newHeight

        ; Resize the GUI
        Gui, CompactGui:Show, h%newHeight%

        ; Move the black box along with the resizing
        newY := newHeight - 4
        GuiControl, Move, ResizeBox, y%newY%

        ; Move the transparent text control along with the black box
        GuiControl, Move, HandleDragOrResizeText, y%newY%

        ; Resize the ListView
        newListViewHeight := newHeight - 68
        GuiControl, Move, MusicList, h%newListViewHeight%
    }

    ; Update global variables with the new size and position of the GUI and its controls
    compactGuiH := newHeight
    compactGuiW := guiW
    listViewH := newListViewHeight
    resizeBoxY := newY

    ; Indicate that resizing is over
    IsResizing := 0
}


; Function to handle dragging or resizing the compact menu
HandleDragOrResize() {
    global IsResizing, compactGuiX, compactGuiY
    ; Toggle the resizing state
    IsResizing := !IsResizing
    if (IsResizing) {
        ; If we just started resizing, call the StartResize function
        StartResize()
    }
}


; Function to start resizing the main GUI
StartResizeFullSizeGui() {
    ; Declare global variables
    global hwnd, IsResizing, fullSizeGuiX, fullSizeGuiY, fullSizeGuiH, fullSizeGuiW, listViewMainW, listViewMainH, resizeBoxMainY
    ; Get the current position of the mouse and the ID of the window under the cursor
    MouseGetPos, startX, startY, hwnd
    ; Get the current position and size of the window
    WinGetPos, guiX, guiY, guiW, guiH, ahk_id %hwnd%

    ; Define minimum and maximum height constraints
    minHeight := 180 ; Adjust the value as needed for minimum GUI
    maxHeight := 6000 ; Adjust the value as needed for maximum GUI

    ; Continue resizing as long as the left mouse button is held down
    while (GetKeyState("LButton", "P")) {
        Sleep 10
        ; Get the current position of the mouse
        MouseGetPos, endX, endY
        ; Calculate the new height of the window
        newHeight := guiH + (endY - startY)

        ; Ensure the new height is within the defined constraints
        newHeight := (newHeight < minHeight) ? minHeight : (newHeight > maxHeight) ? maxHeight : newHeight

        ; Resize the GUI
        Gui, FullSizeGui:Show, h%newHeight%

        ; Move the black box along with the resizing
        newY := newHeight - 4
        GuiControl, Move, ResizeBox, y%newY%

        ; Move the transparent text control along with the black box
        GuiControl, Move, HandleDragOrResizeText, y%newY%

        ; Resize the ListView
        newListViewHeight := newHeight - 90
        GuiControl, Move, MusicList, h%newListViewHeight%
    }

    ; Update global variables with the new size and position of the GUI and its controls
    fullSizeGuiH := newHeight
    fullSizeGuiW := guiW
    listViewMainH := newListViewHeight
    resizeBoxMainY := newY

    ; Indicate that resizing is over
    IsResizing := 0
}


; Function to handle dragging or resizing the main GUI
HandleDragOrResizeFullSizeGui() {
    global IsResizing, fullSizeGuiX, fullSizeGuiY
    ; Toggle the resizing state
    IsResizing := !IsResizing
    if (IsResizing) {
        ; If we just started resizing, call the StartResizeFullSizeGui function
        StartResizeFullSizeGui()
    }
}


; Search function for the compact GUI
SearchAllCompact:
Gui, CompactGui:Submit, NoHide
; Disable redrawing of the MusicList control to improve performance
GuiControl, -Redraw, MusicList
; Clear the ListView
LV_Delete()

; Read the vMusicList file into a variable
FileRead, data, %vMusicList%
; Split the data into lines
lines := StrSplit(data, "`n", "`r")

for index, line in lines {
    ; Skip empty lines
    if (Trim(line) == "")
        continue

    ; Split each line into fields using comma as a delimiter
    fields := StrSplit(line, ",")
    favDisplay := fields[5] != "0" ? "*" : ""  ; Add this line

    ; Add the line to the ListView if it matches the search query
    if (Query == "" or InStr(fields[1], Query) or InStr(fields[2], Query) or InStr(fields[3], Query))
        LV_Add("", fields[1], fields[2], fields[3], fields[4], fields[5], favDisplay)  ; Modify this line
}

; Sort the ListView by the "favorite" column
LV_ModifyCol(5, "SortDesc")  ; Use "Sort" for ascending order, "SortDesc" for descending order


; Enable redrawing of the MusicList control
GuiControl, +Redraw, MusicList
return


; Label to adjust the transparency and update the global variable
AdjustTransparency:
    ; Get the current position of the TransparencySlider
    GuiControlGet, GUITransparency, , TransparencySlider
    
    ; Calculate the transparency percentage
    transparencyPercent := Round((255 - GUITransparency) / 2.05)
    
    ; Define the tooltip text
    tooltipText := transparencyPercent . "%"
    
    ; Show the tooltip near the cursor position
    ToolTip, %tooltipText%, A_CaretX + 20, A_CaretY
    
    ; Set a timer to remove the tooltip after 1 second
    SetTimer, RemoveToolTip, -1000
    
    ; Set the transparency of the two GUIs
    WinSet, Transparent, %GUITransparency%, Compact Music Menu
    WinSet, Transparent, %GUITransparency%, Music Menu
return


; Function to set the transparency of a GUI
SetGuiTransparency(GuiName, Transparency) {
    ; Get the window handle of the GUI
    Gui, %GuiName%: +LastFound
    hWnd := WinExist()

    ; Define the constants for the window style and layered attribute
    WS_EX_LAYERED := 0x80000
    LWA_ALPHA := 0x2

    ; Get the current window style
    WinGet, ExStyle, ExStyle, ahk_id %hWnd%

    ; Add the WS_EX_LAYERED style to the existing window styles
    ExStyle := ExStyle | WS_EX_LAYERED
    DllCall("SetWindowLong", "Ptr", hWnd, "Int", -20, "Int", ExStyle)

    ; Set the transparency of the window
    DllCall("SetLayeredWindowAttributes", "Ptr", hWnd, "UInt", 0, "UInt", Transparency, "UInt", LWA_ALPHA)
}


; Label to show the custom tooltip based on the slider value and adjust transparency
ShowCustomTooltip:
    ; Get the current position of the TransparencySlider
    GuiControlGet, currentTransparency, , TransparencySlider
    
    ; Calculate the transparency percentage
    transparencyPercent := Round(((255 - currentTransparency) / 205) * 100)
    
    ; Define the tooltip text
    tooltipText := transparencyPercent . "%"
    
    ; Get the current position of the mouse cursor
    MouseGetPos, mouseX, mouseY
    
    ; Show the tooltip near the cursor position
    ToolTip, %tooltipText%, mouseX + 15, mouseY - 20
    
    ; Set a timer to remove the tooltip after 2 seconds
    SetTimer, RemoveToolTip, 2000

    ; Call the label to adjust transparency
    Gosub, AdjustTransparency
return


; Removes the ToolTip
RemoveToolTip:
    ; Hide the tooltip
    ToolTip
return


; This subroutine updates the vMusicVolume variable based on the slider's value
SetMusicVolume:
    ; Update the GUI controls
    Gui, Submit, NoHide
    
    ; Get the current position of the MusicVolume slider
    GuiControlGet, vMusicVolume, , MusicVolume
    
    ; Show a tooltip with the current volume
    ToolTip, Volume: %vMusicVolume%
return


; Sets a delay for the automatic sending of the volume bar adjustment
SetMusicVolumeDelayed:
    ; Update the GUI controls
    Gui, Submit, NoHide
    
    ; Get the current position of the MusicVolume slider
    GuiControlGet, vMusicVolume, , MusicVolume
    
    ; Set a timer to call the SetVolume subroutine after 15 milliseconds
    SetTimer, SetVolume, -15
return


; Sets the volume from the bar
SetVolume:
    ; Update the GUI controls
    Gui, Submit, NoHide
    
    ; Activate the window of the specified application
    WinActivate, ahk_exe %Application%
    
    ; Send the volume adjustment command to the application with a delay
    SendWithDelay("/vol speaker " . vMusicVolume)
return


; Add a new label to show or hide the input box and label based on the checkbox state
ShowHideInput:
    ; Update the GUI controls
    Gui, Submit, NoHide
    
    ; Get the state of the checkbox
    tickboxState := CheckboxVar
    
    ; Show or hide the input box and label based on the checkbox state
    if (CheckboxVar) {
        GuiControl, Show, AdditionalInput
        GuiControl, Show, SpeakerLabel
        GuiControl, Focus, AdditionalInput ; set the focus to the speaker input box
    } else {
        GuiControl, Hide, AdditionalInput
        GuiControl, Hide, SpeakerLabel
    }
return


; Detect Enter key press in ListView and call SelectSongFromListView function
ButtonOK:
    ; Get the control that currently has keyboard focus
    GuiControlGet, FocusedControl, FocusV
    
    ; If the control with focus is not the MusicList, exit the subroutine
    if (FocusedControl != "MusicList")
        return
    
    ; Call the SelectSongFromListView function and pass "Enter" as an argument
    SelectSongFromListView("Enter")
return


; Updates the ListView with search results based on the user's query.
SearchAll:
    Gui, Submit, NoHide
    GuiControl, -Redraw, MusicList
    LV_Delete()

    ; Read the vMusicList file into a variable
    FileRead, data, %vMusicList%
    ; Split the data into lines
    lines := StrSplit(data, "`n", "`r")

    for index, line in lines {
        ; Skip empty lines
        if (Trim(line) == "")
            continue
    
        ; Split each line into fields using comma as a delimiter
        fields := StrSplit(line, ",")
        favDisplay := fields[5] != "0" ? "*" : ""  ; Add this line
    
        ; Add the line to the ListView if it matches the search query
        if (Query == "" or InStr(fields[1], Query) or InStr(fields[2], Query) or InStr(fields[3], Query))
            LV_Add("", fields[1], fields[2], fields[3], fields[4], fields[5], favDisplay)  ; Modify this line
    }
    
    ; Sort the ListView by the "favorite" column
    LV_ModifyCol(5, "SortDesc")  ; Use "Sort" for ascending order, "SortDesc" for descending order
    
    GuiControl, +Redraw, MusicList
return


; Add search results to ListView
AddResultsToListView(results) {
    GuiControl, -Redraw, MusicList
    LV_Delete()
    for _, songObj in results {
        favDisplay := songObj.favorite != "0" ? "*" : ""  ; Add this line
        LV_Add("", songObj.artist, songObj.album, songObj.song, songObj.link, songObj.favorite, favDisplay)  ; Modify this line
    }
    
}


; This function is responsible for selecting a song from the ListView based on user actions (Enter key or double click).
SelectSongFromListView(eventType:="") {

    ; If eventType is not "Enter" and the action that triggered this function is not a double click, exit the function.
    if (eventType != "Enter" && A_GuiEvent != "DoubleClick") {
        return
    }

    ; If the Enter key was pressed, get the number of the focused row in the ListView and then retrieve the link in the 4th column of that row.
    if (eventType == "Enter") {
        focusedRow := LV_GetNext(0, "Focused")
        LV_GetText(linkToSend, focusedRow, 4) 
    } else {  ; If the user action was a double click, retrieve the link in the 4th column of the row that was double clicked.
        LV_GetText(linkToSend, A_EventInfo, 4) 
    }

    ; If a link was retrieved, activate the window of the application and send the link to it.
    if (linkToSend != "") {
        WinActivate, ahk_exe %Application%
        Gui, FullSizeGui:Submit, NoHide  ; Save the current state of the GUI without hiding it.

        ; Get the current state of the checkbox.
        GuiControlGet, CheckboxVar, , CheckboxVar

        ; If the checkbox is checked, get the number of the speaker set by the user and send the link to that speaker.
        if (CheckboxVar) {
            GuiControlGet, SpeakerNumberSet, , AdditionalInput
            SendWithDelay("/speakerurl " . SpeakerNumberSet . " " . linkToSend)
        } else {  ; If the checkbox is not checked, send the link without specifying a speaker.
            SendWithDelay("/carurl " . linkToSend)
        }

        ; After sending the link, check the state of the checkbox and close the GUI if the checkbox is checked.
        Gosub, CheckTickBoxAndClose
    }
}


; Check if the GUI should be closed after a song selection
CheckTickBoxAndClose:
    if (!closeOnSelectState)
        Gui, Destroy
return


; This function updates the AlwaysOnTop state of the active GUI based on the closeOnSelectState.
UpdateAlwaysOnTopState:
    if (activeGuiName = "FullSizeGui") {
        if (closeOnSelectState) {
            Gui, FullSizeGui:+AlwaysOnTop
        } else {
            Gui, FullSizeGui:-AlwaysOnTop
        }
    } else if (activeGuiName = "CompactGui") {
        if (closeOnSelectState) {
            Gui, CompactGui:+AlwaysOnTop
        } else {
            Gui, CompactGui:-AlwaysOnTop
        }
    }
return


; This function handles song selection from the menu.
; The song selected by the user is sent to the application.
SongSelection:
    WinActivate, ahk_exe %Application%
    artist := A_ThisMenu2
    album := A_ThisMenu
    song := A_ThisMenuItem
    linkToSend := linkStorage[song]
    Gui, FullSizeGui:Submit, NoHide
    if (CheckboxVar) {
        SendWithDelay("/speakerurl " . SpeakerNumberSet . " " . linkToSend)
    } else {
        SendWithDelay("/carurl " . linkToSend)
    }
return


; This function presents a GUI allowing the user to add a new song to their library
SongAdd() {
    global activeGuiName

    ; Create a new GUI named AddSongInput, which will be always on top and owned by the active GUI if it exists
    if (activeGuiName != "") {
        Gui, AddSongInput:New, +AlwaysOnTop +Owner%activeGuiName%
    } else {
        Gui, AddSongInput:New, +AlwaysOnTop
    }

    ; Based on the active GUI, set the position for the new song input GUI
    if (activeGuiName == "CompactGui") {
        xPos := compactGuiX
        yPos := compactGuiY
    } else {
        xPos := fullSizeGuiX
        yPos := fullSizeGuiY
    }
    
    ; If no specific position is provided, center the GUI on the screen
    if (xPos = 0 and yPos = 0) {
        screenWidth := A_ScreenWidth
        screenHeight := A_ScreenHeight
        xPos := (screenWidth - 400) // 2
        yPos := (screenHeight - 170) // 2
    }

    ; Populate the new song input GUI with elements: Text prompt, input field, and a submit button
    Gui, AddSongInput:Show, x%xPos% y%yPos% w222 h85, Add Song
    Gui, AddSongInput:Add, Text,, Add Song from YouTube
    Gui, AddSongInput:Add, Edit, vSearchYT w200
    Gui, AddSongInput:Add, Button, Default gSubmitSong, Submit

    ; Display the new song input GUI and put the cursor focus in the input field
    Gui, AddSongInput:Show
    GuiControl, AddSongInput:Focus, SearchYT
}


; This function processes the user's song search query from the "Add Song to Library" GUI.
SubmitSong:
    Gui, AddSongInput:Submit  ; Fetch the user's input
    Gui, AddSongInput:Destroy  ; Close the input GUI
    query := SearchYT  ; The user's query becomes the search term
    url := first_youtube_result(query)  ; Fetch the first YouTube video URL for the search term
    SearchYT := url  ; Assign the video URL to SearchYT for later use
    AddSongOptions()  ; Open the "Add Song Options" GUI
return


; This function fetches the URL of the first video result for a given YouTube search query.
first_youtube_result(query){
	StringReplace, query, query, %A_Space%, +, All  ; Spaces must be replaced with '+' in the search URL
	url := "https://www.youtube.com/results?search_query=" query  ; YouTube's search URL format

    ; Create a HTTP GET request for the search URL
	r := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	r.Open("GET", url, true)
	r.Send()
	r.WaitForResponse()

    ; Extract the URL of the first video result from the HTTP response
	if RegExMatch(r.ResponseText, "/watch\?v=.{11}", match)
		url := "https://www.youtube.com" match

	return url
}


; This function creates a GUI for adding song details.
AddSongOptions() {
    global activeGuiName  ; We'll need to know the active GUI

    ; Create a new GUI named AddSongGui, which will be always on top and owned by the active GUI if it exists
    if (activeGuiName != "") {
        Gui, AddSongGui:New, +AlwaysOnTop +Owner%activeGuiName%
    } else {
        Gui, AddSongGui:New, +AlwaysOnTop
    }

    ; Position AddSongGui based on the active GUI and screen dimensions
    if (activeGuiName == "CompactGui") {
        xPos := compactGuiX
        yPos := compactGuiY
    } else {
        xPos := fullSizeGuiX
        yPos := fullSizeGuiY
    }
    
    ; If no specific position is provided, center the GUI on the screen
    if (xPos = 0 and yPos = 0) {
        screenWidth := A_ScreenWidth
        screenHeight := A_ScreenHeight
        xPos := (screenWidth - 400) // 2
        yPos := (screenHeight - 170) // 2
    }
    
    ; Populate AddSongGui with elements: Text prompts, input fields, and buttons
    Gui, AddSongGui:Show, x%xPos% y%yPos% w400 h180, Add Song Options
    Gui, Add, Text, x10 y10, Artist:
    Gui, Add, Edit, x70 y10 w200 h20 vArtistInput, NoArtist
    Gui, Add, Text, x10 y40, Album:
    Gui, Add, Edit, x70 y40 w200 h20 vAlbumInput, NoAlbum
    Gui, Add, Text, x10 y70, Song:
    Gui, Add, Edit, x70 y70 w200 h20 vSongInput, %query%
    Gui, Add, Text, x10 y100, Link:
    Gui, Add, Edit, x70 y100 w200 h20 vLinkInput, %url% ; The input box is populated with the YouTube URL
    Gui, Add, Edit, x70 y130 w200 h20 Hidden vFavInput, 1 ; Hidden field for 'favorite' status, default value is 1
    Gui, Add, Button, x20 y130 w100 h30 Default gSaveSongOptions, Save
    Gui, Add, Button, x180 y130 w100 h30 gGuiClose, Cancel
    Gui, Show, w300 h180, Add Song Options

    ; Finally, show the GUI and set the input focus to the Artist input box
    GuiControl, Focus, ArtistInput
    return
}


; This is the event handler for the Save button in the Add Song Options GUI.
SaveSongOptions:
    Gui, Submit, NoHide  ; Save the current state of the GUI without hiding it
    artist := ArtistInput
    album := AlbumInput
    song := SongInput
    favorite := FavInput ; Fetch the 'favorite' value

    ; Prepare the data string for the new song
    newData := artist . "," . album . "," . song . "," . url . "," . favorite . "`n"

    ; Append the new song's data to the end of the file
    fileObj := FileOpen(vMusicList, "a") ; Open the music list file in append mode
    fileObj.Write(newData)
    fileObj.Close()

    ; Update the text file and GUI to reflect the addition of the new song
    Gosub LoadTXTFileAndGenerateMenu
    Gosub RecreateGUI

return


; This function creates the "Edit Song Options" GUI window and allows the user to edit the song details.
EditSong:
    global activeGuiName

    ; Get the details of the selected row
    SelectedRow := LV_GetNext(0, "Focused") 
    LV_GetText(SelectedArtist, SelectedRow, 1)
    LV_GetText(SelectedAlbum, SelectedRow, 2)
    LV_GetText(SelectedSong, SelectedRow, 3)
    LV_GetText(SelectedLink, SelectedRow, 4)
    LV_GetText(SelectedFav, SelectedRow, 5) 
    
    ; Set SelectedFav to 0 if it's not non-zero
    if (SelectedFav == "")
        SelectedFav := 0
    
    ; If any field in the selected row is not empty, create the EditSong GUI
    if (SelectedArtist != "" || SelectedAlbum != "" || SelectedSong != "" || SelectedLink != "" || SelectedFav != "") { 
        Gui, EditSongGui:New, +AlwaysOnTop +Owner%activeGuiName%

        ; Adding elements to the GUI
        Gui, Add, Text, x10 y10, Artist:
        Gui, Add, Edit, x70 y10 w300 h20 vArtistInput, %SelectedArtist%
        Gui, Add, Text, x10 y40, Album:
        Gui, Add, Edit, x70 y40 w300 h20 vAlbumInput, %SelectedAlbum%
        Gui, Add, Text, x10 y70, Song:
        Gui, Add, Edit, x70 y70 w300 h20 vSongInput, %SelectedSong%
        Gui, Add, Text, x10 y100, Link:
        Gui, Add, Edit, x70 y100 w300 h20 vLinkInput, %SelectedLink%
        Gui, Add, Edit, x70 y130 w300 h20 vFavInput Hidden, %SelectedFav%, 0
        Gui, Add, Button, x10 y130 w100 h30 Default gSaveEditedSong, Save 
        Gui, Add, Button, x120 y130 w100 h30 gGuiClose, Cancel 

    ; Determine GUI position based on active GUI and screen dimensions
    if (activeGuiName == "CompactGui") {
        xPos := compactGuiX
        yPos := compactGuiY
    } else {
        xPos := fullSizeGuiX
        yPos := fullSizeGuiY
    }
    
    if (xPos = 0 and yPos = 0) {
        screenWidth := A_ScreenWidth
        screenHeight := A_ScreenHeight
        xPos := (screenWidth - 400) // 2
        yPos := (screenHeight - 170) // 2
    }
    
        ; Show the GUI
        Gui, EditSongGui:Show, x%xPos% y%yPos% w400 h170, Edit Song Options
    }
return


; Save button event handler for the edited song
SaveEditedSong:
    Gui, Submit, NoHide
    editedArtist := ArtistInput
    editedAlbum := AlbumInput
    editedSong := SongInput
    editedLink := LinkInput
    editedFav := FavInput 

    ; Replace the old song details with the new details in the TXT
    ReplaceSongInTXT(SelectedArtist, SelectedAlbum, SelectedSong, SelectedLink, SelectedFav, editedArtist, editedAlbum, editedSong, editedLink, editedFav)

return


; Replace the selected song in the TXT file
ReplaceSongInTXT(oldArtist, oldAlbum, oldSong, oldLink, oldFav, newArtist, newAlbum, newSong, newLink, newFav) {
    ; Open the TXT file in read mode
    fileObj := FileOpen(vMusicList, "r")
    ; Read the entire file content
    data := fileObj.Read()
    ; Close the file
    fileObj.Close()

    ; Split the data into lines
    lines := StrSplit(data, "`n", "`r")

    ; Create an empty variable to store the updated data
    newData := ""

    ; Iterate through the lines
    for index, line in lines {
        ; Skip empty lines
        if (Trim(line) == "")
            continue

        ; Split the line into fields
        fields := StrSplit(line, ",")

        ; If the current line matches the song to replace, replace it
        if (fields[1] == oldArtist && fields[2] == oldAlbum && fields[3] == oldSong && fields[4] == oldLink && fields[5] == oldFav)
            newData .= newArtist . "," . newAlbum . "," . newSong . "," . newLink . "," . newFav . "`n"
        else
            ; Otherwise, add the line to the updated data
            newData .= line . "`n"
    }

    ; Open the TXT file in write mode
    fileObj := FileOpen(vMusicList, "w")
    ; Write the updated content to the file
    fileObj.Write(newData)
    ; Close the file
    fileObj.Close()

    ; Re-organize the text file for the new song
    Gosub LoadTXTFileAndGenerateMenu

    ; Refresh the GUI to reflect the updated favorite status. This is done by recreating the GUI.
    Gosub RecreateGUI
}


; Deletes the selected song from the ListView and prompts the user for confirmation
DeleteSelectedSong:
    SelectedRow := LV_GetNext(0, "Focused") ; Get the focused row number
    LV_GetText(SelectedArtist, SelectedRow, 1)
    LV_GetText(SelectedAlbum, SelectedRow, 2)
    LV_GetText(SelectedSong, SelectedRow, 3)
    LV_GetText(SelectedLink, SelectedRow, 4)

    ; Check whether any song details were selected
    if (SelectedArtist != "" || SelectedAlbum != "" || SelectedSong != "" || SelectedLink != "") {

        ; Create a new GUI for the deletion confirmation dialog
        Gui, DeleteConfirmation:New, +AlwaysOnTop +Owner%activeGuiName%
        Gui, DeleteConfirmation:Add, Text, x10 y10, Are you sure you want to delete the selected song?
        Gui, DeleteConfirmation:Add, Button, x20 y+30 w70 h30 gConfirmDelete, Yes
        Gui, DeleteConfirmation:Add, Button, x+80 y53 w70 h30 gCancelDelete, No

        ; Determine the position of the confirmation dialog based on the state of the main GUI
        if (activeGuiName == "CompactGui") {
            xPos := compactGuiX
            yPos := compactGuiY
        } else {
            xPos := fullSizeGuiX
            yPos := fullSizeGuiY
        }
        
        if (xPos = 0 and yPos = 0) {
            screenWidth := A_ScreenWidth
            screenHeight := A_ScreenHeight
            xPos := (screenWidth - 400) // 2
            yPos := (screenHeight - 170) // 2
        }
        
        ; Show the deletion confirmation dialog
        Gui, DeleteConfirmation:Show, x%xPos% y%yPos% w265 h95, Delete Song
    }
return


; Removes the selected song from the TXT file and destroys the confirmation GUI
ConfirmDelete:

    ; Destroy the confirmation dialog
    Gui, DeleteConfirmation:Destroy
    
    ; Delete the selected song from the TXT file
    DeleteSongFromTXT(SelectedArtist, SelectedAlbum, SelectedSong, SelectedLink)
return


; Destroys the confirmation GUI without removing the song from the ListView or TXT file
CancelDelete:
    ; Destroy the confirmation dialog
    Gui, DeleteConfirmation:Destroy
return


; Deletes the selected song from the TXT file
DeleteSongFromTXT(artist, album, song, link) {
    ; Open the TXT file in read mode
    fileObj := FileOpen(vMusicList, "r")
    ; Read the entire file content
    data := fileObj.Read()
    ; Close the file
    fileObj.Close()

    ; Split the data into lines
    lines := StrSplit(data, "`n", "`r")

    ; Create an empty variable to store the updated data
    newData := ""

    ; Iterate through the lines
    for index, line in lines {
        ; Skip empty lines
        if (Trim(line) == "")
            continue

        ; Split the line into fields
        fields := StrSplit(line, ",")

        ; If the current line matches the song to delete, skip it
        if (fields[1] == artist && fields[2] == album && fields[3] == song && fields[4] == link)
            continue

        ; Otherwise, add the line to the updated data
        newData .= line . "`n"
    }

    ; Open the TXT file in write mode
    fileObj := FileOpen(vMusicList, "w")
    ; Write the updated content to the file
    fileObj.Write(newData)
    ; Close the file
    fileObj.Close()
    
    ; Refresh the GUI to reflect the updated favorite status. This is done by recreating the GUI.
    Gosub RecreateGUI

}


; Stop Current Song
StopSong:
    ; Activates the window of the specified application
    WinActivate, ahk_exe %Application%
    ; If the CheckboxVar variable is true
    if (CheckboxVar) {
        ; Get the text of the AdditionalInput control and store it in SpeakerNumberSet
        GuiControlGet, SpeakerNumberSet, , AdditionalInput
        ; Call the SendWithDelay function with the specified string
        SendWithDelay("/speakerurl " . SpeakerNumberSet . "  https://www.youtube.com/watch?v=Vbks4abvLEw ")
    } else {
        ; Call the SendWithDelay function with the specified string
        SendWithDelay("/carurl")
    }
return


; Function to generate a random number between min and max (inclusive)
Rand(min, max) {
    ; Generates a random number between min and max and stores it in rand
    Random, rand, min, max
    ; Returns the generated number
    return rand
}


; Random song selection handler
RandomSong:
    WinActivate, ahk_exe %Application%
    ; Get all keys from the linkStorage object
    keys := []
    for key in linkStorage {
        keys.push(key)
    }

    ; Get a random key from the keys array
    randomIndex := Rand(1, keys.Length())
    randomKey := keys[randomIndex]

    ; Get the link corresponding to the random key
    randomLink := linkStorage[randomKey]

    ; Check if the "Speaker" checkbox is checked
    GuiControlGet, SpeakerChecked, , Speaker
    if (SpeakerChecked == 1) {
        GuiControlGet, SpeakerNumberSet, , AdditionalInput
        SendWithDelay("/speakerurl " . SpeakerNumberSet . " " . randomLink)
    } else {
        ; Send the random link
        SendWithDelay("/carurl " . randomLink)
    }
return


; Exit the script
KillSwitch:
    ; Exits the script immediately
	ExitApp
return


; Random song selection handler
RandomCarSong:
    WinActivate, ahk_exe %Application%
    ; Get all keys from the linkStorage object
    keys := []
    for key in linkStorage {
        keys.push(key)
    }

    ; Get a random key from the keys array
    randomIndex := Rand(1, keys.Length())
    randomKey := keys[randomIndex]

    ; Get the link corresponding to the random key
    randomLink := linkStorage[randomKey]

    ; Send the random link using carurl
    SendWithDelay("/carurl " randomLink)
return


; Random song selection handler
RandomSpeakerSong:
    WinActivate, ahk_exe %Application%
    ; Get all keys from the linkStorage object
    keys := []
    for key in linkStorage {
        keys.push(key)
    }

    ; Get a random key from the keys array
    randomIndex := Rand(1, keys.Length())
    randomKey := keys[randomIndex]

    ; Get the link corresponding to the random key
    randomLink := linkStorage[randomKey]

    ; Get the speaker number from the AdditionalInput field
    GuiControlGet, SpeakerNumberSet, , AdditionalInput

    ; Send the random link using speakerurl
    SendWithDelay("/speakerurl " . SpeakerNumberSet . " " . randomLink)
return


; Closes the GUI
GuiClose:
    Gui, Destroy
return


; Function for sending text with a 15ms delay after the text and then pressing Enter
SendWithDelay(TextToSend)
{
    SendInput, t
    Sleep, 15
    SendInput, %TextToSend%
    Sleep, 15
    SendInput, {Enter}
}


; Created by Bassna, aka "Jonathan Willowick" for GTA 5 Eclipse RP server
; https://github.com/Bassna/Eclipse-Music-Menu
; Bassna#4499 on Discord