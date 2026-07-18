#SingleInstance force ; only 1 instance of this script may run at a time.
#InstallMouseHook
#InstallKeybdHook

CoordMode, Mouse, screen
CoordMode, Pixel, screen

Menu, Tray, Icon, imageres.dll, 90

;THIS IS A GREAT FIRST SCRIPT FOR AHK NOOBS! IT WORKS WITH VERY LITTLE SETUP. JUST READ THE STUFF BELOW! YAY! 
;VIDEO EXPLANATION:  https://youtu.be/O6ERELse_QY?t=23m40s


; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; NOTE THAT YOU MUST ASSIGN \ (backslash) TO "Move playhead to cursor" IN PREMIERE'S KEYBOARD SHORTCUTS PANEL!
; YOU SHOULD ALSO ASSIGN CTRL ALT D to "DESELECT ALL" 
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


;NOTE: I use the right mouse button for this because my current mouse does not have macro keys on it. I could use the middle mouse button, but it requires too much pressure to push down so often, and you have to be careful not to accidentally scroll it.
;But if you want to use a button other than the right mouse button, the script becomes a lot simpler. Scroll down to the bottom for that script.

;NOTE: This does not, and cannot work on the timeline where there are no tracks visible.
;Explanation: https://twitter.com/boxrNathan/status/927371468371103745
;That is color 0x212121, and last I checked, it shows up in many other places in premiere, not just that part of the timeline.
;The easy solution is to just fill up your timeline with tracks; have no blank space.

;---------------------------------------------------------------------------------------

;First, we define all the timeline's DEFAULT possible colors.
;(Note that your colors will be different if you changed the UI brightness inside preferences > appearance > brightness.)
;I used Window Spy (it comes with AHK) to detect the exact colors onscreen.
timeline0 = 0x3F3F3F ;timeline color inside the in/out points ON a targeted track, after some UPDATE in like 2024
timeline1 = 0x414141 ;timeline color inside the in/out points ON a targeted track, BEFORE some update in 2024
timeline2 = 0x303030 ;timeline color of the separating LINES between targeted AND non targeted tracks inside the in/out points
timeline3 = 0x1b1b1b ;the timeline color inside in/out points on a NON targeted track... before 2024. Now, this no longer works, which is turbo lame.
timeline4 = 0x1D1D1D ;the color of the bare timeline NOT inside the in out points
timeline5 = 0xE2E2E2 ;the color of a SELECTED blank space on the timeline, NOT in the in/out points
timeline6 = 0xE7E7E7 ;the color of a SELECTED blank space on the timeline, IN the in/out points, on a TARGETED track
timeline7 = 0x191919 ;the color of a SELECTED blank space on the timeline, IN the in/out points, on an UNTARGETED track

timeline8 = 0x1c1c1c ;NEW color as of 2024, of the NON TARGETED space between in/out points. UNFORTUNATELY, this is also the same color as the BINS in areas where there are no items, meaning now you can't right click to make new items and folders and stuff, and therefore, I must remove it from the list below. SUPER LAME.

;These screen bounds are more stable than Premiere's changing timeline ClassNN value.
timelinePanelTargetX := 228
timelinePanelTargetY := 762
timelinePanelTargetW := 1626
timelinePanelTargetH := 607
timelinePanelTolerance := 35
PremiereTimelinePanelClassNN := ""


#IfWinActive ahk_exe Adobe Premiere Pro.exe ;exact name was gotten from windowspy
;--------EVERYTHING BELOW THIS LINE WILL ONLY WORK INSIDE PREMIERE PRO!----------

