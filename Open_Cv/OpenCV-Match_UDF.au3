; #UDF# =======================================================================================================================
; Name ..........: OpenCV Match UDF
; Description ...: Matches pictures on the screen to perform simple automation actions.
; Version .......: v1.0
; Author ........: BB_19
; Credits ........: @mylise
; ===============================================================================================================================
#include-once
#include <GDIplus.au3>
#include <ScreenCapture.au3>
#include <WinAPI.au3>
Global $OpenCV_MatchLogging = False, $OpenCV_ErrorLogging = False, $OpenCV_AutoitConsoleLogging = False
Global $_opencv_core, $_opencv_highgui, $_opencv_imgproc

_GDIPlus_Startup()

; #FUNCTION# ====================================================================================================================
; Name ..........: _ClickMouse
; Description ...:  Calculates the center of a rect using an array with coordinates and then clicks the left/right mouse button.
; Syntax ........: _ClickMouse($Coordinates, $mouse_button[, $number_of_clicks = 1])
; Parameters ....: $Coordinates         - Array returned by _MatchPicture.
;               			  $mouse_button        - [optional] String. "left/right". Default is "left"
;                  			  $number_of_clicks    - [optional] a general number value. Default is 1.
; ===============================================================================================================================
Func _ClickMouse($Coordinates, $mouse_button = "left", $number_of_clicks = 1)
	MouseUp("")
	BlockInput(1)
	MouseClick($mouse_button, ($Coordinates[0] + $Coordinates[2]) / 2, ($Coordinates[1] + $Coordinates[3]) / 2, $number_of_clicks, 0)
	BlockInput(0)
EndFunc   ;==>_ClickMouse

; #FUNCTION# ====================================================================================================================
; Name ..........: _MatchPicture
; Description ...:  Searches for a picture on screen or on a specific area of the screen and returns the coordinates where the picture has been found.
; Syntax ........: _MatchPicture($Match_Pic[, $Threshold = 0.9[, $CustomCords = False[, $LoopCount = 1[, $LoopWait = 2000]]]])
; Parameters ....: $Match_Pic           -  The path to the picture to be matched.
;                  $Threshold           - [optional] Threshold 0.1-1.0. The higher, the more precisely the match picture has to be in order to match. Default is 0.9.
;                  $CustomCords         - [optional] An array with coordinates for a rect x1,y1,x2,y2 that can be used to search on a specific region of the screen. Can be generated using the provided Snapshot-Tool. Default is False.
;                  $LoopCount           - [optional] The number of tries that the script will recheck if the match picture can be found on the screen. Default is 1.
;                  $LoopWait            - [optional] The wait time in ms between each try. Default is 2000 ms.
; Return values .: Array with coordinates(x1,y1,x2,y2) of the match or @error if no match was found.
; Author ........: BB_19
; Related .......: https://www.autoitscript.com/forum/topic/160732-opencv-udf/
; Credits .....: @mylise
; ===============================================================================================================================
Func Image_Search($Match_Pic,$ImageCapture, $Left = 0, $Top = 0, $Right = -1, $Bottom = -1, $Threshold = 0.75, $LoopCount = 1)
	Local $hMatch_Pic = _cvLoadImage($Match_Pic)
	Local $hMatch_Size = _cvGetSize($hMatch_Pic)
	Local $width2 = DllStructGetData($hMatch_Size, "width")
	Local $height2 = DllStructGetData($hMatch_Size, "height")

	For $i = 1 To $LoopCount Step 1

		Local $Bitmap = _GDIPlus_ImageLoadFromFile($ImageCapture)

		Local $hMain_Pic = _Opencv_BMP2IPL($Bitmap)
		Local $hMain_Size = _cvGetSize($hMain_Pic)
		Local $width = DllStructGetData($hMain_Size, "width")
		Local $height = DllStructGetData($hMain_Size, "height")
		Local $rw = $width - $width2 + 1
		Local $rh = $height - $height2 + 1
		Local $tmaxloc = DllStructCreate("int x;" & "int y;")
		Local $tminloc = DllStructCreate("int x;" & "int y;")
		Local $tmaxval = DllStructCreate("double max;")
		Local $tminval = DllStructCreate("double min;")
		Local $pmaxloc = DllStructGetPtr($tmaxloc)
		Local $pminloc = DllStructGetPtr($tminloc)
		Local $pmaxval = DllStructGetPtr($tmaxval)
		Local $pminval = DllStructGetPtr($tminval)

		;Search for Match
		Local $presult = _cvCreateMat($rh, $rw, 5)
		_cvMatchTemplate($hMain_Pic, $hMatch_Pic, $presult, 5)
		_cvThreshold($presult, $presult, $Threshold, 1, 0)
		_cvMinMaxLoc($presult, $pminval, $pmaxval, $pminloc, $pmaxloc, Null)

		;Set coordinates

		Local $Coordinates[6]
		$Coordinates[0] = (DllStructGetData($tmaxloc, "x"))
		$Coordinates[1] = (DllStructGetData($tmaxloc, "y"))
		$Coordinates[2] = (DllStructGetData($tmaxloc, "x") + $width2)
		$Coordinates[3] = (DllStructGetData($tmaxloc, "y") + $height2)
		$Coordinates[4] = ($Coordinates[0] + $Coordinates[2]) / 2
		$Coordinates[5] = ($Coordinates[1] + $Coordinates[3]) / 2


		;Release Resources
		_cvReleaseMat($presult)
		_cvReleaseImage($hMain_Pic)
		_GDIPlus_BitmapDispose($Bitmap)
		_GDIPlus_ImageDispose($Bitmap)

		;Check if found
		If Not (DllStructGetData($tmaxloc, "x") = 0 And DllStructGetData($tmaxloc, "y") = 0 And $width2 = DllStructGetData($tmaxloc, "x") + $width2 And $height2 = DllStructGetData($tmaxloc, "y") + $height2) Then
			_cvReleaseImage($hMatch_Pic)
