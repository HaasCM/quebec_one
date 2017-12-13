/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

#define OO_TRACE_DECL(name) name

SPM_Util_Ranks = ["PRIVATE", "CORPORAL", "SERGEANT", "LIEUTENANT", "CAPTAIN", "MAJOR", "COLONEL"];

OO_TRACE_DECL(SPM_Util_InValueRange) =
{
	params ["_value", "_min", "_max"];

	_value >= _min && _value <= _max
};

OO_TRACE_DECL(SPM_Util_MapValue) =
{
	params ["_value", "_fromMin", "_fromMax", "_toMin", "_toMax"];

	(_value - _fromMin) * (_toMax - _toMin) / (_fromMax - _fromMin) + _toMin;
};

OO_TRACE_DECL(SPM_Util_MapValueRange) =
{
	params ["_value", "_map"];

	if (_value < _map select 0 select 0) exitWith {};

	for "_i" from 1 to (count _map - 1) do
	{
		if (_map select _i select 0 >= _value) exitWith
		{
			private _pointMin = _map select (_i-1);
			private _pointMax = _map select _i;
			[_value, _pointMin select 0, _pointMax select 0, _pointMin select 1, _pointMax select 1] call SPM_Util_MapValue;
		};
	};
};

OO_TRACE_DECL(SPM_Util_TimeoutWait) =
{
	params ["_timeout", "_interval", "_condition"];

	private _timeoutTime = diag_tickTime + _timeout;

	waitUntil { sleep _interval; diag_tickTime > _timeoutTime || { call _condition }};
};

OO_TRACE_DECL(SPM_Util_RandomSpawnPosition) =
{
	[-10000 - random 10000, -10000 - random 10000, 1000 + random 1000]
};

OO_TRACE_DECL(SPM_Util_RotatePosition2D) =
{
	params ["_position", "_angle"];

	private _x = _position select 0;
	private _y = _position select 1;

	private _cos = cos -_angle;
	private _sin = sin -_angle;

	[_x * _cos - _y * _sin, _y * _cos + _x * _sin, _position select 2]
};

OO_TRACE_DECL(SPM_Util_MinimumSweepAngle) =
{
	private _direction1 = _this select 0;
	private _direction2 = _this select 1;

	private _minimumAngle = (_direction1 max _direction2) - (_direction1 min _direction2);
	if (_minimumAngle > 180) then { _minimumAngle = 360 - _minimumAngle };

	_minimumAngle
};

OO_TRACE_DECL(SPM_Util_Find) =
{
	private _array = _this select 0;
	private _code = _this select 1;
	private _passthrough = _this select 2;

	if (isNil "_passthrough") then
	{
		_passthrough = 0;
	};

	_index = -1;
	{
		if ([_x, _passthrough] call _code) exitWith
		{
			_index = _forEachIndex;
		};
	} forEach _array;

	_index
};

OO_TRACE_DECL(SPM_Util_DeleteArrayElements) =
{
	private _array = _this select 0;
	private _condition = _this select 1;
	private _count = param [2, -1, [0]];

	private _deletedElements = [];

	for "_i" from (count _array - 1) to 0 step -1 do
	{
		if ([_array, _i, _array select _i] call _condition) then
		{
			_deletedElements pushBack (_array deleteAt _i);
		};
		if (count _deletedElements == _count) exitWith {};
	};

	_deletedElements;
};

OO_TRACE_DECL(SPM_Util_GetUnits) =
{
	params ["_center", "_innerRadius", "_outerRadius", "_candidates"];

	private _innerRadiusSqr = _innerRadius ^ 2;
	private _outerRadiusSqr = _outerRadius ^ 2;
	private _distanceSqr = 0;

	_candidates select { _distanceSqr = _center distanceSqr getPos _x; _distanceSqr >= _innerRadiusSqr && _distanceSqr <= _outerRadiusSqr };
};

SPM_Util_DirectionNames = ["north", "northeast", "northeast", "east", "east", "southeast", "southeast", "south", "south", "southwest", "southwest", "west", "west", "northwest", "northwest", "north"];

