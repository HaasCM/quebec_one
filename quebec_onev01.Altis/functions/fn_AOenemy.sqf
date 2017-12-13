/*
@file: QS_fnc_AOenemy.sqf
Author:

	Quiksilver (credits: Ahoyworld.co.uk. Rarek et al for AW_fnc_spawnUnits.)
	
Last modified:

		24/10/2014 ArmA 1.32 by Quiksilver
	
Description:

	AO enemies
__________________________________________________________________*/

//---------- CONFIG

#define INF_TYPE "OIA_InfSentry","OIA_InfSquad","OIA_InfSquad_Weapons","OIA_InfTeam","OIA_InfTeam_AT","OI_reconPatrol","OI_reconSentry","OI_reconTeam"
#define INF_URBANTYPE "OIA_GuardSentry","OIA_GuardSquad","OIA_GuardTeam"
#define MRAP_TYPE "O_MRAP_02_hmg_F"
#define VEH_TYPE "O_MBT_02_cannon_F","O_APC_Tracked_02_cannon_F","O_APC_Wheeled_02_rcws_F","O_APC_Tracked_02_cannon_F","I_APC_Wheeled_03_cannon_F","I_APC_tracked_03_cannon_F","I_MBT_03_cannon_F"
#define AIR_TYPE "I_Heli_light_03_F","O_Heli_Light_02_F"
#define STATIC_TYPE "O_HMG_01_F","O_HMG_01_high_F","O_Mortar_01_F"

private ["_enemiesArray","_randomPos","_patrolGroup","_AOvehGroup","_AOveh","_AOmrapGroup","_AOmrap","_pos","_spawnPos","_overwatchGroup","_x","_staticGroup","_static","_aaGroup","_aa","_airGroup","_air","_sniperGroup","_staticDir"];
_pos = getMarkerPos (_this select 0);
_dt = _this select 1;

_enemiesArray = [grpNull];
_x = 0;
//---------- AA VEHICLE

if (count allPlayers >= PARAMS_PlayersNeededForAircraft) then
{
	for "_x" from 1 to PARAMS_AAPatrol do {
		_randomPos = [[[getMarkerPos currentAO, (PARAMS_AOSize / 2)],[]],["water","out"]] call BIS_fnc_randomPos;
		_aaGroup = createGroup east;
		_aa = "O_APC_Tracked_02_AA_F" createVehicle _randomPos;
		[_aa] call JB_fnc_downgradeATInventory;

		createVehicleCrew _aa;
		(crew _aa) join _aaGroup;

		[_aaGroup, getMarkerPos currentAO, 500] call BIS_fnc_taskPatrol;
		_aa lock 3;
		
		[(units _aaGroup)] call QS_fnc_setSkill4;

		_enemiesArray pushBack _aaGroup;
		_enemiesArray pushBack _aa;

		[_aaGroup] call SERVER_RegisterDeaths;

		[[_aa]] call SERVER_CurateEditableObjects;
		[units _aaGroup] call SERVER_CurateEditableObjects;
	};
};

//---------- INFANTRY PATROLS RANDOM
	
for "_x" from 1 to PARAMS_GroupPatrol do {
	_patrolGroup = createGroup east;
	_randomPos = [[[getMarkerPos currentAO, (PARAMS_AOSize / 1.2)],[]],["water","out"]] call BIS_fnc_randomPos;
	_patrolGroup = [_randomPos, EAST, (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> [INF_TYPE] call BIS_fnc_selectRandom)] call BIS_fnc_spawnGroup;
	[_patrolGroup, getMarkerPos currentAO, 400] call BIS_fnc_taskPatrol;

	[_patrolGroup] call JB_fnc_downgradeATEquipment;

	[(units _patrolGroup)] call QS_fnc_setSkill1;

	_enemiesArray pushBack _patrolGroup;

	[_patrolGroup] call SERVER_RegisterDeaths;

	[units _patrolGroup] call SERVER_CurateEditableObjects;
};
	
//---------- STATIC WEAPONS

for "_x" from 1 to PARAMS_StaticMG do {
	_staticGroup = createGroup east;
	_randomPos = [getMarkerPos currentAO, 200, 10, 10] call BIS_fnc_findOverwatch;
	_static = [STATIC_TYPE] call BIS_fnc_selectRandom createVehicle _randomPos;
	waitUntil{!isNull _static};	
	_static setDir random 360;
		"O_support_MG_F" createUnit [_randomPos,_staticGroup];
		((units _staticGroup) select 0) assignAsGunner _static;
		((units _staticGroup) select 0) moveInGunner _static;
	_staticGroup setBehaviour "COMBAT";
	_staticGroup setCombatMode "RED";
	_static setVectorUp [0,0,1];
	_static lock 3;
	
	[(units _staticGroup)] call QS_fnc_setSkill3;

	_enemiesArray pushBack _staticGroup;
	_enemiesArray pushBack _static;

	[_staticGroup] call SERVER_RegisterDeaths;

	[[_static]] call SERVER_CurateEditableObjects;
	[units _staticGroup] call SERVER_CurateEditableObjects;
};
	