;~ 			_Internal_MatchLogger("Match found at: " & $Coordinates[0] & "|" & $Coordinates[1] & "|" & $Coordinates[2] & "|" & $Coordinates[3] & " // Loop counter: " & $iTries & " // Threshold: " & $Threshold & " // Total check time: " & Round(TimerDiff($Perf), 0) & " ms")
			Return $Coordinates
		EndIf
	Next

	_cvReleaseImage($hMatch_Pic)
	$Coordinates[0] = 0
	$Coordinates[1] = 0
	$Coordinates[2] = 0
	$Coordinates[3] = 0
	$Coordinates[4] = 0
	$Coordinates[5] = 0
	Return $Coordinates
EndFunc   ;==>Image_Search

; #FUNCTION# ====================================================================================================================
; Name ..........: _OpenCV_EnableLogging
; Description ...:  Enables Logging of matches and errors in file and console.
; Syntax ........: _OpenCV_EnableLogging([$MatchLogging = True[, $ErrorLogging = False[, $AutoitConsoleLogging = False]]])
; Parameters ....: $MatchLogging        - [optional] Logs all matches in a file with the coordinates and other details. Default is True.
;                			  $ErrorLogging       	  - [optional]  Logs all errors including failed matches in a file. Default is False.
;                  			  $AutoitConsoleLogging - [optional] Outputs all matches, errors and failed matches on the Autoit console. Default is False.
; ===============================================================================================================================
Func _OpenCV_EnableLogging($MatchLogging = True, $ErrorLogging = False, $AutoitConsoleLogging = False)
	$OpenCV_MatchLogging = $MatchLogging
	$OpenCV_ErrorLogging = $ErrorLogging
	$OpenCV_AutoitConsoleLogging = $AutoitConsoleLogging
EndFunc   ;==>_OpenCV_EnableLogging

