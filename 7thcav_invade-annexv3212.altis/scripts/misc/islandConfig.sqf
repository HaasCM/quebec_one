/*
@filename: islandConfig.sqf
Author:

	Quiksilver
	Last modified 24/10/2014 ArmA 1.30 by Quiksilver (took some of the unused crap out)
Notes:

	WIP

______________________________________________________________________*/

_urbanMarkers =["sm1","sm2","sm3","sm4","sm5","sm6","sm7","sm8","sm9","sm10","sm11","sm12","sm13","sm14","sm15","sm16","sm17","sm18","sm19"];
{_x setMarkerAlpha 0;} count _urbanMarkers;

//crossroad disableAI "ANIM";
SHK_fnc_buildingPos02 = compileFinal preprocessFileLineNumbers "functions\SHK_buildingpos02.sqf";

enemyCasArray = [];
enemyCasGroup = objNull;
