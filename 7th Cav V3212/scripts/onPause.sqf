/*
@filename: onPauseScript.sqf
Author: 

	Quiksilver
	
Last modified:

	07/28/2016 
	Arma version 1.62
	by SkyeGuy
	
Description:

	Executed when player opens the pause menu.
__________________________________________________*/

disableSerialization;
_0 = (findDisplay 49) displayCtrl 122; _0 ctrlEnable FALSE;