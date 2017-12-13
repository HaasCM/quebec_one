/*
Author:

	Quiksilver
	Rarek [AW]

Last modified:

	24/04/2014

Description:

	Not done with this, want to get the Commanders gun firing, and some other stuff.

__________________________________________________________________________*/

private ["_flatPos","_accepted","_position","_flatPos1","_flatPos2","_flatPos3","_PTdir","_unitsArray","_priorityGroup","_distance","_dir","_c","_pos","_barrier","_enemiesArray","_target","_targetPos","_firingMessages","_fuzzyPos","_briefing","_completeText","_priorityMan1","_priorityMan2"];

//-------------------- 1. FIND POSITION

_flatPos = [0,0,0];
_accepted = false;
while {!_accepted} do {
	_position = [[[getMarkerPos currentAO,2500]],["water","out"]] call BIS_fnc_randomPos;
	_flatPos = _position isFlatEmpty [5, 0, 0.2, 5, 0, false];

	while {(count _flatPos) < 2} do {
		_position = [[[getMarkerPos currentAO,2500]],["water","out"]] call BIS_fnc_randomPos;
		_flatPos = _position isFlatEmpty [5, 0, 0.2, 5, 0, false];
	};

	if ((_flatPos distance (getMarkerPos "respawn_west")) > 3000 && (_flatPos distance (getMarkerPos currentAO)) > 900) then
	{
		_accepted = true;
	};
};

_flatPos1 = [(_flatPos select 0) - 2, (_flatPos select 1) - 2, (_flatPos select 2)];
_flatPos2 = [(_flatPos select 0) + 2, (_flatPos select 1) + 2, (_flatPos select 2)];
_flatPos3 = [(_flatPos select 0) + 20, (_flatPos select 1) + random 20, (_flatPos select 2)];

//-------------------- 2. SPAWN OBJECTIVES

_PTdir = random 360;

sleep 0.3;

priorityObj1 = "O_MBT_02_arty_F" createVehicle _flatPos1;
waitUntil {!isNull priorityObj1};
priorityObj1 setDir _PTdir;

sleep 0.3;

priorityObj2 = "O_MBT_02_arty_F" createVehicle _flatPos2;
waitUntil {!isNull priorityObj2};
priorityObj2 setDir _PTdir;

sleep 0.3;

priorityObj1 addEventHandler ["Fired", { _this call PRIORITY_ReloadArtilleryWeapon }];
priorityObj2 addEventHandler ["Fired", { _this call PRIORITY_ReloadArtilleryWeapon }];

//----- SPAWN AMMO TRUCK (for ambiance and plausibiliy of unlimited ammo)

ammoTruck = "O_Truck_03_ammo_F" createVehicle _flatPos3;
waitUntil {!isNull ammoTruck};
ammoTruck setDir random 360;

[ammoTruck] call JB_fnc_downgradeATInventory;

{_x lock 3;_x allowCrewInImmobile true; } forEach [priorityObj1,priorityObj2,ammoTruck];

//-------------------- 3. SPAWN CREW

sleep 1;

_unitsArray = [objNull];

_priorityGroup = createGroup east;

"O_officer_F" createUnit [_flatPos, _priorityGroup];
"O_officer_F" createUnit [_flatPos, _priorityGroup];
"O_engineer_F" createUnit [_flatPos, _priorityGroup];
"O_engineer_F" createUnit [_flatPos, _priorityGroup];

priorityGunner1 = ((units _priorityGroup) select 2);
priorityGunner2 = ((units _priorityGroup) select 3);

((units _priorityGroup) select 0) assignAsCommander priorityObj1;
((units _priorityGroup) select 0) moveInCommander priorityObj1;
((units _priorityGroup) select 1) assignAsCommander priorityObj2;
((units _priorityGroup) select 1) moveInCommander priorityObj2;
((units _priorityGroup) select 2) assignAsGunner priorityObj1;
((units _priorityGroup) select 2) moveInGunner priorityObj1;
((units _priorityGroup) select 3) assignAsGunner priorityObj2;
((units _priorityGroup) select 3) moveInGunner priorityObj2;

[(units _priorityGroup)] call QS_fnc_setSkill4;
_priorityGroup setBehaviour "COMBAT";
_priorityGroup setCombatMode "RED";
_priorityGroup allowFleeing 0;

_unitsArray = _unitsArray + [_priorityGroup];

[_priorityGroup] call SERVER_RegisterDeaths;
[[priorityObj1, priorityObj2, ammoTruck] + (units _priorityGroup)] call SERVER_CurateEditableObjects;

//-------------------- 4. SPAWN H-BARRIER RING

sleep 1;

_distance = 16;
_dir = 0;
for "_c" from 0 to 7 do {
	_pos = [_flatPos, _distance, _dir] call BIS_fnc_relPos;
	_barrier = "Land_HBarrierBig_F" createVehicle _pos;
	waitUntil {alive _barrier};
	_barrier setDir _dir;
	_dir = _dir + 45;
	_barrier allowDamage false;
	_barrier enableSimulation false;

	_unitsArray = _unitsArray + [_barrier];
};