OO_TRACE_DECL(SPM_Util_DirectionDescription) =
{
	params ["_direction"];

	SPM_Util_DirectionNames select floor (_direction / 22.5)
};

OO_TRACE_DECL(SPM_Util_PositionDescription) =
{
	private _position = _this select 0;
	
	private _description = "";

	private _locations = [];

	_locations pushBack [nearestLocation [_position, "NameVillage"], 100];
	_locations pushBack [nearestLocation [_position, "NameCity"], 120];
	_locations pushBack [nearestLocation [_position, "NameCityCapital"], 140];

	{
		private _distance = (_x select 0) distance _position;
		_x pushBack _distance;
		_x pushBack (_distance / (_x select 1));
	} forEach _locations;

	private _bestLocation = locationNull;
	private _bestProximity = 1e30;
	private _bestDistance = 1e30;

	{
		if (_x select 3 < 3.0) exitWith
		{
			_bestLocation = _x select 0;
			_bestDistance = _x select 2;
			_bestProximity = _x select 3;
			_description = (if (_x select 3 < 2.0) then { "" } else { "near "}) + text (_x select 0);
		};
	} forEach _locations;

	if (_description == "") then
	{
		{
			if ((_x select 3) < _bestProximity) then
			{
				_bestLocation = _x select 0;
				_bestDistance = _x select 2;
				_bestProximity = _x select 3;
			};
		} forEach _locations;

		private _direction = (getPos _bestLocation) getDir _position;

		_description = ([_direction] call SPM_Util_DirectionDescription) + " of " + text _bestLocation;
	};

	private _nearestLocations = nearestLocations [_position, ["NameLocal", "NameMarine", "NameVillage", "NameCity", "NameCityCapital"], 1000];

	if (count _nearestLocations > 0 && type (_nearestLocations select 0) in ["NameLocal", "NameMarine"]) then
	{
		private _nearestLocation = _nearestLocations select 0;
		if (_nearestLocation distance _position < (_bestDistance * 0.6)) then
		{
			private _text = text _nearestLocation;
			if (_text == "military") then { _text = "military compound" };
			_description = text (_nearestLocations select 0) + " " + _description;
		};
	};

	_description;
};

OO_TRACE_DECL(SPM_Util_KeepOutOfWater) =
{
	params ["_position", "_center"];

	if (surfaceIsWater _position) then
	{
		private _shiftDistance = 10;

		private _shift = (_center vectorDiff _position);
		_shift = (vectorNormalized _shift) vectorMultiply _shiftDistance;
		private _steps = floor ((_position distance _center) / _shiftDistance);

		private _scan = _position;
		for "_i" from 1 to _steps - 1 do
		{
			_scan = _scan vectorAdd _shift;
			if (not surfaceIsWater _scan) exitWith
			{
				_position = _scan;
			};
		};
	};

	_position
};

OO_TRACE_DECL(SPM_Util_SubstituteRepairCrewman) =
{
	private _crewmanDescriptor = _this select 0;

	private _crewmanType = _crewmanDescriptor select 0;
	private _crewmanSide = getNumber (configFile >> "CfgVehicles" >> _crewmanType >> "side");

	switch (_crewmanSide) do
	{
		case 0: { _crewmanDescriptor set [0, "O_soldier_repair_F"]; };
		case 1: { _crewmanDescriptor set [0, "B_soldier_repair_F"]; };
		case 2: { _crewmanDescriptor set [0, "I_Soldier_repair_F"]; };
	};
};

SPM_Util_AIAllEnabled = ["target", "autotarget", "move", "anim", "teamswitch", "fsm", "aimingerror", "suppression", "checkvisible", "autocombat", "path"];