; #FUNCTION# ====================================================================================================================
; Name ..........: _MarkMatch
; Description ...:  Draws a rect on the position of the match to indicate where the match was found on the screen.
; Syntax ........: _MarkMatch($Coordinates[, $iColor = 0x0000FF])
; Parameters ....: $Coordinates   - Array returned by _MatchPicture.
;                  			  $iColor              - [optional] an integer value. Default is 0x0000FF.
; Note ................: The marking is not visible for long.
; Author ........: Malkey
; Modified .....: BB_19
; ===============================================================================================================================
Func _MarkMatch($hwnd, $Coordinates, $X = 0, $Y = 0, $iColor = 0x0000FF)
	Local $start_x = $Coordinates[0] + $X, $start_y = $Coordinates[1] + $Y, $iWidth = $Coordinates[2] + $X, $iHeight = $Coordinates[3] + $Y
	Local $hDC = _WinAPI_GetWindowDC($hwnd) ; DC of entire screen (desktop)
	Local $tRect = DllStructCreate($tagRECT)
	DllStructSetData($tRect, 1, $start_x)
	DllStructSetData($tRect, 2, $start_y)
	DllStructSetData($tRect, 3, $iWidth)
	DllStructSetData($tRect, 4, $iHeight)
	Local $hBrush = _WinAPI_CreateSolidBrush($iColor)
	_WinAPI_FrameRect($hDC, DllStructGetPtr($tRect), $hBrush)
	_WinAPI_DeleteObject($hBrush)
	_WinAPI_ReleaseDC($hwnd, $hDC)
EndFunc   ;==>_MarkMatch

Func _MarkMatchScreen($Coordinates, $iColor = 0x0000FF)
	Local $start_x = $Coordinates[0], $start_y = $Coordinates[1], $iWidth = $Coordinates[2], $iHeight = $Coordinates[3]
	Local $hDC = _WinAPI_GetWindowDC(0) ; DC of entire screen (desktop)
	Local $tRect = DllStructCreate($tagRECT)
	DllStructSetData($tRect, 1, $start_x)
	DllStructSetData($tRect, 2, $start_y)
	DllStructSetData($tRect, 3, $iWidth)
	DllStructSetData($tRect, 4, $iHeight)
	Local $hBrush = _WinAPI_CreateSolidBrush($iColor)
	_WinAPI_FrameRect($hDC, DllStructGetPtr($tRect), $hBrush)
	_WinAPI_DeleteObject($hBrush)
	_WinAPI_ReleaseDC(0, $hDC)
EndFunc   ;==>_MarkMatchScreen


; #FUNCTION# ====================================================================================================================
; Name ..........: _ScreenSize
; Description ...:  Returns the full width + height that is required to create a snapshot of all displays at once.
; Syntax ........: _ScreenSize()
; Return values .: Array with [0]=Width, [1]=Height
; Author ........: BB_19
; ===============================================================================================================================
Func _ScreenSize() ;Returns complete Width+Height of all monitors
	Local $MonSizePos[2], $MonNumb = 1
	$MonSizePos[0] = @DesktopWidth
	$MonSizePos[1] = @DesktopHeight
	;Get Monitors
	Local $aPos, $MonList = _WinAPI_EnumDisplayMonitors()
	If @error Then Return $MonSizePos
	If IsArray($MonList) Then
		ReDim $MonList[$MonList[0][0] + 1][5]
		For $i = 1 To $MonList[0][0]
			$aPos = _WinAPI_GetPosFromRect($MonList[$i][1])
			For $j = 0 To 3
				$MonList[$i][$j + 1] = $aPos[$j]
			Next
			Local $width = $MonList[$i][1] + $MonList[$i][3]
			Local $height = ($MonList[$i][2] + $MonList[$i][4])
			If $MonSizePos[0] < ($width) Then $MonSizePos[0] = $width
			If $MonSizePos[1] < ($height) Then $MonSizePos[1] = $height
		Next
	EndIf
	Return $MonSizePos
EndFunc   ;==>_ScreenSize

Func _Internal_MatchLogger($Message)
	Local $Timestamp = @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & " - "
	If $OpenCV_AutoitConsoleLogging Then ConsoleWrite($Timestamp & $Message & @CRLF)
	If $OpenCV_MatchLogging Then
		Local $MatchLogFile = FileOpen(@ScriptDir & "\OpenCV_Match.log", 1)
		FileWrite($MatchLogFile, $Timestamp & $Message & @CRLF)
		FileClose($MatchLogFile)
	EndIf
EndFunc   ;==>_Internal_MatchLogger

