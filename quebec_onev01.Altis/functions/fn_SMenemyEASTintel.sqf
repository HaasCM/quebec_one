/*
@filename: QS_fnc_SMenemyEASTintel.sqf
Author: 

	Quiksilver
	
Last modified:

	25/04/2014

Description:

	Spawn OPFOR enemy around intel objectives
	Enemy should have backbone AA/AT + random composition.
	Smaller number of enemy due to more complex objective.
	
___________________________________________*/

//---------- CONFIG
#define INF_TEAMS "OIA_InfTeam","OIA_InfTeam_AT","OI_reconPatrol","OIA_GuardTeam"
#define VEH_TYPES "O_MRAP_02_hmg_F","O_APC_Tracked_02_cannon_F"
private ["_x","_pos","_flatPos","_randomPos","_unitsArray","_enemiesArray","_infteamPatrol","_SMvehPatrol","_SMveh","_SMaaPatrol","_SMaa"];
_enemiesArray = [grpNull];
_x = 0;

SM_Dead = [];

//---------- INFANTRY

for "_x" from 0 to (1 + (random 3)) do {
	_infteamPatrol = createGroup east;
	_randomPos = [[[getPos _intelObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
	_infteamPatrol = [_randomPos, EAST, (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> [INF_TEAMS] call BIS_fnc_selectRandom)] call BIS_fnc_spawnGroup;
	[_infteamPatrol, getPos _intelObj, 100] call BIS_fnc_taskPatrol;
	[(units _infteamPatrol)] call QS_fnc_setSkill2Side;
				
	[_infteamPatrol] call JB_fnc_downgradeATEquipment;
	[_infteamPatrol] call SERVER_RegisterDeaths;

	_enemiesArray pushBack _infteamPatrol;

	[units _infteamPatrol] call SERVER_CurateEditableObjects;
};

//---------- RANDOM VEHICLE

_SMvehPatrol = createGroup east;
_randomPos = [[[getPos _intelObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
_SMveh = [VEH_TYPES] call BIS_fnc_selectRandom createVehicle _randomPos;
[_SMveh] call JB_fnc_downgradeATInventory;
waitUntil {sleep 0.5; !isNull _SMveh};
[_SMveh, _SMvehPatrol] call BIS_fnc_spawnCrew;
[_SMvehPatrol, getPos _intelObj, 150] call BIS_fnc_taskPatrol;
[(units _SMvehPatrol)] call QS_fnc_setSkill2Side;
_SMveh lock 3;
if (random 1 >= 0.5) then {
	_SMveh allowCrewInImmobile true;
};
	
_enemiesArray = _enemiesArray + [_SMvehPatrol];
sleep 0.1;
_enemiesArray = _enemiesArray + [_SMveh];

[_SMvehPatrol] call SERVER_RegisterDeaths;

[[_SMveh]] call SERVER_CurateEditableObjects;
[units _SMvehPatrol] call SERVER_CurateEditableObjects;

_enemiesArray