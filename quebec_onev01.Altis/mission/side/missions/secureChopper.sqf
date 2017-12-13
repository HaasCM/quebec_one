/*
Author:

	Quiksilver

Last modified:

	25/04/2014

Description:

	Destroy chopper
____________________________________*/

#define CHOPPER_TYPE "O_Heli_Attack_02_black_F","O_Heli_Light_02_unarmed_F","B_Heli_Attack_01_F"

//-------------------- FIND SAFE POSITION FOR OBJECTIVE

private _flatPos = [0,0,0];
private _accepted = false;
while {!_accepted} do {
	private _position = [] call BIS_fnc_randomPos;
	_flatPos = _position isFlatEmpty [5,0,0.2,sizeOf "Land_TentHangar_V1_F",0,false];

	while {(count _flatPos) < 2} do {
		_position = [] call BIS_fnc_randomPos;
		_flatPos = _position isFlatEmpty [5,0,0.2,sizeOf "Land_TentHangar_V1_F",0,false];
	};

	if ((_flatPos distance (getMarkerPos "respawn_west")) > 3000 && (_flatPos distance (getMarkerPos currentAO)) > 4000) then
	{
		_accepted = true;
	};
};

private _objPos = [_flatPos, 25, 35, 10, 0, 0.5, 0] call BIS_fnc_findSafePos;

//-------------------- SPAWN OBJECTIVE

_hangar = "Land_TentHangar_V1_F" createVehicle _flatPos;
waitUntil {!isNull _hangar};
_hangar setPos [(getPos _hangar select 0), (getPos _hangar select 1), ((getPos _hangar select 2) - 1)];
sideObj = [CHOPPER_TYPE] call BIS_fnc_selectRandom createVehicle _flatPos;
waitUntil {!isNull sideObj};

private _randomDir = (random 360);
{
	_x setDir _randomDir
} forEach [sideObj, _hangar];
sideObj lock 3;

private _house = "Land_Cargo_House_V3_F" createVehicle _objPos;
_house setDir random 360;
_house allowDamage false;

private _laptop = [research1, research2] call BIS_fnc_selectRandom;
{ _x enableSimulation true } forEach [researchTable,_laptop];
researchTable setPos (_house modelToWorld [0.32,2.87,0.04]);
[researchTable, _laptop, [0,0,0.8]] call BIS_fnc_relPosObject;

//-------------------- SPAWN FORCE PROTECTION

_enemiesArray = [sideObj] call QS_fnc_SMenemyEAST;


//-------------------- BRIEF

_fuzzyPos = [((_flatPos select 0) - 300) + (random 600),((_flatPos select 1) - 300) + (random 600),0];

{ _x setMarkerPos _fuzzyPos; } forEach ["sideMarker", "sideCircle"];
sideMarkerText = "Secure Chopper";
"sideMarker" setMarkerText "Special Operations Mission: Secure Chopper";

_briefing = "<t align='center'><t size='2.2'>Special Operations Mission</t><br/><t size='1.5' color='#00B2EE'>Secure Enemy Chopper</t><br/>____________________<br/>OPFOR forces have been provided with a new prototype attack helicopter and they're keeping it in a hangar somewhere on the island.<br/><br/>We've marked the suspected location on your map; secure the data and trigger the self-destruct on the helicopter.</t>";
[_briefing, getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsHint", 0, false];
["NewSideMission", "Secure Enemy Chopper", getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsNotification", 0, false];
sideMarkerText = "Secure Enemy Chopper";

while { true } do {

	sleep 1;

	if (!alive sideObj) exitWith
	{
		[getPos sideObj, 1000] call QS_fnc_SMhintFAIL;
	};

	if (SM_MissionSucceeded) exitWith
	{
		hqSideChat = "Aircraft self-destruct activated.  Laptop secured.  Detonation in 30 seconds";
		[hqSideChat, getMarkerPos "sideMarker", 1000] remoteExec ["AW_fnc_specialOperationsSideChat",0,false];

		_laptop setPos [-10000,-10000,0];

		sleep 30;

		sideObj setDamage 1;

		[] call QS_fnc_SMhintSUCCESS;
	};
};

{ _x setMarkerPos [-10000,-10000,-10000]; } forEach ["sideMarker", "sideCircle"];

sleep 120;

{ _x setPos [-10000,-10000,0]; } forEach [_laptop, researchTable];
deleteVehicle nearestObject [getPos sideObj, "Land_TentHangar_V1_Ruins_F"];
{ deleteVehicle _x } forEach [sideObj, _house, _hangar];
[_enemiesArray] spawn QS_fnc_SMdelete;