Func _Internal_ErrorLogger($Message)

	Local $Timestamp = @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & " - "
	If $OpenCV_AutoitConsoleLogging Then ConsoleWrite($Timestamp & $Message & @CRLF)
	If $OpenCV_ErrorLogging Then
		Local $ErrorLogFile = FileOpen(@ScriptDir & "\OpenCV_Error.log", 1)
		FileWrite($ErrorLogFile, $Timestamp & $Message & @CRLF)
		FileClose($ErrorLogFile)
	EndIf
EndFunc   ;==>_Internal_ErrorLogger

;OpenCV functions created by mylise, https://www.autoitscript.com/forum/topic/160732-opencv-udf/

Func _Opencv_BMP2IPL($pBmpImage)
	Local $iW = _GDIPlus_ImageGetWidth($pBmpImage), $iH = _GDIPlus_ImageGetHeight($pBmpImage)
	Local $tBitmapData = _GDIPlus_BitmapLockBits($pBmpImage, 0, 0, $iW, $iH, $GDIP_ILMREAD, $GDIP_PXF32ARGB)

	Local $pIPL = _cvCreateImageHeader(_cvSize($iW, $iH), 8, 4)

	_cvSetData($pIPL, DllStructGetData($tBitmapData, "scan0"), DllStructGetData($tBitmapData, "stride"))

	Local $pIplDst = _cvCloneImage($pIPL)
	_cvReleaseImageHeader($pIPL)

	_GDIPlus_BitmapUnlockBits($pBmpImage, $tBitmapData)
	Local $pIplDst2 = _cvCreateImage(_cvSize($iW, $iH), 8, 3)

	_cvCvtColor($pIplDst, $pIplDst2, 1)
	_cvReleaseImage($pIplDst)

	Return $pIplDst2
EndFunc   ;==>_Opencv_BMP2IPL

Func _cvCvtColor($cvsrc, $cvdst, $cvcode)
	DllCall($_opencv_imgproc, "none:cdecl", "cvCvtColor", "ptr", $cvsrc, "ptr", $cvdst, "int", $cvcode)
;~ 	If @error Then ConsoleWrite("error in cvCvtColor")
	Return
EndFunc   ;==>_cvCvtColor

Func _cvCreateImage($cvsize, $cvdepth, $cvchannels)
	Local $_aResult = DllCall($_opencv_core, "ptr:cdecl", "cvCreateImage", "struct", $cvsize, "int", $cvdepth, "int", $cvchannels)
;~ 	If @error Then ConsoleWrite("error in cvCreateImage")
	Return $_aResult[0]
EndFunc   ;==>_cvCreateImage

Func _cvReleaseImageHeader($cvimage)
	DllCall($_opencv_core, "none:cdecl", "cvReleaseImageHeader", "ptr*", $cvimage)
;~ 	If @error Then ConsoleWrite("error in cvReleaseImageHeader")
	Return
EndFunc   ;==>_cvReleaseImageHeader

Func _cvCloneImage($cvimage)
	Local $_aResult = DllCall($_opencv_core, "ptr:cdecl", "cvCloneImage", "ptr", $cvimage)
;~ 	If @error Then ConsoleWrite("error in cvCloneImage")
	Return $_aResult[0]
EndFunc   ;==>_cvCloneImage

Func _cvSetData($cvarr, $cvdata, $cvstep)
	DllCall($_opencv_core, "none:cdecl", "cvSetData", "ptr", $cvarr, "ptr", $cvdata, "int", $cvstep)
;~ 	If @error Then ConsoleWrite("error in cvSetData")
	Return
EndFunc   ;==>_cvSetData

Func _cvSize($width, $height)
	Local $vSize = DllStructCreate("int width;" & "int height;")
	DllStructSetData($vSize, "width", $width)
	DllStructSetData($vSize, "height", $height)
	Return $vSize
EndFunc   ;==>_cvSize

Func _cvCreateImageHeader($cvsize, $cvdepth, $cvchannels)
	Local $_aResult = DllCall($_opencv_core, "ptr:cdecl", "cvCreateImageHeader", "struct", $cvsize, "int", $cvdepth, "int", $cvchannels)
;~ 	If @error Then ConsoleWrite("error in cvCreateImageHeader")
	Return $_aResult[0]
EndFunc   ;==>_cvCreateImageHeader