//---------- INFANTRY OVERWATCH
	
for "_x" from 1 to PARAMS_Overwatch do {
	_overwatchGroup = createGroup east;
	_randomPos = [getMarkerPos currentAO, 600, 50, 10] call BIS_fnc_findOverwatch;
	_overwatchGroup = [_randomPos, East, (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "UInfantry" >> [INF_URBANTYPE] call BIS_fnc_selectRandom)] call BIS_fnc_spawnGroup;
	[_overwatchGroup, _randomPos, 100] call BIS_fnc_taskPatrol;

	[(units _overwatchGroup)] call QS_fnc_setSkill2;

	_enemiesArray pushBack _overwatchGroup;

	[_overwatchGroup] call SERVER_RegisterDeaths;

	[units _overwatchGroup] call SERVER_CurateEditableObjects;
};

//--------- MRAP

for "_x" from 0 to 1 do {
	_AOmrapGroup = createGroup east;
	_randomPos = [[[getMarkerPos currentAO, PARAMS_AOSize],[]],["water","out"]] call BIS_fnc_randomPos;
	_AOmrap = "O_MRAP_02_F" createVehicle _randomPos;
	waitUntil {!isNull _AOmrap};
	[_AOmrap] call JB_fnc_downgradeATInventory;

	createVehicleCrew _AOmrap;
	(crew _AOmrap) join _AOmrapGroup;

	[_AOmrapGroup, getMarkerPos currentAO, 600] call BIS_fnc_taskPatrol;
	_AOmrap lock 3;
	if (random 1 >= 0.3) then {
		_AOmrap allowCrewInImmobile true;
	};
	
	[(units _AOmrapGroup)] call QS_fnc_setSkill2;

	_enemiesArray pushBack _AOmrapGroup;
	_enemiesArray pushBack _AOmrap;

	[_AOmrapGroup] call SERVER_RegisterDeaths;

	[[_AOmrap]] call SERVER_CurateEditableObjects;
	[units _AOmrapGroup] call SERVER_CurateEditableObjects;
};

if (count allPlayers >= PARAMS_PlayersNeededForVehicles) then
{
	for "_x" from 0 to 1 do {
		_AOmrapGroup = createGroup east;
		_randomPos = [[[getMarkerPos currentAO, PARAMS_AOSize],[]],["water","out"]] call BIS_fnc_randomPos;
		_AOmrap = [MRAP_TYPE] call BIS_fnc_selectRandom createVehicle _randomPos;
		waitUntil {!isNull _AOmrap};
		[_AOmrap] call JB_fnc_downgradeATInventory;

		createVehicleCrew _AOmrap;
		(crew _AOmrap) join _AOmrapGroup;

		[_AOmrapGroup, getMarkerPos currentAO, 600] call BIS_fnc_taskPatrol;
		_AOmrap lock 3;
		if (random 1 >= 0.3) then {
			_AOmrap allowCrewInImmobile true;
		};
	
		[(units _AOmrapGroup)] call QS_fnc_setSkill2;

		_enemiesArray pushBack _AOmrapGroup;
		_enemiesArray pushBack _AOmrap;

		[_AOmrapGroup] call SERVER_RegisterDeaths;

		[[_AOmrap]] call SERVER_CurateEditableObjects;
		[units _AOmrapGroup] call SERVER_CurateEditableObjects;
	};
};

//---------- GROUND VEHICLE RANDOM

if (count allPlayers >= PARAMS_PlayersNeededForArmor) then
{
	for "_x" from 0 to (3 + (random 2)) do {
		_AOvehGroup = createGroup east;
		_randomPos = [[[getMarkerPos currentAO, PARAMS_AOSize],[]],["water","out"]] call BIS_fnc_randomPos;
		_AOveh = [VEH_TYPE] call BIS_fnc_selectRandom createVehicle _randomPos;
		waitUntil{!isNull _AOveh};
		[_AOveh] call JB_fnc_downgradeATInventory;

		if (random 1 < 0.75) then
		{
			_AOveh allowCrewInImmobile true;
		};

		createVehicleCrew _AOveh;
		(crew _AOveh) join _AOvehGroup;

		[_AOvehGroup, getMarkerPos currentAO, 400] call BIS_fnc_taskPatrol;
		_AOveh lock 3;
	
		[(units _AOvehGroup)] call QS_fnc_setSkill2;

		_enemiesArray pushBack _AOvehGroup;
		_enemiesArray pushBack _AOveh;

		[_AOvehGroup] call SERVER_RegisterDeaths;

		[[_AOveh]] call SERVER_CurateEditableObjects;
		[units _AOvehGroup] call SERVER_CurateEditableObjects;
	};
};
//---------- HELICOPTER	

