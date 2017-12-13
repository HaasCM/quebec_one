/*
Author: 

	Quiksilver
	
Last modified:

	25/04/2014

Description:

	Spawn INDEPENDENT enemy around side objectives.
	Enemy should have backbone AA/AT + random composition.
	
___________________________________________*/

//---------- CONFIG

#define INF_TEAMS "HAF_InfTeam","HAF_InfTeam_AT","HAF_InfSentry","HAF_InfSquad"
#define VEH_TYPES "I_APC_Wheeled_03_cannon_F","I_APC_tracked_03_cannon_F","I_MBT_03_cannon_F","I_MRAP_03_hmg_F"
private ["_x","_pos","_flatPos","_randomPos","_unitsArray","_enemiesArray","_infteamPatrol","_SMvehPatrol","_SMveh","_SMaaPatrol","_SMaa","_indSniperTeam"];
_enemiesArray = [grpNull];
_x = 0;

//---------- CREATE GROUPS

_infteamPatrol = createGroup east;
_indSniperTeam = createGroup east;
_SMvehPatrol = createGroup east;
_SMaaPatrol = createGroup east;

//---------- INFANTRY

for "_x" from 0 to (2 + (random 4)) do {
	_randomPos = [[[getPos sideObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
	_infteamPatrol = [_randomPos, EAST, (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> [INF_TEAMS] call BIS_fnc_selectRandom)] call BIS_fnc_spawnGroup;
	[_infteamPatrol, getPos sideObj, 100] call BIS_fnc_taskPatrol;

	[_infteamPatrol] call JB_fnc_downgradeATEquipment;

	[units _infteamPatrol] call QS_fnc_setSkill2Side;
	[_infteamPatrol] call SERVER_RegisterDeaths;

	_enemiesArray pushBack _infteamPatrol;

	[units _infteamPatrol] call SERVER_CurateEditableObjects;
};

//---------- SNIPER

for "_x" from 0 to 1 do {
	_randomPos = [getPos sideObj, 500, 100, 20] call BIS_fnc_findOverwatch;
	_indSniperTeam = [_randomPos, EAST, (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_SniperTeam")] call BIS_fnc_spawnGroup;
	_indSniperTeam setBehaviour "COMBAT";
	_indSniperTeam setCombatMode "RED";

	[units _indSniperTeam] call QS_fnc_setSkill3Side;
	[_indSniperTeam] call SERVER_RegisterDeaths;
	
	_enemiesArray = _enemiesArray + [_indSniperTeam];

	[units _indSniperTeam] call SERVER_CurateEditableObjects;
};

//---------- RANDOM VEHICLE

_randomPos = [[[getPos sideObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
_SMveh = [VEH_TYPES] call BIS_fnc_selectRandom createVehicle _randomPos;
waitUntil {sleep 0.5; !isNull _SMveh};

[_SMveh] call JB_fnc_downgradeATInventory;

"O_engineer_F" createUnit [_randomPos,_SMvehPatrol];
"O_engineer_F" createUnit [_randomPos,_SMvehPatrol];
"O_engineer_F" createUnit [_randomPos,_SMvehPatrol];
((units _SMvehPatrol) select 0) assignAsDriver _SMveh;
((units _SMvehPatrol) select 1) assignAsGunner _SMveh;
((units _SMvehPatrol) select 2) assignAsCommander _SMveh;
((units _SMvehPatrol) select 0) moveInDriver _SMveh;
((units _SMvehPatrol) select 1) moveInGunner _SMveh;
((units _SMvehPatrol) select 2) moveInCommander _SMveh;
	
_SMveh lock 3;
[_SMvehPatrol, getPos sideObj, 150] call BIS_fnc_taskPatrol;
if (random 1 >= 0.5) then {
	_SMveh allowCrewInImmobile true;
};
	
[units _SMvehPatrol] call QS_fnc_setSkill2Side;
[_SMvehPatrol] call SERVER_RegisterDeaths;

_enemiesArray = _enemiesArray + [_SMvehPatrol];
sleep 0.1;
_enemiesarray = _enemiesArray + [_SMveh];

[[_SMveh]] call SERVER_CurateEditableObjects;
[units _SMvehPatrol] call SERVER_CurateEditableObjects;

//---------- AA VEHICLE

for "_x" from 0 to 1 do {
	_randomPos = [[[getPos sideObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
	_SMaa = "O_APC_Tracked_02_AA_F" createVehicle _randomPos;
	waitUntil {sleep 0.5; !isNull _SMaa};
	[_SMaa] call JB_fnc_downgradeATInventory;
	[_SMaa, _SMaaPatrol] call BIS_fnc_spawnCrew;
	
	_SMaa lock 3;
	[_SMaaPatrol, getPos sideObj, 150] call BIS_fnc_taskPatrol;
	if (random 1 >= 0.5) then {
		_SMaa allowCrewInImmobile true;
	};

	[units _SMaaPatrol] call QS_fnc_setSkill4Side;
	[_SMaaPatrol] call SERVER_RegisterDeaths;

	_enemiesArray = _enemiesArray + [_SMaaPatrol];
	sleep 0.1;
	_enemiesArray = _enemiesArray + [_SMaa];

	[[_SMaa]] call SERVER_CurateEditableObjects;
	[units _SMaaPatrol] call SERVER_CurateEditableObjects;
};

//---------- GARRISON FORTIFICATIONS

{
	_newGrp = [_x] call QS_fnc_garrisonFortIND;
	if (!isNull _newGrp) then
	{
		_enemiesArray = _enemiesArray + [_newGrp];
		[_newGrp] call SERVER_RegisterDeaths;
		[units _newGrp] call SERVER_CurateEditableObjects;
	};
} forEach (getPos sideObj nearObjects ["House", 150]);

_enemiesArray