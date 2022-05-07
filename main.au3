#RequireAdmin
#include <AdbEmulater.au3>
#include "Open_Cv\OpenCV-Match_UDF.au3"

_OpenCV_Startup()

Global $bsPath = emulaterPath("HD-Player.exe")
Global $devicePort = DevicePort($bsPath)

While True

screenCapture($bsPath,$devicePort)

$image1 = Image_Search("object\1.png","adb_screenshort\screenshort.png")
$image2 = Image_Search("object\2.png","adb_screenshort\screenshort.png")
$image3 = Image_Search("object3.png","adb_screenshort\screenshort.png")
$image4 = Image_Search("object\4.png","adb_screenshort\screenshort.png")
$image5 = Image_Search("object\5.png","adb_screenshort\screenshort.png")
$image6 = Image_Search("object\6.png","adb_screenshort\screenshort.png")
$image7 = Image_Search("object\7.png","adb_screenshort\screenshort.png")
$image8 = Image_Search("object\8.png","adb_screenshort\screenshort.png")
$image9 = Image_Search("object\9.png","adb_screenshort\screenshort.png")
$image10 = Image_Search("object\10.png","adb_screenshort\screenshort.png")
$image99 = Image_Search("object\99.png","adb_screenshort\screenshort.png")

If $image1[0] > 0 Then ;
    tap($bsPath,$devicePort,$image1[4],$image1[5])
    tapQuest()
EndIf
If $image2[0] > 0 Then ;
    tap($bsPath,$devicePort,$image2[4],$image2[5])
    tapQuest()
EndIf
If $image3[0] > 0 Then ;
    tap($bsPath,$devicePort,$image3[4],$image3[4])
EndIf
If $image4[0] > 0 Then ;
    tap($bsPath,$devicePort,$image4[4],$image4[5])
EndIf
If $image5[0] > 0 Then ;
    tap($bsPath,$devicePort,$image5[4],$image5[5])
EndIf
If $image6[0] > 0 Then ;
    tap($bsPath,$devicePort,$image6[4],$image6[5])
EndIf
If $image7[0] > 0 Then ;
    tap($bsPath,$devicePort,$image7[4],$image7[5])
    Sleep(200)
    tapQuest()
EndIf
If $image8[0] > 0 Then ;
    tap($bsPath,$devicePort,$image8[4],$image8[5])
    Sleep(200)
    tapQuest()
EndIf
If $image9[0] > 0 Then ;
    tap($bsPath,$devicePort,$image9[4],$image9[5])
    Sleep(200)
    tapQuest()
EndIf
If $image10[0] > 0 Then ;
    tap($bsPath,$devicePort,$image10[4],$image10[5])
    Sleep(200)
    tapQuest()
EndIf
If $image99[0] > 0 Then ;
    tap($bsPath,$devicePort,$image99[4],$image99[5])
    Sleep(200)
    tapQuest()
EndIf

WEnd

_OpenCV_Shutdown()

Func tapQuest()
    tap($bsPath,$devicePort,156,250)
EndFunc