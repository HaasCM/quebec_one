/*

	vehicleCrewRestrictionInit - given a list of pairs of vehicle filters and restrictions,
	when a player occupies a seat of a vehicle matching a filter, apply the corresponding restriction.

	[restriction, vehicleFilter] call compile "vehicleCrewRestrictionInit.sqf";
	[restriction, vehicleFilter] execVM "vehicleCrewRestrictionInit.sqf";

*/

VCR_MovePlayer =
{
	private _vehicle = (_this select 0);
	private _keepPlayerInVehicle = (_this select 1);

	if (_keepPlayerInVehicle && { (_vehicle emptyPositions "cargo") > 0 }) then
	{
		moveOut player;
		player moveInCargo _vehicle;
	}
	else
	{
		player action ["getOut", _vehicle];
	};
};

VCR_CheckRestrictions =
{
	private _playerInVehicle = param [0, false, [false]];

	// Allow incapacitated soldiers to be loaded into any position of any vehicle
	if (lifeState player == "INCAPACITATED") exitWith {};

	private _vehicle = vehicle player;

	private _restrictions = player getVariable ["VCR_Restrictions", []];

	{
		if ([typeOf _vehicle, _x select 1] call JB_fnc_passesTypeFilter) then
		{
			[_vehicle, _playerInVehicle] call (_x select 0);
		};
	} forEach _restrictions;
};

VCR_SetupRestrictions =
{
	private _restrictions = param [0, [], [[]]];

	player setVariable ["VCR_Restrictions", _restrictions];

	player addEventHandler ["GetInMan", { [false] call VCR_CheckRestrictions; }];
	player addEventHandler ["SeatSwitchedMan", { [true] call VCR_CheckRestrictions; }];
};

Restriction_CleanedRoleDescription = 
{
	_cleanedDescription = roleDescription player;

	private _paren = _cleanedDescription find "(";
	if (_paren >= 0) then
	{
		_cleanedDescription = _cleanedDescription select [0, _paren];
		_cleanedDescription = [_cleanedDescription, "end"] call JB_fnc_trimWhitespace;
	};

	_cleanedDescription;
};

//TODO: Restrictions should probably have a caller-supplied passthrough argument

Restriction_MayNotDriveVehicle =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	private _state = _vehicle getVariable ["Restriction_MayNotDriveVehicle", "active"];

	if (_state == "suspended") exitWith { };

	if (player == (driver _vehicle)) then
	{
		private _playerClassDisplayName = ([] call Restriction_CleanedRoleDescription);
		private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

		titleText [format ["In your role as %1, you may not drive this vehicle (%2)", _playerClassDisplayName, _vehicleClassDisplayName], "BLACK IN", 5];
		[_vehicle, _playerInVehicle] call VCR_MovePlayer;
	};
};

Restriction_MayNotGunCommandVehicle =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	if (player == (gunner _vehicle) || player == (commander _vehicle)) then
	{
		private _playerClassDisplayName = [] call Restriction_CleanedRoleDescription;
		private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

		private _prohibitedRole = if (player == (gunner _vehicle)) then { "gunner" } else { "commander" };

		titleText [format ["In your role as %1, you may not act as %2 for this vehicle (%3)", _playerClassDisplayName, _prohibitedRole, _vehicleClassDisplayName], "BLACK IN", 5];
		[_vehicle, _playerInVehicle] call VCR_MovePlayer;
	};
};

Restriction_MayNotCrewVehicle =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	if (player == (driver _vehicle) || player == (gunner _vehicle) || player == (commander _vehicle)) then
	{
		private _playerClassDisplayName = [] call Restriction_CleanedRoleDescription;
		private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

		titleText [format ["In your role as %1, you may not crew this vehicle (%2)", _playerClassDisplayName, _vehicleClassDisplayName], "BLACK IN", 5];
		[_vehicle, _playerInVehicle] call VCR_MovePlayer;
	};
};

Restriction_MayNotPilotAircraft =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	if (player in [driver _vehicle]) then
	{
		private _playerClassDisplayName = [] call Restriction_CleanedRoleDescription;
		private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

		titleText [format ["In your role as %1, you may not pilot this aircraft (%2)", _playerClassDisplayName, _vehicleClassDisplayName], "BLACK IN", 5];
		[_vehicle, _playerInVehicle] call VCR_MovePlayer;
	};

	if (player in [_vehicle turretUnit [0]]) then
	{
		_vehicle enableCopilot true;
		player action ["LockVehicleControl", _vehicle];
		_vehicle enableCopilot false;
	};
};

Restriction_MayNotOperateGunTurrets =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	private _nonWeapons = ["CMFlareLauncher", "SmokeLauncher", "TruckHorn", "TruckHorn2", "TruckHorn3", "MiniCarHorn", "CarHorn", "Laserdesignator_mounted"];

	if (player != driver _vehicle && { count ((_vehicle weaponsTurret (assignedVehicleRole player select 1)) - _nonWeapons) > 0 }) then
	{
		private _playerClassDisplayName = [] call Restriction_CleanedRoleDescription;
		private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

		titleText [format ["In your role as %1, you may not operate weapons on this vehicle (%2)", _playerClassDisplayName, _vehicleClassDisplayName], "BLACK IN", 5];
		[_vehicle, _playerInVehicle] call VCR_MovePlayer;
	};
};

private _restrictions = param [0, [], [[]]];

[_restrictions] call VCR_SetupRestrictions;
player addEventHandler ["Respawn", { [(_this select 1) getVariable ["VCR_Restrictions", []]] call VCR_SetupRestrictions; }];