Rbutton::
UpdateTimelinePanelClassNN()
MouseGetPos, X, Y, , PremiereSequenceCheck
PixelGetColor colorr, %X%, %Y%, RGB
if (IsTimelineColor(colorr) && IsHoveringTimelinePanel(PremiereSequenceCheck))
{
	cleanupEscapeCount := 1
	Click, middle
	Sleep, 10
	if (colorr = timeline4 || colorr = timeline5 || colorr = timeline6 || colorr = timeline7 || colorr = timeline2) ;these are the timeline colors of a selected clip or blank space, in or outside of in/out points.
		send {ESC} ;in Premiere 13.0, ESCAPE will now deselect clips on the timeline, in addition to its other uses. i think it is good ot use here, now. But you can swap this out with CTRL SHIFT D if you like.
	;send ^!d ;in Premiere, set CTRL ALT D to "DESELECT ALL"
	;BREAKTHROUGH -- it looks like a middle mouse click will BRING FOCUS TO a panel without doing ANYTHING ELSE like selecting or going through tabs or anything. Unfortunately, i still can't know with AHK which panel is already in focus.
	;Click, middle sends the middle mouse button to BRING FOCUS TO the timeline, WITHOUT selecting any clips or empty spaces between clips. very nice!
	; tooltip, % GetKeyState("Rbutton", "P") ;<----this was essential for me to figure out EXACTLY how AHK wanted this query to be phrased. Why should i need the quotation marks?? Why does it return a 1 and 0, but for the other method, it returns U and D? Who the hell knows...
	; if GetKeyState("$Rbutton") = D ;<--- see, this line did not work AT ALL.
	if GetKeyState("Rbutton", "P") = 1 ;<----THIS is the only way to phrase this query.
	{
		;tooltip, we are inside the IF now
		;sleep 1000
		;tooltip, 
		loop
		{
			Send \ ;in premiere, this must be set to "move playhead to cursor."
			MouseGetPos, X, Y
			PixelGetColor movedColor, %X%, %Y%, RGB
			if (movedColor = timeline5 || movedColor = timeline6)
				cleanupEscapeCount := 2
			;Tooltip, Right click playhead mod! %PremiereSequenceCheck% %PremiereTimelinePanelClassNN% ;you can remove this line if you don't like the tooltip. You don't need it!
			if GetKeyState("Rbutton", "P") = 0
			{
				;msgbox,,,time to break,1 ;I use message boxes when debugging, and then just comment the out rather than deleting them. It's just like disabling a clip in Premiere.
				tooltip,
				if (cleanupEscapeCount = 2)
					Send {Esc}{Esc}
				else
					Send {Esc}
				goto theEnd
				break
			}
			sleep 3 ;this loop will repeat every 16 milliseconds.
		}
	}
	;MouseClick, left ;notice how this is commented out. I deemed it inferior to using ESCAPE.
}
else
	sendinput {Rbutton}
theEnd:
Return


;If you don't want to use Rbutton (the right mouse button), then you don't need to check for colors and things. This simplifies the script siginificantly.
;In the following script, You can change "Mbutton" to anything else. like "Xbutton1", or  even "F12" if you wanted.
;So, assuming you've mapped "move playhead to cursor" to the \ key, the problem is that it fires once, waits 1 second, and only then does it continue to fire.
;that's why I use a loop - to send constant keypresses, for a smooth experience.
;SCRIPT HAS NOT YET BEEN TESTED BY ME.

;;;;;Mbutton::\ ;<----this would be the STUPID way of doing this. BAD BAD BAD! do not want!
#ifwinactive ahk_exe adobe premiere pro.exe
Mbutton::
if GetKeyState("MButton", "P") = 1
	{
	loop
		{
		Send \ ;in premiere, this must be set to "move playhead to cursor."
		;Tooltip, button 5 playhead mod!
		sleep 16 ;this loop will repeat every 16 milliseconds.
		if GetKeyState("Xbutton2", "P") = 0
			{
			;msgbox,,,time to break,1
			;tooltip,
			goto theEnd2
			;break
			}
		}
}
theEnd2:
Return