//-------------------- 5. SPAWN FORCE PROTECTION

sleep 1;

_enemiesArray = [priorityObj1] call QS_fnc_PTenemyEAST;

{
	if (typeName _x == typeName objNull && { _x isKindOf "O_APC_Tracked_02_AA_F" }) then
	{
		_x addEventHandler ["Fired", { _this call PRIORITY_ReloadAAWeapon }];
	};
} forEach _enemiesArray;

//-------------------- 7. BRIEF

_fuzzyPos = [((_flatPos select 0) - 300) + (random 600),((_flatPos select 1) - 300) + (random 600),0];
{ _x setMarkerPos _fuzzyPos; } forEach ["priorityMarker", "priorityCircle"];

priorityTargetText = "Artillery";
"priorityMarker" setMarkerText "Priority Target: Artillery";

_briefing = "<t align='center' size='2.2'>Priority Target</t><br/><t size='1.5' color='#b60000'>Artillery</t><br/>____________________<br/>OPFOR forces are setting up an artillery battery.  Intel has picked up their positions with thermal imaging scans and have marked it on your map.<br/><br/>This is a priority target.";
[_briefing] remoteExec ["AW_fnc_globalHint",0,false];
["NewPriorityTarget", "Destroy Artillery"] remoteExec ["AW_fnc_globalNotification",0,false];

_firingMessages = [
	"Thermal scans have detected enemy artillery firing.",
	"Enemy artillery rounds inbound. Seek cover.",
	"Enemy artillery is zeroing in"
];

SM_FireMission =
{
	private _vehicle = _this select 0;
	private _numberRounds = _this select 1;
	private _targetPosition = _this select 2;

	private _distance = _vehicle distance _targetPosition;

	private _roundsFired = 0;
	while { canFire _vehicle && _roundsFired < _numberRounds } do
	{
		sleep (random 2);

		_vehicle doArtilleryFire [_targetPosition, "32Rnd_155mm_Mo_shells", 1];

		sleep 8;
		
		_roundsFired = _roundsFired + 1;
	};
};

private _minRangeSqr = 850 * 850;
private _maxRangeSqr = 5000 * 5000;
private _minRangeFromBaseSqr = 1000 * 1000;

private _timeout = diag_tickTime + (60 + random 120);
waitUntil { sleep 1; diag_tickTime > _timeout || (not canFire priorityObj1 and not canFire priorityObj2) };

while { canFire priorityObj1 || canFire priorityObj2 } do
{
	_target = objNull;

	private _timeout = diag_tickTime + (60 + random 60);
	waitUntil { sleep 1; diag_tickTime > _timeout || (not canFire priorityObj1 and not canFire priorityObj2) };

	while { isNull _target and (canFire priorityObj1 || canFire priorityObj2) } do
	{
		private _targets = playableUnits select { (_x distanceSqr (getMarkerPos "respawn_west")) > _minRangeFromBaseSqr && (_x distanceSqr _flatPos1) > _minRangeSqr && (_x distanceSqr _flatPos1) < _maxRangeSqr && vehicle _x == _x && side _x == west };

		if (count _targets > 0) then
		{
			_target = _targets select (floor random count _targets);
		};

		sleep 3;
	};

	if (PARAMS_ArtilleryTargetTickWarning == 1) then
	{
		hqSideChat = _firingMessages call BIS_fnc_selectRandom;
		[hqSideChat] remoteExec ["AW_fnc_globalSideChat",0,false];
	};

	sleep 5;

	private _locationReportImprecision = 60;
	private _fireOnPosition = getPos _target vectorAdd [-_locationReportImprecision + random (2 * _locationReportImprecision), -_locationReportImprecision + random (2 * _locationReportImprecision), 0];

	private _fireMission1 = [priorityObj1, 4, _fireOnPosition] spawn SM_FireMission;
	private _fireMission2 = [priorityObj2, 4, _fireOnPosition] spawn SM_FireMission;

	waitUntil { sleep 1; scriptDone _fireMission1 && scriptDone _fireMission2 };
};

//-------------------- DE-BRIEF

SM_MissionSucceeded = true; publicVariable "SM_MissionSucceeded";

_completeText = "<t align='center' size='2.2'>Priority Target</t><br/><t size='1.5' color='#08b000'>NEUTRALISED</t><br/>____________________<br/>Well done<br/><br/>Continue assault on main objective.";
[_completeText] remoteExec ["AW_fnc_globalHint",0,false];
["CompletedPriorityTarget", "Enemy Artillery Neutralised"] remoteExec ["AW_fnc_globalNotification",0,false];

//-------------------- DELETE

sleep 120;
{ _x setMarkerPos [-10000,-10000,-10000] } forEach ["priorityMarker","priorityCircle"];
{ [_x] spawn QS_fnc_SMdelete } forEach [_enemiesArray,_unitsArray];
{ deleteVehicle _x } forEach [priorityObj1,priorityObj2,ammoTruck];
