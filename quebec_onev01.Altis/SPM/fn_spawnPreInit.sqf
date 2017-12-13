/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

SPM_RecordDeath =
{
	params ["_body", "_killer"];

	if (side _body == side _killer) exitWith
	{
		deleteVehicle _body;
	};

	if (isNil "SPM_DeadBodies") then
	{
		SPM_DeadBodies = [];

		[] spawn
		{
			while { true } do
			{
				private _currentTime = diag_tickTime;
				while { count SPM_DeadBodies > 0 && { (SPM_DeadBodies select 0) select 1 < _currentTime }} do
				{
					deleteVehicle ((SPM_DeadBodies deleteAt 0) select 0);
				};

				if (count SPM_DeadBodies == 0) then
				{
					sleep 120;
				}
				else
				{
					sleep (((SPM_DeadBodies select 0) select 1) - _currentTime);
				};
			};
		};
	};

	SPM_DeadBodies pushBack [_body, diag_tickTime + 120];
};

SPM_RecordDestruction =
{
	params ["_wreck"];

	if (isNil "SPM_DestroyedVehicles") then
	{
		SPM_DestroyedVehicles = [];

		[] spawn
		{
			while { true } do
			{
				private _currentTime = diag_tickTime;
				while { count SPM_DestroyedVehicles > 0 && { (SPM_DestroyedVehicles select 0) select 1 < _currentTime }} do
				{
					deleteVehicle ((SPM_DestroyedVehicles deleteAt 0) select 0);
				};

				if (count SPM_DestroyedVehicles == 0) then
				{
					sleep 240;
				}
				else
				{
					sleep (((SPM_DestroyedVehicles select 0) select 1) - _currentTime);
				};
			};
		};
	};

	SPM_DestroyedVehicles pushBack [_wreck, diag_tickTime + 240];
};

SPM_RecordFiring =
{
	params ["_unit"];

	private _gridCell = [getPos _unit] call SPM_Map_GetStatusGridCell;

	if (count _gridCell > 0) then
	{
		_gridCell set [0, true];
		_gridCell set [2, false];
	};
};

SPM_PositionBehindVehicle =
{
	params ["_vehicle", "_distance"];

	private _box = boundingBoxReal _vehicle;

	private _position = _vehicle modelToWorld [0, (_box select 0 select 1) - _distance, 0];

	_position
};

SPM_PositionInFrontOfVehicle =
{
	params ["_vehicle", "_distance"];

	private _box = boundingBoxReal _vehicle;

	private _position = _vehicle modelToWorld [0, (_box select 1 select 1) + _distance, 0];

	_position
};

SPM_MoveIntoVehicleDriver =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	if (_vehicle isKindOf "StaticWeapon") exitWith { [] }; // Statics weapons claim to have drivers

	private _driver = [];

	if (count _vehiclePositions == 0 || { "driver" in _vehiclePositions }) then
	{
		private _drivers = fullCrew [_vehicle, "driver", true];
		_drivers = _drivers select { isNull (_x select 0) };
		if (count _drivers > 0) then
		{
			_driver = _drivers select 0;
			_unit assignAsDriver _vehicle;
			_unit moveInDriver _vehicle;
		};
	};

	_driver
};

SPM_MoveIntoVehicleGunner =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	private _gunner = [];

	if (count _vehiclePositions == 0 || { "gunner" in _vehiclePositions }) then
	{
		private _gunners = fullCrew [_vehicle, "gunner", true];
		_gunners = _gunners select { isNull (_x select 0) };
		if (count _gunners > 0) then
		{
			_gunner = _gunners select 0;
			_unit assignAsGunner _vehicle;
			_unit moveInGunner _vehicle;
		};
	};

	_gunner
};

SPM_MoveIntoVehicleCommander =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	private _commander = [];

	if (count _vehiclePositions == 0 || { "commander" in _vehiclePositions }) then
	{
		private _commanders = fullCrew [_vehicle, "commander", true];
		_commanders = _commanders select { isNull (_x select 0) };
		if (count _commanders > 0) then
		{
			_commander = _commanders select 0;
			_unit assignAsCommander _vehicle;
			_unit moveInCommander _vehicle;
		};
	};

	_commander
};

SPM_MoveIntoVehicleTurret =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	private _turret = [];

	if (count _vehiclePositions == 0 || { "turret" in _vehiclePositions }) then
	{
		private _turrets = fullCrew [_vehicle, "Turret", true];
		_turrets = _turrets select { isNull (_x select 0) };
		if (count _turrets > 0) then
		{
			_turret = _turrets select 0;
			_unit assignAsTurret [_vehicle, _turret select 3];
			_unit moveInTurret [_vehicle, _turret select 3];
		};
	};

	_turret
};

