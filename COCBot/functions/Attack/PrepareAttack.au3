; #FUNCTION# ====================================================================================================================
; Name ..........: PrepareAttack
; Description ...: Checks the troops when in battle, checks for type, slot, and quantity.  Saved in $g_avAttackTroops[SLOT][TYPE/QUANTITY] variable
; Syntax ........: PrepareAttack($pMatchMode[, $Remaining = False])
; Parameters ....: $pMatchMode          - a pointer value.
;                  $Remaining           - [optional] Flag for when checking remaining troops. Default is False.
; Return values .: None
; Author ........:
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
Func PrepareAttack($pMatchMode, $bRemaining = False, $DebugSiege = False) ;Assigns troops

	; Attack CSV has debug option to save attack line image, save have png of current $g_hHBitmap2
	If ($pMatchMode = $DB And $g_aiAttackAlgorithm[$DB] = 1) Or ($pMatchMode = $LB And $g_aiAttackAlgorithm[$LB] = 1) Then
		If $g_bDebugMakeIMGCSV And $bRemaining = False And TestCapture() = 0 Then
			If $g_iSearchTH = "-" Then ; If TH is unknown, try again to find as it is needed for filename
				imglocTHSearch(True, False, False)
			EndIf
			DebugImageSave("clean", False, Default, Default, "TH" & $g_iSearchTH & "-") ; make clean snapshot as well
		EndIf
	EndIf

	If Not $bRemaining Then ; reset Hero variables before attack if not checking remaining troops
		$g_bDropKing = False ; reset hero dropped flags
		$g_bDropQueen = False
		$g_bDropWarden = False
		If $g_iActivateKing = 1 Or $g_iActivateKing = 2 Then $g_aHeroesTimerActivation[$eHeroBarbarianKing] = 0
		If $g_iActivateQueen = 1 Or $g_iActivateQueen = 2 Then $g_aHeroesTimerActivation[$eHeroArcherQueen] = 0
		If $g_iActivateWarden = 1 Or $g_iActivateWarden = 2 Then $g_aHeroesTimerActivation[$eHeroGrandWarden] = 0

		$g_iTotalAttackSlot = 10 ; reset flag - Slot11+
		$g_bDraggedAttackBar = False
	EndIf

	If $g_bDebugSetlog Then SetDebugLog("PrepareAttack for " & $pMatchMode & " " & $g_asModeText[$pMatchMode], $COLOR_DEBUG)
	If $bRemaining Then
		SetLog("Checking remaining unused troops for: " & $g_asModeText[$pMatchMode], $COLOR_INFO)
	Else
		SetLog("Initiating attack for: " & $g_asModeText[$pMatchMode], $COLOR_ERROR)
	EndIf

	Local $hStarttime = _Timer_Init()

	; Lets Select The CC Or Siege Machine ; $eCastle , $eWallW , $eBattleB, $eStoneS
	Local $aPaths = [$g_sImgSwitchSiegeCastle, $g_sImgSwitchSiegeWallWrecker, $g_sImgSwitchSiegeBattleBlimp, $g_sImgSwitchSiegeStoneSlammer]
	Local $ToUse = $eCastle, $iDa = 0

	If ($pMatchMode = $DB Or $pMatchMode = $LB Or $pMatchMode = $TS) And Not $bRemaining Then
		; Default is CC ,let's check Siege Machines , if is to be used and exist.
		If $g_abAttackDropCC[$pMatchMode] And $g_aiAttackUseSiege[$pMatchMode] > 0 And $g_aiCurrentCCSiegeMachines[$eSiegeStoneSlammer] > 0 Then
			$ToUse = $eStoneS
			$iDa = 3
		ElseIf $g_abAttackDropCC[$pMatchMode] And $g_aiAttackUseSiege[$pMatchMode] > 0 And $g_aiCurrentCCSiegeMachines[$eSiegeBattleBlimp] > 0 Then
			$ToUse = $eBattleB
			$iDa = 2
		ElseIf $g_abAttackDropCC[$pMatchMode] And $g_aiAttackUseSiege[$pMatchMode] > 0 And $g_aiCurrentCCSiegeMachines[$eSiegeWallWrecker] > 0 Then
			$ToUse = $eWallW
			$iDa = 1
		ElseIf $g_abAttackDropCC[$pMatchMode] And $g_aiAttackUseSiege[$pMatchMode] = 3 And $g_aiCurrentSiegeMachines[$eSiegeStoneSlammer] > 0 Then
			$ToUse = $eStoneS
			$iDa = 3
		ElseIf $g_abAttackDropCC[$pMatchMode] And $g_aiAttackUseSiege[$pMatchMode] = 2 And $g_aiCurrentSiegeMachines[$eSiegeBattleBlimp] > 0 Then
			$ToUse = $eBattleB
			$iDa = 2
		ElseIf $g_abAttackDropCC[$pMatchMode] And $g_aiAttackUseSiege[$pMatchMode] = 1 And $g_aiCurrentSiegeMachines[$eSiegeWallWrecker] > 0 Then
			$ToUse = $eWallW
			$iDa = 1
		Else
			$ToUse = $eCastle
			$iDa = 0
		EndIf

		; Only procceds if necessary Drop the CC troops
		If Not $bRemaining And $g_abAttackDropCC[$pMatchMode] Then
			Setlog("Let's use " & GetTroopName($ToUse))
			If QuickMIS("BC1", $g_sImgSwitchSiegeMachine, 50, 700, 820, 720, True, False) Then
				If $g_bDebugSetlog Then SetDebugLog("Benchmark Switch Siege Bar: " & StringFormat("%.2f", _Timer_Diff($hStarttime)) & "'ms")
				$hStarttime = _Timer_Init()
				Setlog("Switching button in a Siege Machine/CC detected.")
				; Was detectable lets click
				Click($g_iQuickMISX + 50, $g_iQuickMISY + 700, 1)
				; wait to appears the new small window
				Local $lastX = $g_iQuickMISX + 50, $LastX1 = $g_iQuickMISX + 300, $lastY = $g_iQuickMISY + 700
				Local $compFor2Sieges = 50
				If _Sleep(1250) Then Return
				; Lets detect the CC & Sieges and click
				Local $HowMany = QuickMIS("CX", $aPaths[$iDa], $lastX - $compFor2Sieges, 530, $LastX1, 560, True, False)

				If $g_bDebugSetlog Then SetDebugLog("Benchmark Switch Siege HowMany: " & StringFormat("%.2f", _Timer_Diff($hStarttime)) & "'ms")
				If $g_bDebugSetlog Then SetDebugLog("Sleeps : " & 750 & "'ms")
				$hStarttime = _Timer_Init()

				If UBound($HowMany) > 0 Then
					If $DebugSiege Then
						Setlog("SiegeSwitch , Detected array: " & _ArrayToString($HowMany))
						; Create the necessery GDI stuff
						_CaptureRegion2()
						Local $subDirectory = $g_sProfileTempDebugPath & "SiegeSwitch"
						DirCreate($subDirectory)
						Local $Date = @YEAR & "-" & @MON & "-" & @MDAY
						Local $Time = @HOUR & "." & @MIN & "." & @SEC
						Local $filename = String($Date & "_" & $Time & "_" & $iDa & "_.png")
						Local $editedImage = _GDIPlus_BitmapCreateFromHBITMAP($g_hHBitmap2)
						Local $hGraphic = _GDIPlus_ImageGetGraphicsContext($editedImage)
						Local $hPenRED = _GDIPlus_PenCreate(0xFFFF0000, 3) ; Create a pencil Color FF0000/RED
					EndIf

					Local $aSiegeAvailable[0][3] ; [0] : Xaxis , [1] Yaxis , [2] Level

					For $i = 0 To UBound($HowMany) - 1
						Local $Coordinates = StringSplit($HowMany[$i], ",", $STR_NOCOUNT)
						Local $x = $Coordinates[0] + ($lastX - $compFor2Sieges), $y = $Coordinates[1] + 540

						ReDim $aSiegeAvailable[UBound($aSiegeAvailable) + 1][3]
						$aSiegeAvailable[UBound($aSiegeAvailable) - 1][0] = $x
						$aSiegeAvailable[UBound($aSiegeAvailable) - 1][1] = $y
						Local $SiegeLevel = getTroopsSpellsLevel($x - 26, 587)
						; Just in case of Level 1
						$aSiegeAvailable[UBound($aSiegeAvailable) - 1][2] = $SiegeLevel <> "" ? Number($SiegeLevel) : 1

						If $DebugSiege Then
							Local $Info = $i + 1 & "_" & GetTroopName($ToUse) & "_L" & $aSiegeAvailable[UBound($aSiegeAvailable) - 1][2] & "_" & $x & "_" & $y
							addInfoToDebugImage($hGraphic, $hPenRED, $Info, $x, $y)
							_GDIPlus_GraphicsDrawLine($hGraphic, 0, 587, 860, 587, $hPenRED)
							_GDIPlus_GraphicsDrawLine($hGraphic, $x - 26, 0, $x - 26, 732, $hPenRED)
						EndIf
					Next
					If $g_bDebugSetlog Then SetDebugLog("Benchmark Switch Siege Levels: " & StringFormat("%.2f", _Timer_Diff($hStarttime)) & "'ms")
					If $g_bDebugSetlog Then SetDebugLog("Sleeps : " & 0 & "'ms")
					$hStarttime = _Timer_Init()

					Local $iFinalX = 0, $iFinalY = 0, $iFinalLevel = 0

					If UBound($aSiegeAvailable) > 0 Then
						For $i = 0 To UBound($aSiegeAvailable) - 1
							If $aSiegeAvailable[$i][2] > $iFinalLevel Then
								$iFinalX = $aSiegeAvailable[$i][0]
								$iFinalY = $aSiegeAvailable[$i][1]
								$iFinalLevel = $aSiegeAvailable[$i][2]
							EndIf
						Next
						Click($iFinalX, $iFinalY, 1)
						Local $TextLog = $ToUse = $eCastle ? "" : " Level " & $iFinalLevel
						Setlog(GetTroopName($ToUse) & $TextLog & " selected!", $COLOR_SUCCESS)
					Else
						If $g_bDebugImageSave Then DebugImageSave("PrepareAttack_SwitchSiege")
						Click($lastX, $lastY, 1)
					EndIf

					If _sleep(250) Then Return
