/*
@file: destroyRadar.sqf
Author:

	Quiksilver

Last modified:

	25/04/2014

Description:

	Get radar telemetry from enemy radar site, then destroy it.
_________________________________________________________________________*/

//-------------------- FIND SAFE POSITION FOR OBJECTIVE

_flatPos = [0,0,0];
_accepted = false;
while {!_accepted} do {
	_position = [] call BIS_fnc_randomPos;
	_flatPos = _position isFlatEmpty [5,0,0.1,sizeOf "Land_Radar_Small_F",0,false];

	while {(count _flatPos) < 2} do {
		_position = [] call BIS_fnc_randomPos;
		_flatPos = _position isFlatEmpty [5,0,0.1,sizeOf "Land_Radar_Small_F",0,false];
	};

	if ((_flatPos distance (getMarkerPos "respawn_west")) > 3000 && (_flatPos distance (getMarkerPos currentAO)) > 4000) then
	{
		_accepted = true;
	};
};

//-------------------- SPAWN OBJECTIVE

sideObj = "Land_Radar_Small_F" createVehicle _flatPos;
waitUntil {!isNull sideObj};
sideObj setDir random 360;

private _housePosition = [_flatPos, 15, 30, 10, 0, 0.5, 0] call BIS_fnc_findSafePos;

private _house = "Land_Cargo_House_V3_F" createVehicle _housePosition;
_house setDir random 360;
_house allowDamage false;

private _explosives = [explosivesDummy1, explosivesDummy2] call BIS_fnc_selectRandom;
private _laptop = [research1, research2] call BIS_fnc_selectRandom;

researchTable setPos (_house modelToWorld [0.32,2.87,0.04]);
[researchTable, _laptop, [0,0,0.8]] call BIS_fnc_relPosObject;
{ _x enableSimulation true; } forEach [researchTable, _laptop];

private _tower1 = "Land_Cargo_Patrol_V3_F" createVehicle ([sideObj, 50, 0] call BIS_fnc_relPos);
private _tower2 = "Land_Cargo_Patrol_V3_F" createVehicle ([sideObj, 50, 120] call BIS_fnc_relPos);
private _tower3 = "Land_Cargo_Patrol_V3_F" createVehicle ([sideObj, 50, 240] call BIS_fnc_relPos);

_tower1 setDir 180;
_tower2 setDir 300;
_tower3 setDir 60;

{ _x allowDamage false } forEach [_tower1,_tower2,_tower3];

//-------------------- SPAWN FORCE PROTECTION

private _enemiesArray = [sideObj] call QS_fnc_SMenemyEAST;

//-------------------- BRIEF

private _fuzzyPos = [((_flatPos select 0) - 300) + (random 600),((_flatPos select 1) - 300) + (random 600),0];

{ _x setMarkerPos _fuzzyPos; } forEach ["sideMarker", "sideCircle"];
sideMarkerText = "Secure Radar"; publicVariable "sideMarkerText";
"sideMarker" setMarkerText "Special Operations Mission: Secure Radar"; publicVariable "sideMarker";
publicVariable "sideObj";

private _briefing = "<t align='center'><t size='2.2'>Special Operations Mission</t><br/><t size='1.5' color='#00B2EE'>Secure Radar</t><br/>____________________<br/>OPFOR have captured a small radar on the island to support their aircraft.<br/><br/>We've marked the position on your map; head over there and secure the site. Take the data and destroy the facility.</t>";
[_briefing, getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsHint", 0, false];
["NewSideMission", "Secure Radar", getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsNotification", 0, false];
sideMarkerText = "Secure Radar"; publicVariable "sideMarkerText";

while { true } do {

	sleep 1;

	if (!alive sideObj) exitWith
	{
		[getPos sideObj, 1000] call QS_fnc_SMhintFAIL;
	};

	if (SM_MissionSucceeded) exitWith
	{
		hqSideChat = "Charge set on radar dome.  Detonation in 30 seconds";
		[hqSideChat, getMarkerPos "sideMarker", 1000] remoteExec ["AW_fnc_specialOperationsSideChat",0,false];

		_explosives setPos [(getPos sideObj select 0), ((getPos sideObj select 1) +5), ((getPos sideObj select 2) + 0.5)];
		_laptop setPos [-10000,-10000,0];

		sleep 30;

		"Bo_Mk82" createVehicle getPos _explosives;
		_explosives setPos [-10000,-10000,1];

		[] call QS_fnc_SMhintSUCCESS;
	};
};

{ _x setMarkerPos [-10000,-10000,-10000]; } forEach ["sideMarker", "sideCircle"]; publicVariable "sideMarker";
{ _x setPos [-10000,-10000,0]; } forEach [_laptop, researchTable, _explosives];

sleep 120;

deleteVehicle nearestObject [_flatPos, "Land_Radar_Small_ruins_F"];
{ deleteVehicle _x } forEach [sideObj, _house, _tower1, _tower2, _tower3];
[_enemiesArray] spawn QS_fnc_SMdelete;
