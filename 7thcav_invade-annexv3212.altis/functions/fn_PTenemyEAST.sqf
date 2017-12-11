/*
Author: 

	Quiksilver
	
Last modified:

	25/04/2014

Description:

	Spawn OPFOR enemy around side objectives.
	Enemy should have backbone AA/AT + random composition.
	
___________________________________________*/

//---------- CONFIG

#define INF_TEAMS "OIA_InfTeam","OIA_InfTeam_AT","OI_reconPatrol","OIA_GuardTeam"
#define VEH_TYPES "O_MBT_02_cannon_F","O_APC_Tracked_02_cannon_F","O_APC_Wheeled_02_rcws_F","O_MRAP_02_hmg_F","O_APC_Tracked_02_AA_F"
private ["_x","_pos","_flatPos","_randomPos","_enemiesArray","_infteamPatrol","_SMvehPatrol","_SMveh","_SMaaPatrol","_SMaa","_smSniperTeam"];
_enemiesArray = [grpNull];
_x = 0;

//---------- GROUPS
	
_infteamPatrol = createGroup east;
_smSniperTeam = createGroup east;
_SMvehPatrol = createGroup east;
_SMaaPatrol = createGroup east;

SM_Dead = [];

//---------- INFANTRY RANDOM
	
for "_x" from 0 to (3 + (random 4)) do {
	_randomPos = [[[getPos priorityObj1, 300],[]],["water","out"]] call BIS_fnc_randomPos;
	_infteamPatrol = [_randomPos, EAST, (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> [INF_TEAMS] call BIS_fnc_selectRandom)] call BIS_fnc_spawnGroup;
	[_infteamPatrol, getPos priorityObj1, 100] call BIS_fnc_taskPatrol;
				
	[_infteamPatrol] call SERVER_RegisterDeaths;

	[_infteamPatrol] call JB_fnc_downgradeATEquipment;
	[units _infteamPatrol] call SERVER_CurateEditableObjects;

	_enemiesArray pushBack _infteamPatrol;
};

//---------- SNIPER

for "_x" from 0 to 1 do {
	_randomPos = [getPos priorityObj1, 500, 100, 20] call BIS_fnc_findOverwatch;
	_smSniperTeam = [_randomPos, EAST, (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OI_SniperTeam")] call BIS_fnc_spawnGroup;
	_smSniperTeam setBehaviour "COMBAT";
	_smSniperTeam setCombatMode "RED";

	[_smSniperTeam] call SERVER_RegisterDeaths;

	[units _smSniperTeam] call SERVER_CurateEditableObjects;

	_enemiesArray = _enemiesArray + [_smSniperTeam];
};
	
//---------- VEHICLE RANDOM
	
_randomPos = [[[getPos priorityObj1, 300],[]],["water","out"]] call BIS_fnc_randomPos;
_SMveh1 = [VEH_TYPES] call BIS_fnc_selectRandom createVehicle _randomPos;
waitUntil {sleep 0.5; !isNull _SMveh1};
[_SMveh1] call JB_fnc_downgradeATInventory;
[_SMveh1, _SMvehPatrol] call BIS_fnc_spawnCrew;

_SMveh1 lock 3;
[_SMvehPatrol, getPos priorityObj1, 75] call BIS_fnc_taskPatrol;

[_SMvehPatrol] call SERVER_RegisterDeaths;

[[_SMveh1] + (units _SMvehPatrol)] call SERVER_CurateEditableObjects;
	
_enemiesArray = _enemiesArray + [_SMveh1];
	
//---------- VEHICLE RANDOM	
	
_randomPos = [[[getPos priorityObj1, 300],[]],["water","out"]] call BIS_fnc_randomPos;
_SMveh2 = [VEH_TYPES] call BIS_fnc_selectRandom createVehicle _randomPos;
waitUntil {sleep 0.5; !isNull _SMveh2};
[_SMveh2] call JB_fnc_downgradeATInventory;
[_SMveh2, _SMvehPatrol] call BIS_fnc_spawnCrew;

_SMveh2 lock 3;
[_SMvehPatrol, getPos priorityObj1, 150] call BIS_fnc_taskPatrol;

[_SMvehPatrol] call SERVER_RegisterDeaths;

[[_SMveh2] + (units _SMvehPatrol)] call SERVER_CurateEditableObjects;

_enemiesArray = _enemiesArray + [_SMveh2];
_enemiesArray = _enemiesArray + [_SMvehPatrol];

//---------- VEHICLE AA
	
_randomPos = [[[getPos priorityObj1, 300],[]],["water","out"]] call BIS_fnc_randomPos;
_SMaa = "O_APC_Tracked_02_AA_F" createVehicle _randomPos;
waitUntil {sleep 0.5; !isNull _SMaa};
[_SMaa] call JB_fnc_downgradeATInventory;
[_SMaa, _SMaaPatrol] call BIS_fnc_spawnCrew;

_SMaa lock 3;
[_SMaaPatrol, getPos priorityObj1, 150] call BIS_fnc_taskPatrol;
	
[_SMaaPatrol] call SERVER_RegisterDeaths;

[[_SMaa] + (units _SMaaPatrol)] call SERVER_CurateEditableObjects;

_enemiesArray = _enemiesArray + [_SMaaPatrol];
_enemiesArray = _enemiesArray + [_SMaa];

//---------- COMMON

[(units _infteamPatrol)] call QS_fnc_setSkill2;
[(units _smSniperTeam)] call QS_fnc_setSkill3;
[(units _SMaaPatrol)] call QS_fnc_setSkill4;
[(units _SMvehPatrol)] call QS_fnc_setSkill2;
	
//---------- GARRISON FORTIFICATIONS
	
	{
		_newGrp = [_x] call QS_fnc_garrisonFortEAST;
		if (!isNull _newGrp) then
		{ 
			[_newGrp] call SERVER_RegisterDeaths;

			[units _newGrp] call SERVER_CurateEditableObjects;

			_enemiesArray = _enemiesArray + [_newGrp];
		};
	} forEach (getPos priorityObj1 nearObjects ["House", 150]);
	
_enemiesArray