OO_TRACE_DECL(SPM_Util_AISet) =
{
	params ["_unit", "_name", "_settings"];

	private _allEnabled = false;
	if (_settings == "all") then
	{
		_settings = SPM_Util_AIAllEnabled;
		_allEnabled = true;
	}
	else
	{
		_allEnabled = (count (SPM_Util_AIAllEnabled - _settings) == 0);
	};

	private _ai = _unit getVariable "SPM_AI";
	if (isNil "_ai") exitWith
	{
		if (not _allEnabled) then
		{
			_ai = [[_name, _settings]];
			_unit setVariable ["SPM_AI", _ai];
		};
	};


	private _index = [_ai, _name] call BIS_fnc_findInPairs;
	if (_index == -1) exitWith
	{
		if (not _allEnabled) then
		{
			_ai pushBack [_name, _settings];
		};
	};

	if (_allEnabled) exitWith
	{
		_ai deleteAt _index;
		if (count _ai == 0) then
		{
			_unit setVariable ["SPM_AI", nil];
		};
	};

	_ai select _index set [1, _settings];
};

OO_TRACE_DECL(SPM_Util_AIGet) =
{
	params ["_unit", "_name"];

	private _ai = _unit getVariable "SPM_AI";
	if (isNil "_ai") exitWith { +SPM_Util_AIAllEnabled };

	private _index = [_ai, _name] call BIS_fnc_findInPairs;
	if (_index == -1) exitWith { +SPM_Util_AIAllEnabled };

	_ai select _index select 1
};

OO_TRACE_DECL(SPM_Util_AIApply) =
{
	params ["_unit", "_settings"];

	_unit disableAI "all";
	{
		_unit enableAI _x;
	} forEach _settings;
};

OO_TRACE_DECL(SPM_Util_AIOnlyMove) =
{
	params ["_units"];

	{
		private _unit = _x;
		if (not isNull _unit) then
		{
			_unit disableAI "all";
			_unit enableAI "move";
			_unit enableAI "path";
			_unit enableAI "teamswitch";
			{
				_unit forgetTarget (_x select 1);
			} forEach (_unit targetsQuery [objNull, sideUnknown, "", [], 0]);
		};
	} forEach _units;
};

OO_TRACE_DECL(SPM_Util_AIRevokeMove) =
{
	params ["_units"];

	{
		private _unit = _x;
		if (not isNull _unit) then
		{
			_unit disableAI "move";
		};
	} forEach _units;
};

OO_TRACE_DECL(SPM_Util_AIGrantMove) =
{
	params ["_units"];

	{
		private _unit = _x;
		if (not isNull _unit) then
		{
			_unit enableAI "move";
		};
	} forEach _units;
};

OO_TRACE_DECL(SPM_Util_AIFullCapability) =
{
	params ["_units"];

	{
		private _unit = _x;
		if (not isNull _unit) then
		{
			_unit enableAI "all";
		};
	} forEach _units;
};

OO_TRACE_DECL(SPM_Util_WaitForVehicleToMove) =
{
	params ["_vehicle", "_distance", "_movementTime", "_distanceTime"];

	private _origin = getPos _vehicle;

	[{ not alive _vehicle || { speed _vehicle > 1 } }, _movementTime, 0.1] call JB_fnc_timeoutWaitUntil;

	if (speed _vehicle > 1) then
	{
		[{ not alive _vehicle || { _origin distance _vehicle > _distance } }, _distanceTime, 0.1] call JB_fnc_timeoutWaitUntil;
	};
};

OO_TRACE_DECL(SPM_Util_HasLoadedWeapons) =
{
	private _vehicle = _this select 0;

	if (_vehicle isKindOf "Man") exitWith { primaryWeapon _vehicle != "" || secondaryWeapon _vehicle != "" || handgunWeapon _vehicle != "" };

	private _hasLoadedWeapons = false;
	{
		private _type = _x select 0;
		if (not (getText (configFile >> "CfgMagazines" >> _type >> "ammo") in ["CMflare_Chaff_Ammo", "Laserbeam"])) exitWith
		{
			_hasLoadedWeapons = true;
		};
	} forEach (magazinesAllTurrets _vehicle);

	_hasLoadedWeapons;
};