if (count allPlayers >= PARAMS_PlayersNeededForAircraft) then
{
	if((random 10 <= PARAMS_AirPatrol)) then {
		_airGroup = createGroup east;
		_randomPos = [[[getMarkerPos currentAO, PARAMS_AOSize],_dt], ["water","out"]] call BIS_fnc_randomPos;
		_air = [AIR_TYPE] call BIS_fnc_selectRandom createVehicle [_randomPos select 0,_randomPos select 1,1000];
		waitUntil{!isNull _air};

		[_air] call JB_fnc_downgradeATInventory;
		_air engineOn true;
		_air setPos [_randomPos select 0,_randomPos select 1,300];

		_air spawn
		{
			private["_x"];
			for [{_x=0},{_x<=200},{_x=_x+1}] do
			{
				_this setVelocity [0,0,0];
				sleep 0.1;
			};
		};

		"O_helipilot_F" createUnit [_randomPos,_airGroup];
		((units _airGroup) select 0) assignAsDriver _air;
		((units _airGroup) select 0) moveInDriver _air;
		"O_helipilot_F" createUnit [_randomPos,_airGroup];
		((units _airGroup) select 1) assignAsGunner _air;
		((units _airGroup) select 1) moveInGunner _air;

		[_airGroup, getMarkerPos currentAO, 800] call BIS_fnc_taskPatrol;
		[(units _airGroup)] call QS_fnc_setSkill2;
		_air flyInHeight 300;
		_airGroup setCombatMode "RED";
		_air lock 3;
		
		_enemiesArray pushBack _airGroup;
		_enemiesArray pushBack _air;

		[_airGroup] call SERVER_RegisterDeaths;

		[[_air]] call SERVER_CurateEditableObjects;
		[units _airGroup] call SERVER_CurateEditableObjects;
	};
};
//---------- SNIPERS
	
for "_x" from 1 to PARAMS_SniperTeamsPatrol do {
	_sniperGroup = createGroup east;
	_randomPos = [getMarkerPos currentAO, 1200, 100, 10] call BIS_fnc_findOverwatch;
	_sniperGroup = [_randomPos, EAST,(configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OI_SniperTeam")] call BIS_fnc_spawnGroup;
	_sniperGroup setBehaviour "COMBAT";
	_sniperGroup setCombatMode "RED";
		
	if (random 1 >= 0.5) then
	{
		[(units _sniperGroup)] call QS_fnc_setSkill4;
	}
	else
	{
		[(units _sniperGroup)] call QS_fnc_setSkill3;
	};

	_enemiesArray pushBack _sniperGroup;

	[_sniperGroup] call SERVER_RegisterDeaths;

	[units _sniperGroup] call SERVER_CurateEditableObjects;
};

//=========== ENEMIES IN BUILDINGS

if (PARAMS_EnemiesInBuildings != 0) then
{
	_houses = _pos nearObjects ["House", PARAMS_AOSize];
	private _numberToPlace = ((count _houses) * 4) min PARAMS_EnemiesInBuildings;

	private _unitTypes = getArray (missionConfigFile >> "Faction" >> "Independent" >> "Units");

	private _groups = [];
	private _group = [];
	for [{_i = 0}, {_i < _numberToPlace}, {_i = _i + 1}] do
	{
		if (_i mod 10 == 0) then
		{
			if (count _group > 0) then
			{
				_groups pushBack _group;
				_group = [];
			};
		};
		_group pushBack (_unitTypes call BIS_fnc_selectRandom);
	};
	if (count _group > 0) then
	{
		_groups pushBack _group;
	};

	{
		private _housed = [_pos, RESISTANCE, _x] call BIS_fnc_spawnGroup;

		[_housed] call JB_fnc_downgradeATEquipment;

		_enemiesArray pushBack _housed;

		[(units _housed)] call QS_fnc_setSkill2;

		private _housePosition = getPos (_houses select (floor random (count _houses - 1)));
		[_housePosition, units _housed, 50, 0, [0,20], true, true] call SHK_fnc_buildingPos02;

		{
			if ((_x distance _housePosition) > 50) then
			{
				_x setPos _housePosition vectorAdd [-50 + random 100, -50 + random 100, 0];
			};
		} forEach units _housed;

		[_housed] call SERVER_RegisterDeaths;

		[units _housed] call SERVER_CurateEditableObjects;
	} forEach _groups;
};

//---------- GARRISON FORTIFICATIONS	
	
{
	if (random 1 < 0.5) then
	{
		_newGrp = [_x] call QS_fnc_garrisonFortEAST;
		if (!isNull _newGrp) then { 
			_enemiesArray pushBack _newGrp;
			[_newGrp] call SERVER_RegisterDeaths;
			[units _newGrp] call SERVER_CurateEditableObjects;
		};
	};
} forEach (getMarkerPos currentAO nearObjects ["House", PARAMS_AOSize]);
	
_enemiesArray;
