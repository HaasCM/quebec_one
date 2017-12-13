/*
@file: HQresearch.sqf
Author:

	Quiksilver

Last modified:

	24/04/2014

Description:

	testing:
		multiplayer testing
		qs_fnc_smenemyeast
____________________________________*/

#define VEH_TYPE "O_MRAP_02_F","O_Truck_03_covered_F","O_Truck_03_transport_F","O_Heli_Light_02_unarmed_F","O_Truck_02_transport_F","O_Truck_02_covered_F","C_SUV_01_F","C_Van_01_transport_F"

//-------------------- FIND POSITION FOR OBJECTIVE

private _flatPos = [0,0,0];
private _accepted = false;
while {!_accepted} do {
	private _position = [] call BIS_fnc_randomPos;
	_flatPos = _position isFlatEmpty [5,1,0.2,sizeOf "Land_Research_HQ_F",0,false];

	while {(count _flatPos) < 2} do {
		_position = [] call BIS_fnc_randomPos;
		_flatPos = _position isFlatEmpty [10,1,0.2,sizeOf "Land_Research_HQ_F",0,false];
	};

	if ((_flatPos distance (getMarkerPos "respawn_west")) > 3000 && (_flatPos distance (getMarkerPos currentAO)) > 4000) then
	{
		_accepted = true;
	};
};

//-------------------- SPAWN OBJECTIVE BUILDING

sideObj = "Land_Research_HQ_F" createVehicle _flatPos;
waitUntil {alive sideObj};
sideObj setPos [(getPos sideObj select 0), (getPos sideObj select 1), (getPos sideObj select 2)];
sideObj setVectorUp [0,0,1];

private _vehicle = [VEH_TYPE] call BIS_fnc_selectRandom createVehicle ([_flatPos, 15, 30, 10, 0, 0.5, 0] call BIS_fnc_findSafePos);
_vehicle lock 3;
[_vehicle] call JB_fnc_downgradeATInventory;

//---------- SPAWN (okay, tp) TABLE, AND LAPTOP ON IT.

private _explosives = [explosivesDummy1, explosivesDummy2] call BIS_fnc_selectRandom;
private _laptop = [research1, research2] call BIS_fnc_selectRandom;
{ _x enableSimulation true } forEach [researchTable, _laptop];
researchTable setPosASL (lineIntersectsSurfaces [getPosASL sideObj vectorAdd [0,0,1], getPosASL sideObj] select 0 select 0);
[researchTable, _laptop, [0,0,0.8]] call BIS_fnc_relPosObject;

//-------------------- SPAWN FORCE PROTECTION

private _enemiesArray = [sideObj] call QS_fnc_SMenemyEAST;

//-------------------- BRIEF

private _fuzzyPos = [((_flatPos select 0) - 300) + (random 600),((_flatPos select 1) - 300) + (random 600),0];

{ _x setMarkerPos _fuzzyPos; } forEach ["sideMarker", "sideCircle"];
sideMarkerText = "Seize Research Data";
"sideMarker" setMarkerText "Special Operations Mission: Seize Research Data";

_briefing = "<t align='center'><t size='2.2'>Special Operations Mission</t><br/><t size='1.5' color='#00B2EE'>Seize Research Data</t><br/>____________________<br/>OPFOR are conducting advanced military research on Altis.<br/><br/>Secure the data and destroy the facility.</t>";
[_briefing, getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsHint", 0, false];
["NewSideMission", "Seize Research Data", getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsNotification", 0, false];
sideMarkerText = "Seize Research Data";

//-------------------- [ CORE LOOPS ] ------------------------

while { true } do {

	sleep 1;

	if (!alive sideObj) exitWith
	{
		[getPos sideObj, 1000] call QS_fnc_SMhintFAIL;
	};

	if (SM_MissionSucceeded) exitWith {

		hqSideChat = "Laptop secured.  Charge set on facility.  Detonation in 30 seconds";
		[hqSideChat, getMarkerPos "sideMarker", 1000] remoteExec ["AW_fnc_specialOperationsSideChat",0,false];

		_explosives setPos [(getPos sideObj select 0), (getPos sideObj select 1), ((getPos sideObj select 2) + 2)];
		_laptop setPos [-10000,-10000,0];

		sleep 30;

		"Bo_Mk82" createVehicle getPos _explosives;
		_explosives setPos [-10000,-10000,1];

		[] call QS_fnc_SMhintSUCCESS;
	};
};

{ _x setMarkerPos [-10000,-10000,-10000]; } forEach ["sideMarker", "sideCircle"];
{ _x setPos [-10000,-10000,0]; } forEach [_laptop, researchTable, _explosives];

sleep 120;

deleteVehicle nearestObject [_flatPos, "Land_Research_HQ_ruins_F"];
{ deleteVehicle _x } forEach [sideObj, _vehicle];
[_enemiesArray] spawn QS_fnc_SMdelete;
