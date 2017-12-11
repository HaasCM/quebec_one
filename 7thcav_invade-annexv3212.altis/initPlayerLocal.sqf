["InitializePlayer", [player, true]] call BIS_fnc_dynamicGroups;

waitUntil {time > 0};

enableEnvironment false;

waitUntil { !isNull player };
waitUntil { vehicle player == player };
waitUntil { getPlayerUID player != "" };

enableSentences false;
enableSaving [false, false];

//------------------------------------------------ Handle parameters

for [ {_i = 0}, {_i < count(paramsArray)}, {_i = _i + 1} ] do {
	call compile format
	[
		"PARAMS_%1 = %2",
		(configName ((missionConfigFile >> "Params") select _i)),
		(paramsArray select _i)
	];
};

// [[code, whatever], [code, whatever], ...]
CLIENT_PlayerDisconnectedHandlers = [];

// Called by the server when a player disconnects
CLIENT_PlayerDisconnected =
{
	params ["_unit"];

	if (isDedicated) exitWith {};

	{
		[_unit] call (_x select 0);
	} forEach CLIENT_PlayerDisconnectedHandlers;
};

// Handle the case of a player being carried or dragged by another player.  If spotted, detach
// the player from the disconnecting player and pose them incapacitated.
CLIENT_PlayerDisconnectedHandlers pushBack
	[
		{
			private _unit = _this select 0;

			if (attachedTo player == _unit) then
			{
				detach player;
				if (lifeState player == "INCAPACITATED") then
				{
					player switchMove "unconsciousrevivedefault";
				};
			};
		}
	];

player setVariable ["RESPAWN_PlayerPosition", [getPosASL player, getDir player]];

// Have player exit vehicle with weapon that he entered
PLAYER_WeaponGetIn = "";
player addEventHandler ["GetInMan", { if ((_this select 2 == HALO_AO_Aircraft) || (_this select 2 == HALO_SM_Aircraft)) then { PLAYER_WeaponGetIn = "" } else { PLAYER_WeaponGetIn = currentWeapon player } }];
player addEventHandler ["GetOutMan", { if (PLAYER_WeaponGetIn == "") then { player action ["SwitchWeapon", player, player, -1];}; [player, "amovpercmstpsnonwnondnon"] remoteExec ["switchMove"]; }];

// Disable faction changes due to team killing, vehicle destruction, etc.
player addEventHandler ["HandleRating", { 0 }];

[] execVM "scripts\vehicle\crew\CrewList.sqf";

[] execVM "ASL_AdvancedSlingLoading\overrideStandardSlingLoading.sqf";
[] execVM "scripts\holsterWeaponKey.sqf";
[] execVM "scripts\jumpInit.sqf";
[] execVM "scripts\curatorLightInit.sqf";
[] execVM "scripts\disablePingInit.sqf";

[] call JB_fnc_repackInit;
[] call JB_fnc_medicalInit;
[] call JB_fnc_increasedFuelConsumption;

//[] call Radio_fnc_init; // Radio clicks and line noise

["init"] call compile preProcessFile format ["scripts\class\%1.sqf", typeOf player];

[] execVM "scripts\misc\diary.sqf";
[] execVM "scripts\mapOverlay.sqf";
[] execVM "scripts\channelControlInit.sqf";

[] execVM ("scripts\configure" + worldName + ".sqf");			// Island-specific modifications

CLIENT_CommandChatHandler =
{
	private _channel = _this select 0;
	private _message = _this select 1;

	if (_message find "&" == 0) then
	{
		[_message] remoteExec ["SERVER_ExecuteCommand", 2];
	};
};

[CLIENT_CommandChatHandler] call JB_fnc_chatAddEventHandler;

"addToScore" addPublicVariableEventHandler
{
	((_this select 1) select 0) addScore ((_this select 1) select 1);
};

CLIENT_InitPlayerLocalComplete = true;