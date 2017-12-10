/*
@file: HQfia.sqf
Author:

	Quiksilver

Last modified:

	24/04/2014

Description:

	Secure HQ supplies before destroying it.
	Enemy type is FIA resistance who are hostile to blufor.

____________________________________*/

private ["_flatPos","_accepted","_position","_enemiesArray","_fuzzyPos","_x","_briefing","_unitsArray","_insurgencySupplies","_SMveh","_SMaa","_tower1","_tower2","_tower3","_c4Message"];

//-------------------- FIND POSITION FOR OBJECTIVE

_flatPos = [0,0,0];
_accepted = false;
while {!_accepted} do {
	_position = [] call BIS_fnc_randomPos;
	_flatPos = _position isFlatEmpty [10,1,0.2,sizeOf "Land_Dome_Small_F",0,false];

	while {(count _flatPos) < 2} do {
		_position = [] call BIS_fnc_randomPos;
		_flatPos = _position isFlatEmpty [10,1,0.2,sizeOf "Land_Dome_Small_F",0,false];
	};

	if ((_flatPos distance (getMarkerPos "respawn_west")) > 3000 && (_flatPos distance (getMarkerPos currentAO)) > 4000) then {
		_accepted = true;
	};
};

//-------------------- SPAWN OBJECTIVE

sideObj = "Land_Cargo_HQ_V2_F" createVehicle _flatPos;
waitUntil {alive sideObj};
sideObj setPos [(getPos sideObj select 0), (getPos sideObj select 1), (getPos sideObj select 2)];
sideObj setVectorUp [0,0,1];

_insurgencySupplies = [crate3, crate4] call BIS_fnc_selectRandom;
_insurgencySupplies setPosASL (lineIntersectsSurfaces [getPosASL sideObj vectorAdd [0,0,1], getPosASL sideObj] select 0 select 0);

_tower1 = [sideObj, 50, 0] call BIS_fnc_relPos;
_tower2 = [sideObj, 50, 120] call BIS_fnc_relPos;
_tower3 = [sideObj, 50, 240] call BIS_fnc_relPos;

tower1 = "Land_Cargo_Patrol_V2_F" createVehicle _tower1;
tower2 = "Land_Cargo_Patrol_V2_F" createVehicle _tower2;
tower3 = "Land_Cargo_Patrol_V2_F" createVehicle _tower3;

tower1 setDir 180;
tower2 setDir 300;
tower3 setDir 60;

{ _x allowDamage false } forEach [tower1,tower2,tower3];
sleep 0.3;

//-------------------- SPAWN FORCE PROTECTION


_enemiesArray = [sideObj] call QS_fnc_SMenemyFIA;


//-------------------- SPAWN BRIEFING

_fuzzyPos = [((_flatPos select 0) - 300) + (random 600),((_flatPos select 1) - 300) + (random 600),0];

{ _x setMarkerPos _fuzzyPos; } forEach ["sideMarker", "sideCircle"];
sideMarkerText = "Secure Insurgency Supply";
"sideMarker" setMarkerText "Special Operations Mission: Secure Insurgency Supply";

_briefing = "<t align='center'><t size='2.2'>Special Operations Mission</t><br/><t size='1.5' color='#00B2EE'>Destroy Insurgency Supply</t><br/>____________________<br/>OPFOR are running an insurgency training facility.<br/><br/>We've marked the position on your map; find and destroy the facility's training supplies.</t>";
[_briefing, getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsHint", 0, false];
["NewSideMission", "Secure Insurgency Supply", getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsNotification", 0, false];
sideMarkerText = "Secure Insurgency Supply";

//-------------------- [ CORE LOOPS ] ------------------------ [ CORE LOOPS ]

while { true } do {

	sleep 1;

	if (!alive sideObj) exitWith
	{
		[getPos sideObj, 1000] call QS_fnc_SMhintFAIL;
	};

	if (SM_MissionSucceeded) exitWith
	{
		hqSideChat = "Charge set on insurgency supplies.  Detonation in 30 seconds";
		[hqSideChat, getMarkerPos "sideMarker", 1000] remoteExec ["AW_fnc_specialOperationsSideChat",0,false];

		sleep 30;

		"Bo_Mk82" createVehicle getPos _insurgencySupplies;
		_insurgencySupplies setPos [-10000,-10000,0];

		[] call QS_fnc_SMhintSUCCESS;
	};
};

{ _x setMarkerPos [-10000,-10000,-10000]; } forEach ["sideMarker", "sideCircle"];
_insurgencySupplies setPos [-10000,-10000,0];

sleep 120;

deleteVehicle nearestObject [_flatPos, "Land_Cargo_HQ_V2_ruins_F"];
{ deleteVehicle _x } forEach [sideObj,tower1,tower2,tower3];
[_enemiesArray] spawn QS_fnc_SMdelete;
