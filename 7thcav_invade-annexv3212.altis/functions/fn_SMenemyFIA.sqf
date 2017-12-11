/*
Author: 

	Quiksilver
	
Last modified:

	25/04/2014

Description:

	Spawn FIA enemy around side objectives.
	Enemy should have backbone AA/AT + random composition.
	
___________________________________________*/

//---------- CONFIG

#define INF_TEAMS "IRG_InfSentry","IRG_InfSquad","IRG_InfSquad_Weapons","IRG_InfTeam","IRG_InfTeam_AT","IRG_ReconSentry","IRG_SniperTeam_M"
#define VEH_TYPES "B_G_Offroad_01_armed_F"
private ["_x","_pos","_flatPos","_randomPos","_unitsArray","_enemiesArray","_infteamPatrol","_SMvehPatrol","_SMveh","_SMaaPatrol","_SMaa","_IRGsniperGroup"];
_enemiesArray = [grpNull];
_x = 0;

SM_Dead = [];

//---------- INFANTRY RANDOM

for "_x" from 0 to (2 + (random 4)) do {
	_infteamPatrol = createGroup east;
	_randomPos = [[[getPos sideObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
	_infteamPatrol = [_randomPos, EAST, (configfile >> "CfgGroups" >> "West" >> "Guerilla" >> "Infantry" >> [INF_TEAMS] call BIS_fnc_selectRandom)] call BIS_fnc_spawnGroup;
	[_infteamPatrol, getPos sideObj, 100] call BIS_fnc_taskPatrol;

	[_infteamPatrol] call JB_fnc_downgradeATEquipment;

	[units _infteamPatrol] call QS_fnc_setSkill2Side;
	[_infteamPatrol] call SERVER_RegisterDeaths;

	_enemiesArray pushBack _infteamPatrol;

	[units _infteamPatrol] call SERVER_CurateEditableObjects;
};

//---------- SNIPER

for "_x" from 0 to 2 do {
	_IRGsniperGroup = createGroup east;
	_randomPos = [getPos sideObj, 600, 100, 20] call BIS_fnc_findOverwatch;
	_IRGsniperGroup = [_randomPos, EAST, (configfile >> "CfgGroups" >> "West" >> "Guerilla" >> "Infantry" >> "IRG_SniperTeam_M")] call BIS_fnc_spawnGroup;
	_IRGsniperGroup setBehaviour "COMBAT";
	_IRGsniperGroup setCombatMode "RED";
		
	[units _IRGsniperGroup] call QS_fnc_setSkill4Side;
	[_IRGsniperGroup] call SERVER_RegisterDeaths;

	_enemiesArray = _enemiesArray + [_IRGsniperGroup];

	[units _IRGsniperGroup] call SERVER_CurateEditableObjects;
};

//---------- VEHICLES	
	
for "_x" from 0 to 3 do {
	_SMvehPatrol = createGroup east;
	_randomPos = [[[getPos sideObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
	_SMveh = "B_G_Offroad_01_armed_F" createVehicle _randomPos;
	waitUntil{!isNull _SMveh};
	[_SMveh] call JB_fnc_downgradeATInventory;

		"O_Soldier_F" createUnit [_randomPos,_SMvehPatrol];
		"O_Soldier_F" createUnit [_randomPos,_SMvehPatrol];
		"O_Soldier_F" createUnit [_randomPos,_SMvehPatrol];
		((units _SMvehPatrol) select 0) assignAsDriver _SMveh;
		((units _SMvehPatrol) select 1) assignAsGunner _SMveh;
		((units _SMvehPatrol) select 2) assignAsCargo _SMveh;
		((units _SMvehPatrol) select 0) moveInDriver _SMveh;
		((units _SMvehPatrol) select 1) moveInGunner _SMveh;
		((units _SMvehPatrol) select 2) moveInCargo _SMveh;
			
	_SMveh lock 3;
	_SMveh allowCrewInImmobile true;
	[_SMvehPatrol, getPos sideObj, 300] call BIS_fnc_taskPatrol;
	
	[units _SMvehPatrol] call QS_fnc_setSkill3Side;
	[_SMvehPatrol] call SERVER_RegisterDeaths;

	_enemiesArray = _enemiesArray + [_SMvehPatrol];
	sleep 0.1;
	_enemiesArray = _enemiesArray + [_SMveh];

	[[_SMveh]] call SERVER_CurateEditableObjects;
	[units _SMvehPatrol] call SERVER_CurateEditableObjects;
};

//---------- VEHICLE AA

for "_x" from 0 to 1 do {
	_SMaaPatrol = createGroup east;
	_randomPos = [[[getPos sideObj, 300],[]],["water","out"]] call BIS_fnc_randomPos;
	_SMaa = "O_APC_Tracked_02_AA_F" createVehicle _randomPos;
	waitUntil {sleep 0.5; !isNull _SMaa};
	[_SMaa] call JB_fnc_downgradeATInventory;
	[_SMaa, _SMaaPatrol] call BIS_fnc_spawnCrew;
	_SMaa allowCrewInImmobile true;
	
	_SMaa lock 3;
	[_SMaaPatrol, getPos sideObj, 150] call BIS_fnc_taskPatrol;
	
	[(units _SMaaPatrol)] call QS_fnc_setSkill4Side;
	[_SMaaPatrol] call SERVER_RegisterDeaths;

	_enemiesArray = _enemiesArray + [_SMaaPatrol];
	sleep 0.1;
	_enemiesArray = _enemiesArray + [_SMaa];

	[[_SMaa]] call SERVER_CurateEditableObjects;
	[units _SMaaPatrol] call SERVER_CurateEditableObjects;
};

//---------- GARRISON FORTIFICATIONS	
	
{
	_newGrp = [_x] call QS_fnc_garrisonFortFIA;
	if (!isNull _newGrp) then
	{ 
		_enemiesArray = _enemiesArray + [_newGrp];
		[_newGrp] call SERVER_RegisterDeaths;

		[units _newGrp] call SERVER_CurateEditableObjects;
	};
} forEach (getPos sideObj nearObjects ["House", 200]);

_enemiesArray