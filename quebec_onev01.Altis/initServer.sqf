/*
@filename: initServer.sqf
Author:

	Quiksilver

Last modified:

	23/10/2014 ArmA 1.32 by Quiksilver

Description:

	Server scripts such as missions, modules, third party and clean-up.

*/

diag_log "initServer.sqf";

#include "SPM\strongpoint.h"

for [ {_i = 0}, {_i < count(paramsArray)}, {_i = _i + 1} ] do {
	call compile format
	[
		"PARAMS_%1 = %2",
		(configName ((missionConfigFile >> "Params") select _i)),
		(paramsArray select _i)
	];
};

SPM_SpecialOperationsCommand = [] call OO_CREATE(SpecialOperationsCommand);
SPM_SpecialOperationsEnabled = true;
SPM_CounterattackEnabled = true;

PARAMS_PlayersNeededForVehicles = 10;
PARAMS_PlayersNeededForAircraft = 15;
PARAMS_PlayersNeededForArmor = 20;

civilian setFriend [west, 1]; // To allow for armed civilians that won't attack players
independent setFriend [east, 1];
east setFriend [independent, 1];
independent setFriend [west, 0];

//-------------------------------------------------- Server scripts

[] call compile preprocessFile ("scripts\configure" + worldName + ".sqf");								// Island-specific modifications

[] call compile preprocessFile "scripts\weatherInit.sqf";												// weather control
[] call compile preprocessFile "scripts\misc\islandConfig.sqf";											// prep the island for mission
[] call compile preprocessFile "scripts\eos\OpenMe.sqf";												// EOS (urban mission and defend AO)

if (PARAMS_AO == 1) then { _null = [] execVM "mission\main\missionControl.sqf"; };						// Main AO
if (PARAMS_SideObjectives == 1) then { _null = [] execVM "mission\side\missionControl.sqf";};			// Side objectives

["Initialize"] call BIS_fnc_dynamicGroups;

_null = [] execVM "ASL_AdvancedSlingLoading\functions\fn_advancedSlingLoadInit.sqf";
_null = [] execVM "AR_AdvancedRappelling\functions\fn_advancedRappellingInit.sqf";
_null = [] execVM "AT_AdvancedTowing\functions\fn_advancedTowingInit.sqf";
_null = [] execVM "AUR_AdvancedUrbanRappelling\functions\fn_advancedUrbanRappellingInit.sqf";

SERVER_ExecuteCommand =
{
	private _command = _this select 0;

	switch (true) do
	{
		case (_command find "&spm " == 0):
		{
			[_command select [5]] call SPM_ExecuteCommand;
		};
	};
};

SERVER_SPM_COMMAND_SecurityCheck =
{
	private _command = _this select 0;

	if (not isRemoteExecuted) exitWith { true };

	private _remoteOwner = remoteExecutedOwner;

	private _passed = false;
	{
		if (owner _x == _remoteOwner) exitWith
		{
			private _curator = getAssignedCuratorLogic _x;
			_passed = (not isNull _curator && { _curator in SERVER_GameMasters });
		};
	} forEach allPlayers;

	_passed
};

SPM_COMMAND_SecurityCheck = SERVER_SPM_COMMAND_SecurityCheck;

//TODO: Installing empty handlers is apparently a workaround to a bug that interferes with the PlayerConnected/PlayerDisconnected event handlers
onPlayerConnected {};
onPlayerDisconnected {};

addMissionEventHandler ["PlayerConnected", SERVER_PlayerConnected];
addMissionEventHandler ["PlayerDisconnected", SERVER_PlayerDisconnected];

enableEnvironment FALSE;

// Start times anywhere during the day, but focused on 12-1pm

setDate [2016, 6, 21, random [0, 12, 23], random 60];