OO_TRACE_DECL(SPM_Util_ExitRoads) =
{
	params ["_originRoad", "_center", "_radius"];

	private _intersections = [];
	private _ends = [];
	private _exits = [];

	{
		_ends pushBack [_originRoad, _x];
	} forEach roadsConnectedTo _originRoad;

	{
		private _run = [_x select 0, _x select 1, _center, _radius] call SPM_Nav_RoadRun;
		private _end = _run select (count _run - 1);

		switch (count roadsConnectedTo _end) do
		{
			case 1: {};

			case 2: { _exits pushBack [_run select (count _run - 2), _end] };

			default
			{
				if (not (_end in _intersections)) then
				{
					_intersections pushBack _end;

					private _endNeighbor = _run select (count _run - 2);
					{
						if (_x != _endNeighbor) then
						{
							_ends pushBack [_end, _x];
						};
					} forEach roadsConnectedTo _end;
				};
			}
		};
	} forEach _ends;

	_exits
};

// Find a road that starts in the specified area and leaves the strongpoint
OO_TRACE_DECL(SPM_Util_GetRoadSpawnpoint) =
{
	params ["_strongpoint", "_center", "_radius"];

	//TODO: Take center, inner/outer radii parameters, then look for a road that starts in the ring and leaves the strongpoint
	private _strongpointCenter = OO_GET(_strongpoint,Strongpoint,Position);
	private _strongpointRadius = OO_GET(_strongpoint,Strongpoint,Radius);

	private _spawnpoint = [];
	
	private _baseToCenterDirection = (getMarkerPos "respawn_west") getDir _strongpointCenter;

	private _originRoad = [_center, _radius min 200] call BIS_fnc_nearestRoad;

	if (not isNull _originRoad) then
	{
		private _exits = [_originRoad, _strongpointCenter, _strongpointRadius] call SPM_Util_ExitRoads;

		_exits = _exits select
		{
			private _roadToCenterDirection = (_x select 1) getDir _strongpointCenter;
			private _roadEntryDirection = (_x select 1) getDir (_x select 0);

			([_roadToCenterDirection, _roadEntryDirection] call SPM_Util_MinimumSweepAngle) < 60 && { ([_roadToCenterDirection, _baseToCenterDirection] call SPM_Util_MinimumSweepAngle) > 60 }
		};

		if (count _exits > 0) then
		{
			private _exit = selectRandom _exits;
			private _exitPosition = getPos (_exit select 1) vectorAdd [-0.25 + random 0.5, -0.25 + random 0.5, 0];

			_spawnpoint = [_exitPosition, _exitPosition getDir (_exit select 0)];
		};
	};

	_spawnpoint
};

OO_TRACE_DECL(SPM_Util_GetGroundSpawnpoint) =
{
	params ["_strongpoint", "_minDistance", "_maxDistance"];

	private _center = OO_GET(_strongpoint,Strongpoint,Position);
	private _radius = OO_GET(_strongpoint,Strongpoint,Radius);

	private _innerArea = pi * (_radius + _minDistance)^2;
	private _outerArea = pi * (_radius + _maxDistance)^2;
	private _area = _outerArea - _innerArea;

	private _positions = [_center, _radius + _minDistance, _radius + _maxDistance, (sqrt _area) / 20] call SPM_Util_SampleAreaGrid; // 400 samples
	[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, 0, 45] call SPM_Util_ExcludeSamplesBySurfaceNormal;
	[_positions, 6.0, ["FENCE", "WALL", "BUILDING", "ROCK"]] call SPM_Util_ExcludeSamplesByProximity;

	private _centerToHeadquarters = _center getDir (getPos Headquarters);

	private _position = [];
	while { count _positions > 0 && count _position == 0 } do
	{
		_position = _positions deleteAt (floor random count _positions);
		if ([_center getDir _position, _centerToHeadquarters] call SPM_Util_MinimumSweepAngle < 30) then { _position = [] };
	};

	if (count _position == 0) then
	{
		private _headquartersToCenterVector = (getPos Headquarters) vectorFromTo _center;
		_position = _center vectorAdd (_headquartersToCenterVector vectorMultiply (_radius + (_maxDistance + _minDistance) * 0.5));
		_position = [_position, _center] call SPM_Util_KeepOutOfWater;
	};

	[_position, _position getDir _center]
};

