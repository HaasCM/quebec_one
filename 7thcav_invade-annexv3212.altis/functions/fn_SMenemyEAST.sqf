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
	_randomPos = [[[getPos sideObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
	_infteamPatrol = [_randomPos, EAST, (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> [INF_TEAMS] call BIS_fnc_selectRandom)] call BIS_fnc_spawnGroup;
	[_infteamPatrol, getPos sideObj, 100] call BIS_fnc_taskPatrol;
				
	[_infteamPatrol] call JB_fnc_downgradeATEquipment;

	[(units _infteamPatrol)] call QS_fnc_setSkill2Side;
	[_infteamPatrol] call SERVER_RegisterDeaths;

	_enemiesArray pushBack _infteamPatrol;

	[units _infteamPatrol] call SERVER_CurateEditableObjects;
};

//---------- SNIPER

for "_x" from 0 to 1 do {
	_randomPos = [getPos sideObj, 500, 100, 20] call BIS_fnc_findOverwatch;
	_smSniperTeam = [_randomPos, EAST, (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OI_SniperTeam")] call BIS_fnc_spawnGroup;
	_smSniperTeam setBehaviour "COMBAT";
	_smSniperTeam setCombatMode "RED";
		
	[(units _smSniperTeam)] call QS_fnc_setSkill3Side;
	[_smSniperTeam] call SERVER_RegisterDeaths;

	_enemiesArray = _enemiesArray + [_smSniperTeam];

	[units _smSniperTeam] call SERVER_CurateEditableObjects;
};
	
//---------- VEHICLE RANDOM
	
_randomPos = [[[getPos sideObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
_SMveh1 = [VEH_TYPES] call BIS_fnc_selectRandom createVehicle _randomPos;
waitUntil {sleep 0.5; !isNull _SMveh1};
[_SMveh1] call JB_fnc_downgradeATInventory;
[_SMveh1, _SMvehPatrol] call BIS_fnc_spawnCrew;
[_SMvehPatrol, getPos sideObj, 75] call BIS_fnc_taskPatrol;
_SMveh1 lock 3;
if (random 1 >= 0.5) then {
	_SMveh1 allowCrewInImmobile true;
};
sleep 0.1;
	
_enemiesArray = _enemiesArray + [_SMveh1];

[[_SMveh1]] call SERVER_CurateEditableObjects;
[units _SMvehPatrol] call SERVER_CurateEditableObjects;
	
//---------- VEHICLE RANDOM	
	
_randomPos = [[[getPos sideObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
_SMveh2 = [VEH_TYPES] call BIS_fnc_selectRandom createVehicle _randomPos;
waitUntil {sleep 0.5; !isNull _SMveh2};
[_SMveh2] call JB_fnc_downgradeATInventory;
[_SMveh2, _SMvehPatrol] call BIS_fnc_spawnCrew;
[_SMvehPatrol, getPos sideObj, 150] call BIS_fnc_taskPatrol;
_SMveh2 lock 3;
if (random 1 >= 0.5) then {
	_SMveh2 allowCrewInImmobile true;
};

[(units _SMvehPatrol)] call QS_fnc_setSkill2Side;
[_SMvehPatrol] call SERVER_RegisterDeaths;

_enemiesArray pushBack _SMveh2;
_enemiesArray pushBack _SMvehPatrol;

[[_SMveh2]] call SERVER_CurateEditableObjects;
[units _SMvehPatrol] call SERVER_CurateEditableObjects;

//---------- VEHICLE AA
	
_randomPos = [[[getPos sideObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
_SMaa = "O_APC_Tracked_02_AA_F" createVehicle _randomPos;
[_SMaa] call JB_fnc_downgradeATInventory;
waitUntil {sleep 0.5; !isNull _SMaa};
[_SMaa, _SMaaPatrol] call BIS_fnc_spawnCrew;
_SMaa lock 3;
if (random 1 >= 0.5) then {
	_SMaa allowCrewInImmobile true;
};
[_SMaaPatrol, getPos sideObj, 150] call BIS_fnc_taskPatrol;

[(units _SMaaPatrol)] call QS_fnc_setSkill4Side;
[_SMaaPatrol] call SERVER_RegisterDeaths;

_enemiesArray = _enemiesArray + [_SMaaPatrol];
sleep 0.1;
_enemiesArray = _enemiesArray + [_SMaa];

[[_SMaa]] call SERVER_CurateEditableObjects;
[units _SMaaPatrol] call SERVER_CurateEditableObjects;

//---------- GARRISON FORTIFICATIONS
	
{
	_newGrp = [_x] call QS_fnc_garrisonFortEAST;
	if (!isNull _newGrp) then
	{ 
		[units _newGrp] call QS_fnc_setSkill2Side;
		[_newGrp] call SERVER_RegisterDeaths;

		[units _newGrp] call SERVER_CurateEditableObjects;

		_enemiesArray pushBack _newGrp;
	};
} forEach (getPos sideObj nearObjects ["House", 150]);
	
_enemiesArray