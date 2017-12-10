waitUntil { not isNull player };
waitUntil { not isNil "CLIENT_InitPlayerLocalComplete" };

private _respawn = player getVariable ["RESPAWN_PlayerPosition", []];
player setPosASL (_respawn select 0);
player setDir (_respawn select 1);

hideBody player;

if (not isNil "RESPAWN_Loadout") then
{
	player setUnitLoadout RESPAWN_Loadout;
};

saving_inventory = FALSE;

// Tell server about this character.  Note that this is a blocking call because what the server does
// with the player can affect the rest of this script.
[[player], "SERVER_CuratePlayer", 2] call JB_fnc_remoteCall;

[player, [Headquarters, Carrier], []] execVM "scripts\greenZoneInit.sqf"; // No-combat zones

[] execVM "vas\earplugs.sqf";
player addAction ["Clear vehicle inventory", { [vehicle player] call JB_fnc_clearVehicleInventory }, [], 0, false, true, "", "[vehicle player] call JB_fnc_clearVehicleInventoryCondition"];
player addAction ["Unflip Vehicle", { [cursorTarget] call JB_fnc_flipVehicle }, [], 0, true, true, "", "(vehicle player) == player && { (player distance cursorTarget) < 4 } && { [cursorTarget] call JB_fnc_flipVehicleCondition }"];

[player] call JB_fnc_fuelInitPlayer;
[player] call JB_fnc_ammoInitPlayer;

["respawn"] call compile preProcessFile format ["scripts\class\%1.sqf", typeOf player];