OO_TRACE_DECL(SPM_Util_GetAirSpawnpoint) =
{
	params ["_strongpoint", "_distance", "_altitude"];

	private _center = OO_GET(_strongpoint,Strongpoint,Position);
	private _radius = OO_GET(_strongpoint,Strongpoint,Radius);

	private _centerToHeadquarters = _center getDir (getPos Headquarters);

	private _position = [];
	while { count _position == 0 } do
	{
		private _direction = random 360;
		if ([_direction, _centerToHeadquarters] call SPM_Util_MinimumSweepAngle > 30) then
		{
			_position = _center vectorAdd ([(_radius + _distance) * sin _direction, (_radius + _distance) * cos _direction, _altitude])
		};
	};

	[_position, _position getDir _center]
};

OO_TRACE_DECL(SPM_Util_GroupMembersAreDead) =
{
	private _groups = _this select 0;

	if (typeName _groups == typeName grpNull) exitWith
	{
		{ alive _x } count units _groups == 0
	};

	private _livingMembers = 0;
	{
		_livingMembers = { alive _x } count units _x;
		if (_livingMembers > 0) exitWith {};
	} forEach _groups;

	_livingMembers == 0
};

OO_TRACE_DECL(SPM_Util_PositionIsInsideObject) =
{
	params ["_position", "_object"];

	_position = _object worldToModel _position;

	private _boundingBox = boundingBoxReal _object;

	private _negative = _boundingBox select 0;
	private _positive = _boundingBox select 1;

	if (_position select 0 < _negative select 0 || _position select 0 > _positive select 0) exitWith { false };
	if (_position select 1 < _negative select 1 || _position select 1 > _positive select 1) exitWith { false };
	if (_position select 2 < _negative select 2 || _position select 2 > _positive select 2) exitWith { false };

	true
};

//test_EmptyObjectForSmoke

OO_TRACE_DECL(SPM_Util_Fire) =
{
	_this spawn
	{
		params ["_parent", "_offset", "_duration", "_onCompletion", "_passthrough"];

		private _fire = createvehicle ["test_EmptyObjectForFireBig" , getPos _parent vectorAdd _offset, [], 0, "can_collide"];
		[{ isNull _parent }, _duration] call JB_fnc_timeoutWaitUntil;
		deleteVehicle _fire;
		[_passthrough] call _onCompletion;
	};
};

OO_TRACE_DECL(SPM_Util_MarkPositions) =
{
	params ["_positions", "_prefix", "_color"];

	private _markerName = "";

	private _markerIndex = 0;
	while { true } do
	{
		_markerName = format ["%1-%2", _prefix, _markerIndex];
		if ((getMarkerPos _markerName) select 0 == 0) exitWith {};
		deleteMarker _markerName;
		_markerIndex = _markerIndex + 1;
	};

	{
		_markerName = format ["%1-%2", _prefix, _forEachIndex];
		private _marker = createMarker [_markerName, _x];
		_marker setMarkerType "mil_dot";
		_marker setMarkerColor _color;
	} forEach _positions;
};