;~ 					Click(35, 595 + $g_iBottomOffsetY, 1, 0, "#0111") ;860x780 click 1st troop slot

					If $DebugSiege Then
						; Destroy the used GDI stuff
						_GDIPlus_ImageSaveToFile($editedImage, $subDirectory & "\" & $filename)
						_GDIPlus_PenDispose($hPenRED)
						_GDIPlus_GraphicsDispose($hGraphic)
						_GDIPlus_BitmapDispose($editedImage)
					EndIf
				Else
					If $g_bDebugImageSave Then DebugImageSave("PrepareAttack_SwitchSiege")
					; If was not detectable lets click again on green icon to hide the window!
					Setlog("Undetected " & GetTroopName($ToUse) & " after click on switch btn!", $COLOR_DEBUG)
					Click($lastX, $lastY, 1)
					If _sleep(250) Then Return
;~ 					Click(35, 595 + $g_iBottomOffsetY, 1, 0, "#0111") ;860x780 click 1st troop slot
				EndIf
				If _Sleep(750) Then Return
			EndIf
		EndIf
	EndIf
	If $g_bDebugSetlog Then SetDebugLog("Benchmark Switch Siege Detection: " & StringFormat("%.2f", _Timer_Diff($hStarttime)) & "'ms")
	If $g_bDebugSetlog Then SetDebugLog("Sleeps : " & 250 + 750 & "'ms")

	If _Sleep($DELAYPREPAREATTACK1) Then Return

	Local $iTroopNumber = 0
	For $i = 0 To UBound($g_avAttackTroops, 1) - 1
		$g_avAttackTroops[$i][0] = -1
		$g_avAttackTroops[$i][1] = 0
		$g_avAttackTroops[$i][2] = 0
		$g_avAttackTroops[$i][3] = 0
		$g_avAttackTroops[$i][4] = 0
		$g_avAttackTroops[$i][5] = 0
	Next

	Local $avAttackBar = AttackBarCheck($bRemaining, $pMatchMode)
	If UBound($avAttackBar, 1) > 0 Then
		For $i = 0 To UBound($avAttackBar, 1) - 1
			If IsUnitUsed($pMatchMode, $avAttackBar[$i][0]) Then
				$g_avAttackTroops[$avAttackBar[$i][1]][0] = Number($avAttackBar[$i][0]) ; Troop Index
				$g_avAttackTroops[$avAttackBar[$i][1]][1] = Number($avAttackBar[$i][2]) ; Amount
				$g_avAttackTroops[$avAttackBar[$i][1]][2] = Number($avAttackBar[$i][3]) ; X-Coord
				$g_avAttackTroops[$avAttackBar[$i][1]][3] = Number($avAttackBar[$i][4]) ; Y-Coord
				$g_avAttackTroops[$avAttackBar[$i][1]][4] = Number($avAttackBar[$i][5]) ; OCR X-Coord
				$g_avAttackTroops[$avAttackBar[$i][1]][5] = Number($avAttackBar[$i][6]) ; OCR Y-Coord
				$iTroopNumber += $avAttackBar[$i][2]
				Local $sDebugText = $g_bDebugSetlog ? " (X:" & $avAttackBar[$i][3] & "|Y:" & $avAttackBar[$i][4] & "|OCR-X:" & $avAttackBar[$i][5] & "|OCR-Y:" & $avAttackBar[$i][6] & ")" : ""
				SetLog($avAttackBar[$i][1] & ": " & $avAttackBar[$i][2] & " " & GetTroopName($avAttackBar[$i][0], $avAttackBar[$i][2]) & $sDebugText, $COLOR_SUCCESS)
			Else
				SetDebugLog("Discard use of " & GetTroopName($avAttackBar[$i][0]) & " (" & $avAttackBar[$i][0] & ")", $COLOR_ERROR)
			EndIf
		Next
	EndIf
	SetSlotSpecialTroops()

	Return $iTroopNumber
EndFunc   ;==>PrepareAttack

Func IsUnitUsed($iMatchMode, $iTroopIndex)
	Local $iTempMode = ($iMatchMode = $MA ? $DB : $iMatchMode)

	If $iTroopIndex < $eKing Then ;Index is a Troop
		If $iMatchMode = $DT Or $iMatchMode = $TB Then Return True
		Local $aTempArray = $g_aaiTroopsToBeUsed[$g_aiAttackTroopSelection[$iTempMode]]
		Local $iFoundAt = _ArraySearch($aTempArray, $iTroopIndex)
		If $iFoundAt <> -1 Then
			If $iMatchMode = $MA And $iTroopIndex = $eGobl Then
				Return False
			Else
				Return True
			EndIf
		EndIf
		Return False
	Else ; Index is a Hero/Siege/Castle/Spell
		Local $iTempMode = ($iMatchMode = $MA ? $DB : $iMatchMode)

		If $iMatchMode <> $DB And $iMatchMode <> $LB And $iMatchMode <> $TS And $iMatchMode <> $MA Then
			Return True
		Else
			Switch $iTroopIndex
				Case $eKing
					If (BitAND($g_aiAttackUseHeroes[$iTempMode], $eHeroKing) = $eHeroKing) Then Return True
				Case $eQueen
					If (BitAND($g_aiAttackUseHeroes[$iTempMode], $eHeroQueen) = $eHeroQueen) Then Return True
				Case $eWarden
					If (BitAND($g_aiAttackUseHeroes[$iTempMode], $eHeroWarden) = $eHeroWarden) Then Return True
				Case $eCastle
					If $g_abAttackDropCC[$iTempMode] Then Return True
				Case $eLSpell
					If $g_abAttackUseLightSpell[$iTempMode] Or $g_bSmartZapEnable Then Return True
				Case $eHSpell
					If $g_abAttackUseHealSpell[$iTempMode] Then Return True
				Case $eRSpell
					If $g_abAttackUseRageSpell[$iTempMode] Then Return True
				Case $eJSpell
					If $g_abAttackUseJumpSpell[$iTempMode] Then Return True
				Case $eFSpell
					If $g_abAttackUseFreezeSpell[$iTempMode] Then Return True
				Case $ePSpell
					If $g_abAttackUsePoisonSpell[$iTempMode] Then Return True
				Case $eESpell
					If $g_abAttackUseEarthquakeSpell[$iTempMode] = 1 Or $g_bSmartZapEnable Then Return True
				Case $eHaSpell
					If $g_abAttackUseHasteSpell[$iTempMode] Then Return True
				Case $eCSpell
					If $g_abAttackUseCloneSpell[$iTempMode] Then Return True
				Case $eSkSpell
					If $g_abAttackUseSkeletonSpell[$iTempMode] Then Return True
				Case $eBtSpell
					If $g_abAttackUseBatSpell[$iTempMode] Then Return True
				Case $eWallW, $eBattleB, $eStoneS
					If $g_abAttackDropCC[$iTempMode] Then Return True
				Case Else
					Return False
			EndSwitch
			Return False
		EndIf

		Return False
	EndIf
	Return False
EndFunc   ;==>IsUnitUsed

Func AttackRemainingTime($bInitialze = Default)
	If $bInitialze Then
		$g_hAttackTimer = __TimerInit()
		$g_iAttackTimerOffset = Default
		SuspendAndroidTime(True) ; Reset suspend Android time for compensation when Android is suspended
		Return
	EndIf

	Local $iPrepareTime = 29 * 1000

	If $g_iAttackTimerOffset = Default Then

		; now attack is really starting (or it has already after 30 Seconds)

		; set offset
		$g_iAttackTimerOffset = __TimerDiff($g_hAttackTimer) - SuspendAndroidTime()

		If $g_iAttackTimerOffset > $iPrepareTime Then
			; adjust offset by remove "lost" attack time
			$g_iAttackTimerOffset = $iPrepareTime - $g_iAttackTimerOffset
		EndIf

	EndIf

	If Not $bInitialze Then Return

	; Return remaining attack time
	Local $iAttackTime = 3 * 60 * 1000
	Local $iRemaining = $iAttackTime - (__TimerDiff($g_hAttackTimer) - SuspendAndroidTime() - $g_iAttackTimerOffset)
	If $iRemaining < 0 Then Return 0
	Return $iRemaining

EndFunc   ;==>AttackRemainingTime