IsTimelineColor(colorr) {
	global timeline0, timeline1, timeline2, timeline3, timeline4, timeline5, timeline6, timeline7
	return (colorr = timeline0 || colorr = timeline1 || colorr = timeline2 || colorr = timeline3 || colorr = timeline4 || colorr = timeline5 || colorr = timeline6 || colorr = timeline7)
}

UpdateTimelinePanelClassNN() {
	global PremiereTimelinePanelClassNN

	MouseGetPos, mouseX, mouseY, hoveredWindowID, hoveredClassNN
	MouseGetPos, mouseX, mouseY, hoveredWindowID, hoveredControlHwnd, 2
	if (!hoveredClassNN || !hoveredControlHwnd)
		return ""

	WinGetPos, hoveredX, hoveredY, hoveredW, hoveredH, ahk_id %hoveredControlHwnd%
	if IsTimelinePanelBounds(hoveredX, hoveredY, hoveredW, hoveredH)
	{
		PremiereTimelinePanelClassNN := hoveredClassNN
		return PremiereTimelinePanelClassNN
	}

	return ""
}

IsHoveringTimelinePanel(hoveredClassNN) {
	global PremiereTimelinePanelClassNN

	if (PremiereTimelinePanelClassNN = "" || hoveredClassNN != PremiereTimelinePanelClassNN)
		return 0

	MouseGetPos, mouseX, mouseY, hoveredWindowID, hoveredControlHwnd, 2
	if (!hoveredControlHwnd)
		return 0

	WinGetPos, hoveredX, hoveredY, hoveredW, hoveredH, ahk_id %hoveredControlHwnd%
	return IsTimelinePanelBounds(hoveredX, hoveredY, hoveredW, hoveredH)
}

IsTimelinePanelBounds(controlX, controlY, controlW, controlH) {
	global timelinePanelTargetX, timelinePanelTargetY, timelinePanelTargetW, timelinePanelTargetH, timelinePanelTolerance
	return (Abs(controlX - timelinePanelTargetX) <= timelinePanelTolerance
		&& Abs(controlY - timelinePanelTargetY) <= timelinePanelTolerance
		&& Abs(controlW - timelinePanelTargetW) <= timelinePanelTolerance
		&& Abs(controlH - timelinePanelTargetH) <= timelinePanelTolerance)
}






; #IfWinNotActive ahk_exe Adobe Premiere Pro.exe

; ~Rbutton::
; tellme := isPremiereUnderCursor(yesno)
; if (tellme = 0)
	; {
	; sendinput {Rbutton} ;function as normal. sadly does not maintain the holding down of right click, in cases where it may be important.
	; return ;do nothing else
	; }
; ;tooltip, yes it is
; send, {mButton} ;middle mouse button will bring focus to Premiere
; return





; isPremiereUnderCursor(yesno := 1)
; {
; ;so the issue with this is that if I hit this button while Premiere is active, but the cursor is hovering over some OTHER application, it doesn't know that, and will send these  keystrokes to THAT window. Well, at least it'll send stuff after the left click, to that window.
; ; ;I need to have it DETECT that you have actually clicked on premiere.
; MouseGetPos,,,KDE_id
; WinGet,KDE_Win,MinMax,ahk_id %KDE_id%
; ; If KDE_Win
    ; ; return ;I am not sure exactly what this is for
; ; ;tooltip, %KDE_Win%
; WinGetClass,fancyclass,ahk_id %KDE_id%
; ;tooltip, fancyclass = %fancyclass%
; ;sleep 1000
; If (fancyclass = "DroverLord - Window Class") ;this is in case you use this on a floating Premiere window NOT connected to the main premiere window!
	; {
	; tooltip, on floating window
	; sleep 100
	; tooltip,
	; return 1
	; }
; else If (fancyclass != "Premiere Pro")
	; {
	; ;tooltip, NOT IN PREMIERE
	; ;sleep 100
	; ;tooltip,
	; ;winactivate?
	; WinActivate, ahk_id %KDE_id%
	; return 0
	; }
; else
	; return 1
; }