OO_TRACE_DECL(SPM_Util_SampleAreaGrid) =
{
	params ["_center", "_innerRadius", "_outerRadius", "_stepSize"];

	private _steps = floor (_outerRadius / _stepSize);
	private _position = [0, 0, 0];
	private _outerRadiusSqr = _outerRadius ^ 2;
	private _innerRadiusSqr = _innerRadius ^ 2;
	private _distanceSqr = 0;

	private _positions = [];

	for "_x" from -_steps to _steps do
	{
		_position set [0, (_center select 0) - (_x * _stepSize)];
		for "_y" from -_steps to _steps do
		{
			_position set [1, (_center select 1) - (_y * _stepSize)];
		
			_distanceSqr = _center distanceSqr _position;

			if (_distanceSqr < _innerRadiusSqr) then
			{
				_y = abs _y; // We found a point inside, so skip to the mirrored point inside
			}
			else
			{
				if (_distanceSqr <= _outerRadiusSqr) then
				{
					_positions pushBack +_position;
				};
			};
		};
	};

	_positions
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesBySurfaceType) =
{
	params ["_positions", "_surfaceTypes", "_excludedPositions"];

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _excludeRoadSurfaces = "#GdtRoad" in _surfaceTypes;
	private _excludeWaterSurfaces = "#GdtWater" in _surfaceTypes;

	private _position = [];

	for "_i" from (count _positions - 1) to 0 step -1 do
	{
		_position = _positions select _i;

		if (_excludeRoadSurfaces && { isOnRoad _position } || { (_excludeWaterSurfaces && { surfaceIsWater _position }) } || { surfaceType _position in _surfaceTypes }) then
		{
			_positions deleteAt _i;
			if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
		};
	};
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesBySurfaceNormal) =
{
	params ["_positions", "_minAngle", "_maxAngle", "_excludedPositions"];

	private _minSin = sin _minAngle;
	private _maxSin = sin _maxAngle;

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _position = [];
	private _slopeSin = 0;

	for "_i" from (count _positions - 1) to 0 step -1 do
	{
		_position = _positions select _i;

		_slopeSin = (surfaceNormal _position) select 2;
		if (_slopeSin > _minSin && _slopeSin < _maxSin) then
		{
			_positions deleteAt _i;
			if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
		};
	};
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesByHeightASL) =
{
	params ["_positions", "_minHeight", "_maxHeight", "_excludedPositions"];

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _position = [];

	for "_i" from (count _positions - 1) to 0 step -1 do
	{
		_position = _positions select _i;

		if (getTerrainHeightASL _position < _minHeight || { getTerrainHeightASL _position > _maxHeight }) then
		{
			_positions deleteAt _i;
			if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
		};
	};
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesByProximity) =
{
	params ["_positions", "_proximity", "_proximateTypes", "_excludedPositions"];

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _excludeBuildings = "BUILDING" in _proximateTypes;
	private _excludeRoads = "ROAD" in _proximateTypes;
	private _excludeWest = "WEST" in _proximateTypes;
	private _excludeEast = "EAST" in _proximateTypes;
	private _excludeIndependent = "INDEPENDENT" in _proximateTypes;
	private _excludeCivilian = "CIVILIAN" in _proximateTypes;
	private _excludeRocks = "ROCK" in _proximateTypes;

	private _excludeFaction = _excludeWest || _excludeEast || _excludeIndependent || _excludeCivilian;

	private _proximitySqr = _proximity ^ 2;

	private _position = [];
	private _entities = [];
	private _towardsHouse = [];
	private _towardsRock = [];
	private _deleted = false;

	for "_i" from (count _positions - 1) to 0 step -1 do
	{
		_position = _positions select _i;
		_deleted = false;

		_entities = if (_excludeFaction) then { _entities = _position nearEntities _proximity; } else { [] };

		switch (true) do
		{
			case (_excludeWest && { not isNil { { if (side _x == west) exitWith { true } } forEach _entities } }): { _deleted = true };
			case (_excludeEast && { not isNil { { if (side _x == east) exitWith { true } } forEach _entities } }): { _deleted = true };
			case (_excludeIndependent && { not isNil { { if (side _x == independent) exitWith { true } } forEach _entities } }): { _deleted = true };
			case (_excludeCivilian && { not isNil { { if (side _x == civilian) exitWith { true } } forEach _entities } }): { _deleted = true };
			case (count nearestTerrainObjects [_position, _proximateTypes, _proximity, false, true] > 0): { _deleted = true };
			case (_excludeRoads && { count (_position nearRoads _proximity) > 0 }): { _deleted = true };
			default
			{
				if (not _deleted && _excludeBuildings) then
				{
					private _buildings = nearestObjects [_position, ["Building"], _proximity + 50, false];

					{
						if (_x distanceSqr _position < _proximitySqr) exitWith { _deleted = true; };

						_towardsHouse = _position vectorFromTo getPos _x;
						if ([_position vectorAdd (_towardsHouse vectorMultiply _proximity), _x] call SPM_Util_PositionIsInsideObject) exitWith { _deleted = true; };
					} forEach _buildings;
				};

				if (not _deleted && _excludeRocks) then
				{
					private _objects = nearestTerrainObjects [_position, ["ROCK", "HIDE"], _proximity + 40, false, true]; // Largest rock object has a radius of over 35 meters

					{
						if (str _x find "stone_" != -1 || str _x find "rock_" != -1) then // sharp & blunt
						{
							if (_x distance _position < _proximity) exitWith { _deleted = true; };

							_towardsRock = _position vectorFromTo getPos _x;
							if ([_position vectorAdd (_towardsRock vectorMultiply _proximity), _x] call SPM_Util_PositionIsInsideObject) exitWith { _deleted = true; };
						};

						if (_deleted) exitWith {};
					} forEach _objects;
				};
			};
		};

		if (_deleted) then
		{
			_positions deleteAt _i;
			if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
		};
	};
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesByAreas) =
{
	params ["_positions", "_areas", "_excludedPositions"];

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _position = [];
	private _center = [];
	private _innerRadiusSqr = 0;
	private _outerRadiusSqr = 0;
	private _distanceSqr = 0;

	{
		_center = _x select 0;
		_innerRadiusSqr = (_x select 1) ^ 2;
		_outerRadiusSqr = (_x select 2) ^ 2;

		for "_i" from (count _positions - 1) to 0 step -1 do
		{
			_position = _positions select _i;

			_distanceSqr = _position distanceSqr _center;

			if (_distanceSqr >= _innerRadiusSqr && _distanceSqr <= _outerRadiusSqr) then
			{
				_positions deleteAt _i;
				if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
			};
		};
	} forEach _areas;
};

