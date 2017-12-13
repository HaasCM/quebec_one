JB_RV_SetInitializer =
{
	private _vehicle = _this select 0;
	private _initName = _this select 1;
	private _initCode = _this select 2;

	private _vehicleInit = _vehicle getVariable "JB_RV_VehicleInit";
	private _vehicleInitCount = 0;

	if (!isNil "_vehicleInit") then
	{
		_vehicleInitCount = count _vehicleInit;
	}
	else
	{
		_vehicleInit = [];
		_vehicleInitCount = 0;
	};

	private _newName = true;

	{
		if (_x select 0 == _initName) then
		{
			_x set [1, _initCode];
			_newName = false;
		};
	} foreach _vehicleInit;

	if (_newName) then
	{
		_vehicleInit = _vehicleInit + [[_initName, _initCode]];
	};

	_vehicle setVariable ["JB_RV_VehicleInit", _vehicleInit];
};

/*

[parameters] = [vehicle] call JB_RV_GetRespawnParameters

	This function obtains the parameters needed for JB_RV_RespawnVehicle.  This function exists
	so that the parameters can be collected at one time and then used at another time.  That
	ability is particularly important for JB_fnc_respawnVehicleWhenKilled.  The vehicle
	will be Killed, and then the parameters can be immediately collected.  The WhenKilled script
	can then delay for however long it likes, other software can remove the wrecked vehicle,
	and the parameters that were saved can be supplied to JB_RV_RespawnVehicle.

*/
JB_RV_GetRespawnParameters =
{
	private _vehicle = param [0, objNull, [objNull]];

	if (!([_vehicle] call JB_RV_HasRespawnParameters)) exitWith { [_vehicle] };

	private _type = typeOf _vehicle;
	private _startPosition = _vehicle getVariable "JB_RV_StartPosition";
	private _startDirection = _vehicle getVariable "JB_RV_StartDirection";
	private _vehicleInit = _vehicle getVariable "JB_RV_VehicleInit";

	private _vehicleName = vehicleVarName _vehicle;

	private _whenKilled = _vehicle getVariable ["JB_RV_WhenKilled", []];
	private _whenAbandoned = _vehicle getVariable ["JB_RV_WhenAbandoned", []];

	private _curators = [];
	{
		if (_vehicle in curatorEditableObjects _x) then
		{
			_curators pushBack _x;
		}
	} foreach allCurators;

	private _vehiclePylonMagazines = _vehicle getVariable "JB_RV_VehiclePylonMagazines";

	[_vehicle, _type, _startPosition, _startDirection, _vehicleInit, _vehicleName, _whenKilled, _whenAbandoned, _curators, _vehiclePylonMagazines];
};

/*
	Determine if the vehicle is tracked by this system.
*/
JB_RV_HasRespawnParameters =
{
	count ((_this select 0) getVariable ["JB_RV_StartPosition", []]) > 0
};

/*
	Mark the vehicle such that it is no longer tracked by this system.
*/
JB_RV_RemoveRespawnParameters =
{
	private _vehicle = _this select 0;

	_vehicle setVariable ["JB_RV_StartPosition", nil];
	_vehicle setVariable ["JB_RV_StartDirection", nil];
	_vehicle setVariable ["JB_RV_VehicleInit", nil];
	_vehicle setVariable ["JB_RV_WhenKilled", nil];
	_vehicle setVariable ["JB_RV_WhenAbandoned", nil];
	_vehicle setVariable ["JB_RV_VehiclePylonMagazines", nil];
};

/*

newVehicle = [parameters] call JB_fnc_respawnVehicle

	Immediately respawn a vehicle that has been initialized by JB_fnc_respawnVehicleInitialize.  The
	vehicle will be recreated using the location and initialization script supplied at that time.

	The parameters to this function are defined by JB_fnc_respawnVehicleParameters, which collects
	the parameters from the old vehicle for use by this function.  This permits scripts to collect
	the respawn parameters at one time and use them at another.

*/

