/*
@filename: fn_conditionUAVSoftware.sqf
Author:
	
	Quiksilver
	
Last modified:

	23/10/2014 ArmA 1.32 by Quiksilver
	
Description:

	condition for loading UAV crew
______________________________________________*/

private ["_c","_t","_type"];

private _c = false;
private _t = cursorTarget;

if ((player distance _t) < 3) then {
	if (unitIsUAV _t) then {
		_c = true;
	};
};
_c;
