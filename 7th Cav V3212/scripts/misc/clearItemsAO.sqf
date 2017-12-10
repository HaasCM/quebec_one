private _center = _this select 0;
private _radius = _this select 1;

private _radiusSqr = _radius * _radius;

// Any weapons lying loose on the ground
{
	if (_x distanceSqr _center < _radiusSqr) then
	{
		deleteVehicle _x;
	};
} forEach allMissionObjects "GroundWeaponHolder";

// 300 meter proximity range
#define PLAYER_STATIC_PROXIMITY_SQR 90000

// Static weapons (mortars, emplaced HMG, AT, etc)
[_center, _radius] spawn
	{
		AO_PlayerNearStatic =
		{
			private _playerNearStatic = false;

			{
				_playerNearStatic = (_x distanceSqr _static) < PLAYER_STATIC_PROXIMITY_SQR;
				if (_playerNearStatic) exitWith {};
			} forEach allPlayers;

			_playerNearStatic;
		};

		private _center = _this select 0;
		private _radius = _this select 1;

		private _radiusSqr = _radius * _radius;

		private _static = objNull;

		{
			_static = _x;
			if ((isNull (attachedTo _static)) && { _static distanceSqr _center < _radiusSqr} && { not ([_static] call AO_PlayerNearStatic) }) then
			{
				if ((count (crew _static)) > 0) then
				{
					{deleteVehicle _x;} forEach (crew _static);
				};
				deleteVehicle _static;
			};
		} forEach allMissionObjects "StaticWeapon" ;
	};

// Mines
{
	if (_x distanceSqr _center < _radiusSqr) then
	{
		deleteVehicle _x;
	};
} forEach allMines;

// Dead bodies, wrecked vehicles
{
	if (_x distanceSqr _center < _radiusSqr) then
	{
		deleteVehicle _x;
	};
} forEach allDead;

// Radio tower, destroyed buildings
{
	if (_x distanceSqr _center < _radiusSqr && { (typeOf _x) find "Tower" > 0 }) then
	{
		deleteVehicle _x;
	};
} forEach (allMissionObjects "Ruins");

sleep 2;

{
	if ((count units _x) == 0) then
	{
		deleteGroup _x;
	};
} forEach allGroups;