OO_TRACE_DECL(SPM_Util_ClosestPosition) =
{
	params ["_positions", "_key"];

	private _minimumDistanceSqr = 1e30;
	private _minimumDistancePosition = [];
	{
		private _distanceSqr = _x distanceSqr _key;
		if (_distanceSqr < _minimumDistanceSqr) then
		{
			_minimumDistanceSqr = _distanceSqr;
			_minimumDistancePosition = _x;
		}
	} forEach _positions;

	_minimumDistancePosition
};

OO_TRACE_DECL(SPM_Util_OpenPositionForVehicle) =
{
	params ["_center", "_radius"];

	private _positions = [_center, 0, _radius, 10] call SPM_Util_SampleAreaGrid;
	[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, 10.0, ["WALL", "BUILDING", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;

	if (count _positions == 0) exitWith { _center };

	selectRandom _positions
};

OO_TRACE_DECL(SPM_Util_OpenPositionForBoat) =
{
	params ["_center", "_radius"];

	private _positions = [_center, 0, _radius, 5] call SPM_Util_SampleAreaGrid;
	[_positions, 0, 2] call SPM_Util_ExcludeSamplesByHeightASL;
	[_positions, 5.0, ["WALL", "BUILDING", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;

	if (count _positions == 0) exitWith { _center };

	selectRandom _positions
};

OO_TRACE_DECL(SPM_Util_VehicleMobilityDamage) =
{
	params ["_vehicle"];

	private _hitPointsDamage = getAllHitPointsDamage _vehicle;
	private _names = _hitPointsDamage select 1;
	private _values = _hitPointsDamage select 2;

	private _numberSystems = 0;
	private _totalDamage = 0;
	{ if (_x find "wheel" >= 0 || { _x find "track" >= 0 }) then { _numberSystems = _numberSystems + 1; _totalDamage = _totalDamage + (_values select _forEachIndex) } } forEach _names;

	if (_numberSystems == 0) exitWith { 0.0 };

	_totalDamage / _numberSystems
};

OO_TRACE_DECL(SPM_Util_InArea) =
{
	params ["_position", "_area"];

	if (count _area == 0) exitWith { false };

	private _distance = if (count _area == 2) then
	{
		// Radius [_distance, _position]
		(_area select 1) distance _position
	}
	else
	{
		// Area [_distance, _position, _width, _height, _angle]
		([_position, _area select 1, _area select 2, _area select 3, _area select 4] call JB_fnc_distanceToArea)
	};

	if (_distance > (_area select 0)) exitWith { false };

	true
};

OO_TRACE_DECL(SPM_Util_HasOffensiveWeapons) =
{
	params ["_vehicle"];

	count (weapons _vehicle - ["CMFlareLauncher", "SmokeLauncher", "TruckHorn", "TruckHorn2", "TruckHorn3", "MiniCarHorn", "CarHorn", "Laserdesignator_mounted"]) > 0
};