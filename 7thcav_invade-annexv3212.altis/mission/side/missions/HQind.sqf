/*
Author:

	Quiksilver

Last modified:

	24/04/2014

Description:

	Secure HQ supplies before destroying it.

____________________________________*/

//-------------------- FIND POSITION FOR OBJECTIVE

_flatPos = [0,0,0];
_accepted = false;
while {!_accepted} do {
	_position = [] call BIS_fnc_randomPos;
	_flatPos = _position isFlatEmpty [10,1,0.2,sizeOf "Land_Cargo_House_V2_F",0,false];

	while {(count _flatPos) < 2} do {
		_position = [] call BIS_fnc_randomPos;
		_flatPos = _position isFlatEmpty [10,1,0.2,sizeOf "Land_Cargo_House_V2_F",0,false];
	};

	if ((_flatPos distance (getMarkerPos "respawn_west")) > 3000 && (_flatPos distance (getMarkerPos currentAO)) > 4000) then {
		_accepted = true;
	};
};

_flatPos1 = [_flatPos, 15, 50] call BIS_fnc_relPos;
_flatPos2 = [_flatPos, 15, 80] call BIS_fnc_relPos;

//-------------------- SPAWN OBJECTIVE

_objDir = random 360;

sideObj = "Land_Cargo_House_V2_F" createVehicle _flatPos;
waitUntil {alive sideObj};
sideObj setPos [(getPos sideObj select 0), (getPos sideObj select 1), (getPos sideObj select 2)];
sideObj setVectorUp [0,0,1];
sideObj setDir _objDir;

_launchers = [indCrate1, indCrate2] call BIS_fnc_selectRandom;
_launchers setPos (sideObj modelToWorld [0.21,2.81,0.04]);

truck1 = "O_Truck_03_ammo_F" createVehicle _flatPos1;
[truck1] call JB_fnc_downgradeATInventory;
truck2 = "I_Truck_02_ammo_F" createVehicle _flatPos2;
[truck2] call JB_fnc_downgradeATInventory;

{ _x setDir random 360 } forEach [truck1,truck2];
{ _x lock 3 } forEach [truck1,truck2];

//-------------------- SPAWN FORCE PROTECTION

_enemiesArray = [sideObj] call QS_fnc_SMenemyIND;

//-------------------- SPAWN BRIEFING

_fuzzyPos = [((_flatPos select 0) - 300) + (random 600),((_flatPos select 1) - 300) + (random 600),0];
{ _x setMarkerPos _fuzzyPos; } forEach ["sideMarker", "sideCircle"];
sideMarkerText = "Destroy Launchers";
"sideMarker" setMarkerText "Special Operations Mission: Secure Launchers";
_briefing = "<t align='center'><t size='2.2'>Special Operations Mission</t><br/><t size='1.5' color='#00B2EE'>Destroy Launchers</t><br/>____________________<br/>Rogue AAF are supplying OPFOR with advanced weapons including shoulder-fired missile launchers.<br/><br/>We've located the storage facility, which is marked on your map.  Go and destroy those launchers.</t>";
[_briefing, getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsHint", 0, false];
["NewSideMission", "Destroy Launchers", getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsNotification", 0, false];
sideMarkerText = "Destroy Launchers";

while { true } do {

	sleep 1;

	if (!alive sideObj) exitWith
	{
		[getPos sideObj, 1000] call QS_fnc_SMhintFAIL;
	};

	if (SM_MissionSucceeded) exitWith
	{
		hqSideChat = "Charge set on launchers.  Detonation in 30 seconds";
		[hqSideChat, getMarkerPos "sideMarker", 1000] remoteExec ["AW_fnc_specialOperationsSideChat",0,false];

		sleep 30;
		"Bo_Mk82" createVehicle getPos _launchers;

		[] call QS_fnc_SMhintSUCCESS;
	};
};

{ _x setMarkerPos [-10000,-10000,-10000]; } forEach ["sideMarker", "sideCircle"];
_launchers setPos [-10000,-10000,0];

sleep 120;

deleteVehicle nearestObject [_flatPos, "Land_Cargo_House_V2_ruins_F"];
{ deleteVehicle _x } forEach [sideObj, truck1, truck2];
[_enemiesArray] spawn QS_fnc_SMdelete;