SPM_MoveIntoVehicleCargo =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	private _seat = [];

	if (count _vehiclePositions == 0 || { "cargo" in _vehiclePositions }) then
	{
		private _seats = fullCrew [_vehicle, "cargo", true];
		_seats = _seats select { isNull (_x select 0) };
		if (count _seats > 0) then
		{
			_seat = _seats select 0;
			_unit assignAsCargoIndex [_vehicle, _seat select 2];
			_unit moveInCargo [_vehicle, _seat select 2];
		};
	};

	_seat
};

SPM_MoveIntoVehicle =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	private _driver = [_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicleDriver;
	if (count _driver > 0) exitWith { _driver };

	private _gunner = [_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicleGunner;
	if (count _gunner > 0) exitWith { _gunner };

	private _commander = [_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicleCommander;
	if (count _commander > 0) exitWith { _commander };

	private _turret = [_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicleTurret;
	if (count _turret > 0) exitWith { _turret };

	private _cargo = [_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicleCargo;
	if (count _cargo > 0) exitWith { _cargo };
};

SPM_SpawnGroup =
{
	params ["_side", "_descriptor", "_position", "_direction", ["_loadInVehicles", true, [true]], ["_vehiclePositions", [], [[]]]];

	private _group = createGroup _side;

	private _vehicles = [];
	private _vehicle = objNull;

	{
		if (typeName (_x select 0) == typeName objNull) then
		{
			private _unit = _x select 0;

			if (_unit isKindOf "Man") then
			{
				_unit join _group;

				if (_loadInVehicles && not isNull _vehicle) then
				{
					[_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicle;
				};
			}
			else
			{
				_vehicle = _unit;
				_vehicles pushBack _vehicle;
				_group addVehicle _vehicle;
			};
		}
		else
		{
			private _type = _x select 0;
			private _rank = _x select 1;
			private _unitPosition = ([_x select 2, _direction] call SPM_Util_RotatePosition2D);
			private _unitDirection = _x select 3;
			private _unitInitialize = _x select 4;

			if (_type isKindOf "Man") then
			{
				private _unit = _group createUnit [_type, _position vectorAdd _unitPosition, [], 0, "can_collide"];
				_unit setRank _rank;
				_unit setDir (_direction + _unitDirection);

				if (_loadInVehicles && not isNull _vehicle) then
				{
					[_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicle;
				};
			}
			else
			{
				_vehicle = [_type, _position vectorAdd _unitPosition, _direction + _unitDirection] call SPM_fnc_spawnVehicle;
				_vehicles pushBack _vehicle;
				_group addVehicle _vehicle;
			};

			if (not isNil "_unitInitialize") then { [_unit] call _unitInitialize };
		}
	} forEach _descriptor;

	[_vehicles] call SERVER_CurateEditableObjects;
	[units _group] call SERVER_CurateEditableObjects;

	{
		_x addEventHandler ["Killed", SPM_RecordDestruction];
	} forEach _vehicles;
	{
		_x addEventHandler ["Killed", SPM_RecordDeath];
	} forEach units _group;
//	{
//		_x addEventHandler ["FiredMan", SPM_RecordFiring];
//	} forEach units _group;

	_group
};

SPM_SpawnVehicle =
{
	params ["_type", "_position", "_direction", "_special"];

	private _spawnPosition = call SPM_Util_RandomSpawnPosition;

	private _vehicle = createVehicle [_type, _spawnPosition, [], 0, _special];
	_vehicle setDir _direction;
	_vehicle setPos _position;

	[[_vehicle]] call SERVER_CurateEditableObjects;

	_vehicle addEventHandler ["Killed", SPM_RecordDestruction];

	_vehicle setVehicleLock "lockedplayer";

	_vehicle
};

SPM_SpawnMineField =
{
	params ["_position", "_sizeX", "_sizeY", "_angle", "_number", "_types"];

	private _sin = sin -_angle;
	private _cos = cos -_angle;

	private _mines = [];
	for "_i" from 1 to _number do
	{
		private _x = ((random 2.0) - 1.0) * _sizeX;
		private _y = ((random 2.0) - 1.0) * _sizeY;

		private _minePosition = [_x * _cos - _y * _sin, _y * _cos + _x * _sin, 0];

		private _type = _types select (floor random (count _types));
		_mines pushBack (_type createVehicle (_position vectorAdd _minePosition));
	};

	_mines;
};