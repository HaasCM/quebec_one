/*
@filename: fn_actionUAVSoftware.sqf
Author:

	Quiksilver
	
Last modified:

	23/10/2014 ArmA 1.32 by Quiksilver
	
Description:

	Re-load UAV software
___________________________________________*/

private _t = cursorTarget;

if (unitIsUAV _t) then
{
	hintSilent "Uploading new software...";

	{
		deleteVehicle _x;
	} forEach (crew _t);

	[[player, "AinvPercMstpSrasWrflDnon_Putdown_AmovPercMstpSrasWrflDnon"], "QS_fnc_switchMoveMP", nil, false] spawn BIS_fnc_MP;

	[_t] spawn
	{
		_t = _this select 0;
		[(crew _t)] call QS_fnc_setSkill4Side;
		createVehicleCrew _t;
		sleep 4;
		hintSilent "Software upload complete";
		sleep 2;
		hintSilent "";
	};
};