JB_RV_RespawnVehicle =
{
	params ["_vehicle", "_type", "_startPosition", "_startDirection", "_vehicleInit", "_vehicleName", "_whenKilled", "_whenAbandoned", "_curators", "_vehiclePylonMagazines"];

	// Hide the object, ensuring that it won't intersect a new one.  Next, recreate the vehicle
	// at some random location away from the map, rotate it and move it to the final
	// location.  Last, update the vehicle's variable name to point at the new vehicle.

	_vehicle hideObjectGlobal true;

	private _newVehicle = createVehicle [_type, [_startPosition select 0, _startPosition select 1, 10000], [], 0, "can_collide"];

	_newVehicle setVariable ["JB_RV_StartPosition", _startPosition];
	_newVehicle setVariable ["JB_RV_StartDirection", _startDirection];
	_newVehicle setVariable ["JB_RV_VehiclePylonMagazines", _vehiclePylonMagazines];

	private _pylonPaths = ("true" configClasses (configFile >> "CfgVehicles" >> _type >> "Components" >> "TransportPylonsComponent" >> "Pylons")) apply { [configName _x, getArray (_x >> "turret")] };
	{ _newVehicle removeWeaponGlobal getText (configFile >> "CfgMagazines" >> _x >> "pylonWeapon") } forEach getPylonMagazines _newVehicle;
	{ _newVehicle setPylonLoadOut [_pylonPaths select _forEachIndex select 0, _x, true, _pylonPaths select _forEachIndex select 1] } forEach _vehiclePylonMagazines;

	if (!isNil "_vehicleInit") then
	{
		_newVehicle setVariable ["JB_RV_VehicleInit", _vehicleInit];
		{
			[_newVehicle, _vehicle] call (_x select 1);
		} foreach _vehicleInit;
	};

	if (count _whenKilled > 0) then
	{
		_newVehicle setVariable ["JB_RV_WhenKilled", _whenKilled];
	};

	if (count _whenAbandoned > 0) then
	{
		_newVehicle setVariable ["JB_RV_WhenAbandoned", _whenAbandoned];
	};

	// Curate
	[[_newVehicle]] call SERVER_CurateEditableObjects;

	// Delete the old vehicle

	deleteVehicle _vehicle;

	// Set the vehicle's variable name to point to the respawned vehicle on the server and on all clients
	[_newVehicle, _vehicleName] call JB_fnc_setVehicleVarName;

	[_newVehicle] call JB_fnc_respawnVehicleReturn;

	_newVehicle;
};

JB_RV_Monitor =
{
	private _vehicle = _this select 0;

	private _lastAbandoned = 0;
	private _isAbandoned = false;
	private _startPosition = _vehicle getVariable "JB_RV_StartPosition";
	private _marker = format ["JB_RV_%1-%2", floor (_startPosition select 0), floor (_startPosition select 1)];

	while { alive _vehicle && not _isAbandoned } do
	{
		private _whenAbandoned = _vehicle getVariable "JB_RV_WhenAbandoned";
		if (not isNil "_whenAbandoned") then
		{
			private _abandonDistanceCondition = _whenAbandoned select 0;
			private _abandonDurationCondition = _whenAbandoned select 1;
			private _movedDistanceCondition = _whenAbandoned select 2;

			private _currentlyAbandoned = false;

			if (_vehicle distance _startPosition >= _movedDistanceCondition) then
			{
				if ({ alive _x } count crew _vehicle == 0) then
				{
					_currentlyAbandoned = true;
					{
						if (vehicle _x == _x && { _x distance _vehicle <= _abandonDistanceCondition }) exitWith { _currentlyAbandoned = false };
					} forEach allPlayers;
				};
			};

			if (not _currentlyAbandoned) then
			{
				_lastAbandoned = 0;

				deleteMarker _marker;
			}
			else
			{
				if (_lastAbandoned == 0) then
				{
					_lastAbandoned = diag_tickTime;

					createMarker [_marker, getPos _vehicle];
					_marker setMarkerType "mil_dot";
					_marker setMarkerText getText (configFile >> "CfgVehicles" >> typeOf _vehicle >> "displayName");
				}
				else
				{
					_marker setMarkerPos [getPos _vehicle select 0, getPos _vehicle select 1];

					_abandonedDuration = diag_tickTime - _lastAbandoned;
					if (_abandonedDuration >= _abandonDurationCondition) then
					{
						_isAbandoned = true;
					};
				};
			};
		};

		sleep 5;
	};

	if (_lastAbandoned != 0) then
	{
		deleteMarker _marker;
	};

	private _shouldReturn = false;
	private _returnDelay = 0;
	private _shouldRespawn = false;
	private _respawnDelay = 0;

	if (not alive _vehicle) then
	{
		private _whenKilled = _vehicle getVariable "JB_RV_WhenKilled";

		if (not isNil "_whenKilled") then
		{
			_shouldRespawn = true;
			_respawnDelay = _whenKilled select 0;
		};
	}
	else
	{
		if (_isAbandoned) then
		{
			private _whenAbandoned = _vehicle getVariable "JB_RV_WhenAbandoned";
			private _deleteOnAbandon = _whenAbandoned select 3;

			if (_deleteOnAbandon) then
			{
				deleteVehicle _vehicle;
			}
			else
			{
				_shouldReturn = true;
				_returnDelay = 0;
			};
		};
	};

	if (_shouldRespawn) then
	{
		private _vehicleParameters = [_vehicle] call JB_RV_GetRespawnParameters;
		sleep _respawnDelay;
		_vehicle = _vehicleParameters call JB_RV_RespawnVehicle;

		[_vehicle] spawn JB_RV_Monitor;
	};

	if (_shouldReturn) then
	{
		sleep _respawnDelay;
		[_vehicle] call JB_fnc_respawnVehicleReturn;

		[_vehicle] spawn JB_RV_Monitor;
	};
};
