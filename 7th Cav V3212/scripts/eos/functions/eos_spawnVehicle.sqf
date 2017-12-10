private _position = (_this select 0);
private _side = (_this select 1);
private _faction = (_this select 2);
private _type = (_this select 3);
private _special = if (count _this > 4) then {_this select 4} else {"CAN_COLLIDE"};

private _vehicleType = [_faction,_type] call eos_fnc_getunitpool;

if (count _vehicleType == 0) exitWith { [] };

private _group = createGroup _side;

private _vehicle = createVehicle [(_vehicleType select 0), _position, [], 0, _special];

if (_side != west) then
{
	[_vehicle, "opfor", []] call BIS_fnc_initVehicle;
	_vehicle lock 3;
};

waitUntil {!isNull _vehicle};

[_vehicle] call JB_fnc_downgradeATInventory;

if ((random 1) < 0.75) then
{
	_vehicle allowCrewInImmobile TRUE;
};

createVehicleCrew _vehicle;
(crew _vehicle) join _group;

[_group] call SERVER_RegisterDeaths;
[[_vehicle]] call SERVER_CurateEditableObjects;
[units _group] call SERVER_CurateEditableObjects;

[_vehicle,units _group,_group]