Func _cvMinMaxLoc($cvarr, $cvmin_val, $cvmax_val, $cvmin_loc, $cvmax_loc, $cvmask = "")
	DllCall($_opencv_core, "none:cdecl", "cvMinMaxLoc", "ptr", $cvarr, "ptr", $cvmin_val, "ptr", $cvmax_val, "ptr", $cvmin_loc, "ptr", $cvmax_loc, "ptr", $cvmask)
;~ 	If @error Then ConsoleWrite("error in cvMinMaxLoc")
	Return
EndFunc   ;==>_cvMinMaxLoc

Func _cvMatchTemplate($cvimage, $cvtempl, $cvresult, $cvmethod)
	DllCall($_opencv_imgproc, "none:cdecl", "cvMatchTemplate", "ptr", $cvimage, "ptr", $cvtempl, "ptr", $cvresult, "int", $cvmethod)
;~ 	If @error Then ConsoleWrite("error in cvMatchTemplate")
	Return
EndFunc   ;==>_cvMatchTemplate

Func _cvThreshold($cvsrc, $cvdst, $cvthreshold, $cvmax_value, $cvthreshold_type)
	Local $_aResult = DllCall($_opencv_imgproc, "double:cdecl", "cvThreshold", "ptr", $cvsrc, "ptr", $cvdst, "double", $cvthreshold, "double", $cvmax_value, "int", $cvthreshold_type)
;~ 	If @error Then ConsoleWrite("error in cvThreshold")
	Return
EndFunc   ;==>_cvThreshold

Func _cvCreateMat($cvrows, $cvcols, $cvtype)
	Local $_aResult = DllCall($_opencv_core, "ptr:cdecl", "cvCreateMat", "int", $cvrows, "int", $cvcols, "int", $cvtype)
;~ 	If @error Then ConsoleWrite("error in cvCreateMat")
	Return $_aResult[0]
EndFunc   ;==>_cvCreateMat

Func _cvGetSize($pimage)
	Local $_aResult = DllCall($_opencv_core, "int64:cdecl", "cvGetSize", "ptr", $pimage)
;~ 	If @error Then ConsoleWrite("error csize image ")
	Local $width = BitAND(0xFFFFFFFF, $_aResult[0])
	Local $height = Int($_aResult[0] / 2 ^ 32)
	Local $vSize = DllStructCreate("int width;" & "int height;")
	DllStructSetData($vSize, "width", $width)
	DllStructSetData($vSize, "height", $height)
	Return $vSize
EndFunc   ;==>_cvGetSize

Func _cvReleaseMat($cvmat)
	DllCall($_opencv_core, "none:cdecl", "cvReleaseMat", "ptr*", $cvmat)
;~ 	If @error Then ConsoleWrite("error in cvReleaseMat")
	Return
EndFunc   ;==>_cvReleaseMat

Func _cvReleaseImage($pimage)
	DllCall($_opencv_core, "none:cdecl", "cvReleaseImage", "ptr*", $pimage)
;~ 	If @error Then ConsoleWrite("error image release")
EndFunc   ;==>_cvReleaseImage

Func _cvLoadImage($filename, $iscolor = 1)
	If $filename = "" Then Return SetError(1)
	$_aResult = DllCall($_opencv_highgui, "int:cdecl", "cvLoadImage", "str", $filename, "int", $iscolor)
;~ 	If @error Then ConsoleWrite("File not loading")
	If Not IsArray($_aResult) Then
		MsgBox(16, "Error", "Failed loading DLLs.")
		_OpenCV_Shutdown()
		Exit
	EndIf
	Return $_aResult[0]
EndFunc   ;==>_cvLoadImage

Func _OpenCV_Shutdown()
	DllClose($_opencv_core)
	DllClose($_opencv_highgui)
	DllClose($_opencv_imgproc)
	_GDIPlus_Shutdown()
EndFunc   ;==>_OpenCV_Shutdown

Func _OpenCV_Startup()
	$_opencv_core = DllOpen("DLLs\opencv_core2413.dll")
	$_opencv_highgui = DllOpen("DLLs\opencv_highgui2413.dll")
	$_opencv_imgproc = DllOpen("DLLs\opencv_imgproc2413.dll")
EndFunc   ;==>_OpenCV_Startup


