/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ForceRating_Create) =
{
	params ["_forceRating", "_vehicle", "_rating"];

	OO_SET(_forceRating,ForceRating,Vehicle,_vehicle);
	OO_SET(_forceRating,ForceRating,Rating,_rating);
};

OO_BEGIN_STRUCT(ForceRating);
	OO_OVERRIDE_METHOD(ForceRating,RootStruct,Create,SPM_ForceRating_Create);
	OO_DEFINE_PROPERTY(ForceRating,Vehicle,"OBJECT",objNull);
	OO_DEFINE_PROPERTY(ForceRating,Rating,"SCALAR",0);
OO_END_STRUCT(ForceRating);

OO_TRACE_DECL(SPM_ForceUnit_GetGroups) =
{
	params ["_forceUnit"];

	private _groups = [];
	{
		if (alive _x) then { _groups pushBackUnique group _x };
	} forEach OO_GET(_forceUnit,ForceUnit,Units);

	_groups
};

OO_TRACE_DECL(SPM_ForceUnit_Create) =
{
	params ["_forceUnit", "_vehicle", "_units"];

	OO_SET(_forceUnit,ForceUnit,Vehicle,_vehicle);
	OO_SET(_forceUnit,ForceUnit,Units,_units);
};

OO_BEGIN_STRUCT(ForceUnit);
	OO_OVERRIDE_METHOD(ForceUnit,RootStruct,Create,SPM_ForceUnit_Create);
	OO_DEFINE_METHOD(ForceUnit,GetGroups,SPM_ForceUnit_GetGroups);
	OO_DEFINE_PROPERTY(ForceUnit,Vehicle,"OBJECT",objNull);
	OO_DEFINE_PROPERTY(ForceUnit,Units,"ARRAY",[]);
OO_END_STRUCT(ForceUnit);

OO_TRACE_DECL(SPM_Force_GetAdjustedForceValue) =
{
	params ["_forceValue", "_difficulty"];

	_forceValue * (if (_difficulty <= 5) then { [_difficulty, 1, 5, 0.5, 1.0] call SPM_Util_MapValue } else { [_difficulty, 5, 10, 1.0, 2.0] call SPM_Util_MapValue })
};

OO_TRACE_DECL(SPM_Force_GetForceRatings) =
{
	private _units = _this select 0;
	private _unitTypeRatings = _this select 1;

	private _vehicles = [];
	{
		private _vehicle = vehicle _x;
		if (_x in [driver _vehicle, gunner _vehicle, commander _vehicle] && { not (_vehicle isKindOf "ParachuteBase") } ) then
		{
			_vehicles pushBackUnique _vehicle;
		}
		else
		{
			_vehicles pushBackUnique _x;
		};
	} forEach _units;

	private _force = [];
	{
		private _vehicleType = typeOf _x;

		private _unitTypeRating = [];
		{
			if (_x select 0 == _vehicleType) exitWith { _unitTypeRating = _x select 1 };
		} forEach _unitTypeRatings;

		if (count _unitTypeRating > 0) then
		{
			private _ratingMultiplier = 0;
				
			if (_x isKindOf "Man") then
			{
				if (lifeState _x in ["HEALTHY", "INJURED"]) then { _ratingMultiplier = 1 };
			}
			else
			{
				_ratingMultiplier = { not isNull _x && { lifeState _x in ["HEALTHY", "INJURED"] } } count [driver _x, gunner _x, commander _x];
			};

			if (not canMove _x) then
			{
				_ratingMultiplier = _ratingMultiplier * 0.5;
			};

			private _rating = (_unitTypeRating select 0) * _ratingMultiplier;
			_force pushBack ([_x, _rating] call OO_CREATE(ForceRating));
		};
	} forEach _vehicles;

	_force
};

OO_TRACE_DECL(SPM_Force_Rebalance) =
{
	params ["_westForce", "_eastForce", "_eastCallups", "_eastForceReserves", ["_difficulty", 5, [0]]];

	private _changes = [[], [], [], _eastForceReserves];

	private _eastUnitsActiveForce = [];
	private _eastUnitsRetiringForce = [];
	{
		private _retiring = ((group driver OO_GET(_x,ForceRating,Vehicle)) getVariable "SPM_Retiring");
		if (isNil "_retiring") then { _eastUnitsActiveForce pushBack _x } else { _eastUnitsRetiringForce pushBack _x };
	} forEach _eastForce;

	private _westRating = 0;
	{ _westRating = _westRating + OO_GET(_x,ForceRating,Rating); } forEach _westForce;

	private _westRatingAverage = if (count _westForce == 0) then { 0 } else { _westRating / count _westForce };

	private _eastRating = 0;
	{ _eastRating = _eastRating + OO_GET(_x,ForceRating,Rating); } forEach _eastUnitsActiveForce;

	private _forceDeficit = ([_westRating, _difficulty] call SPM_Force_GetAdjustedForceValue) - _eastRating;

	// Reinstate

	while { _forceDeficit > 0 } do
	{
		private _idealRating = _westRatingAverage min _forceDeficit;
		private _idealRatingHalf = _idealRating * 0.5;
		private _idealRatingDouble = _idealRating * 2.0;

		private _closestMatch = [-1, 1e30];
		{
			private _unitRating = OO_GET(_x,ForceRating,Rating);
			private _difference = abs (idealRating - _unitRating);
			if (_difference < (_closestMatch select 1) && { _unitRating >= _idealRatingHalf && _unitRating <= _idealRatingDouble } && { OO_GET(_x,ForceRating,Rating) < _forceDeficit }) then
			{
				_closestMatch = [_forEachIndex, _difference];
			}
		} forEach _eastUnitsRetiringForce;

		if (_closestMatch select 0 == -1) exitWith {};

		private _retiredUnit = _eastUnitsRetiringForce deleteAt (_closestMatch select 0);

		CHANGES(_changes,reinstate) pushBack OO_GET(_retiredUnit,ForceRating,Vehicle);

		_forceDeficit = (_forceDeficit - OO_GET(_retiredUnit,ForceRating,Rating)) max 0;
	};

	// Call up

	while { _forceDeficit > 0 && _eastForceReserves > 0 } do
	{
		private _ratingLimit = _forceDeficit min _eastForceReserves;

		// Compute weights for each unit type that can be called up, along with a sum of those weights

		private _weightSum = 0.0;
		private _weights = _eastCallups apply
		{
			private _rating = _x select 1;
			private _ratingValue = (_rating select 0) * (_rating select 1);

			private _weight = 0;
			if (_ratingValue <= _ratingLimit) then
			{
				_weight = 1 / (abs (_ratingValue - _westRatingAverage) + 10);
				_weightSum = _weightSum + _weight;
			};

			_weight
		};

		if (_weightSum == 0.0) exitWith {};

		// Select a value at random from the weight sum and use that to track down which unit type it refers to.  Heavily-weighted
		// unit types will be chosen more frequently than lightly-weighted unit types.

		private _weight = random _weightSum;

		_weightSum = 0.0;
		private _match = -1;
		{
			_weightSum = _weightSum + _x;
			if (_weightSum >= _weight) exitWith { _match = _forEachIndex };
		} forEach _weights;

		private _calledUpRating = _eastCallups select _match;

		CHANGES(_changes,callup) pushBack _calledUpRating;

		private _ratings = _calledUpRating select 1;
		private _rating = (_ratings select 0) * (_ratings select 1);
		_forceDeficit = (_forceDeficit - _rating) max 0;
		_eastForceReserves = (_eastForceReserves - _rating) max 0;
	};

	_forceDeficit = -_forceDeficit;

	// Retire

	while { _forceDeficit > 0 } do
	{
		private _closestMatch = [-1, 0];
		{
			private _rating = OO_GET(_x,ForceRating,Rating);
			if (_rating > (_closestMatch select 1) && { _rating < _forceDeficit * 2.0 }) then
			{
				_closestMatch = [_forEachIndex, _rating];
			}
		} forEach _eastUnitsActiveForce;

		if (_closestMatch select 0 == -1) exitWith {};

		private _retiredUnit = _eastUnitsActiveForce deleteAt (_closestMatch select 0);

		CHANGES(_changes,retire) pushBack OO_GET(_retiredUnit,ForceRating,Vehicle);

		_forceDeficit = _forceDeficit - OO_GET(_retiredUnit,ForceRating,Rating);
	};

	_changes set [3, _eastForceReserves];

	_changes
};

OO_TRACE_DECL(SPM_Force_DeleteForceUnit) =
{
	params ["_forceUnit"];

	{
		if (alive _x) then { deleteVehicle _x; };
	} forEach OO_GET(_forceUnit,ForceUnit,Units);

	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	// The only dead bodies we delete are the ones in vehicles
	{
		if (not alive _x && vehicle _x != _x) then { deleteVehicle _x };
	} forEach crew _vehicle;

	if (alive _vehicle) then
	{
		deleteVehicle _vehicle;
	};
};

OO_TRACE_DECL(SPM_Force_DeleteForceUnits) =
{
	params ["_forceUnits", "_criterion"];

	for "_i" from (count _forceUnits - 1) to 0 step -1 do
	{
		private _x = _forceUnits select _i;
		if (call _criterion) then
		{
			[_x] call SPM_Force_DeleteForceUnit;

			_forceUnits deleteAt _i;
		};
	};
};

OO_TRACE_DECL(SPM_Force_RemoveForceUnits) =
{
	params ["_forceUnits", "_condition"];

	private _x = [];
	for "_i" from (count _forceUnits - 1) to 0 step -1 do
	{
		_x = _forceUnits select _i;
		if (call _condition) then
		{
			_forceUnits deleteAt _i;
		};
	};
};

OO_TRACE_DECL(SPM_Force_SalvageForceUnit) =
{
	params ["_forceCategory", "_key"];

	private _forceUnits = OO_GET(_forceCategory,ForceCategory,ForceUnits);
	private _ratings = OO_GET(_forceCategory,ForceCategory,RatingsEast);
	private _reserves = OO_GET(_forceCategory,ForceCategory,Reserves);

	private _index = _key;

	if (typeName _key != typeName 0) then { _index = [_forceUnits, _key] call SPM_Force_FindForceUnit };

	if (_index < 0) exitWith { _reserves };

	private _forceUnit = _forceUnits deleteAt _index;

	private _unitForce = [OO_GET(_forceUnit,ForceUnit,Units), _ratings] call SPM_Force_GetForceRatings;
	if (count _unitForce > 0) then
	{
		_reserves = _reserves + OO_GET(_unitForce select 0,ForceRating,Rating);
	};

	[_forceUnit] call SPM_Force_DeleteForceUnit;

	OO_SET(_forceCategory,ForceCategory,Reserves,_reserves);
};

OO_TRACE_DECL(SPM_Force_RetireOnFoot) =
{
	params ["_units", "_retireCallback", "_passthrough"];

	for "_i" from (count _units - 1) to 0 step -1 do
	{
		private _forceUnit = _units select _i;
		if (not alive (OO_GET(_forceUnit,ForceUnit,Vehicle))) then
		{
			{
				if ([_x] call SPM_Util_GroupMembersAreDead) then
				{
					_units deleteAt _i;
				}
				else
				{
					if (not (_x getVariable ["SPM_Retiring", false])) then
					{
						[_i, _passthrough] call _retireCallback;
					};
				};
			} forEach ([] call OO_METHOD(_forceUnit,ForceUnit,GetGroups));
		};
	};
};

OO_TRACE_DECL(SPM_Force_FindForceUnit) =
{
	params ["_units", "_key"];

	private _index = -1;

	switch (typeName _key) do
	{
		case typeName objNull:
		{
			if (not isNull _key) then
			{
				{
					if (_key == OO_GET(_x,ForceUnit,Vehicle)) exitWith
					{
						_index = _forEachIndex;
					};
				} forEach _units;
			};
		};

		case typeName grpNull:
		{
			if (not isNull _key) then
			{
				{
					if (_key in ([] call OO_METHOD(_x,ForceUnit,GetGroups))) exitWith
					{
						_index = _forEachIndex;
					};
				} forEach _units;
			};
		};

		default
		{
			_index = [_units, OO_GET(_key,ForceUnit,Vehicle)] call SPM_Force_FindForceUnit;
			if (_index == -1) then
			{
				{
					_index = [_units, _x] call SPM_Force_FindForceUnit;
					if (_index != -1) exitWith {};
				} forEach ([] call OO_METHOD(_key,ForceUnit,GetGroups));
			};
		};
	};

	_index;
};

OO_TRACE_DECL(SPM_Force_GetForceLevels) =
{
	params ["_category", "_proximity", "_units", "_ratings"];

	if (_proximity >= 0) then
	{
		private _area = OO_GET(_category,ForceCategory,Area);
		private _center = OO_GET(_area,StrongpointArea,Center);
		private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
		private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

		_innerRadius = (_innerRadius - _proximity) max 0;
		_outerRadius = (_outerRadius + _proximity);

		_units = [_center, _innerRadius, _outerRadius, _units] call SPM_Util_GetUnits;
	};

	([_units, _ratings] call SPM_Force_GetForceRatings)
};

OO_TRACE_DECL(SPM_Force_GetForceLevelsWest) =
{
	params ["_category", "_proximity"];

	private _side = OO_GET(_category,ForceCategory,SideWest);
	private _units = allUnits select { side _x == _side && { lifeState _x in ["HEALTHY", "INJURED"] } };

	([_category, _proximity, _units, OO_GET(_category,ForceCategory,RatingsWest)] call SPM_Force_GetForceLevels)
};

OO_TRACE_DECL(SPM_Force_GetForceLevelsEast) =
{
	params ["_category", "_proximity"];

	private _units = OO_GET(_category,ForceCategory,ForceUnits) apply { OO_GET(_x,ForceUnit,Vehicle) };

	([_category, _proximity, _units, OO_GET(_category,ForceCategory,RatingsEast)] call SPM_Force_GetForceLevels)
};

OO_TRACE_DECL(SPM_ForceCategory_Delete) =
{
	params ["_category"];

	private _sideWest = OO_GET(_category,ForceCategory,SideWest);

	private _forceUnits = OO_GET(_category,ForceCategory,ForceUnits);
	while { count _forceUnits > 0 } do
	{
		private _forceUnit = _forceUnits deleteAt 0;
		private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);
		if (alive _vehicle) then
		{
			if (side _vehicle != _sideWest) then
			{
				[_forceUnit] call SPM_Force_DeleteForceUnit;
			};
		};
	};

	[] call OO_METHOD_PARENT(_category,Root,Delete,Category);
};

OO_BEGIN_SUBCLASS(ForceCategory,Category);
	OO_OVERRIDE_METHOD(ForceCategory,Root,Delete,SPM_ForceCategory_Delete);
	OO_DEFINE_METHOD(ForceCategory,GetForceLevelsWest,SPM_Force_GetForceLevelsWest);
	OO_DEFINE_METHOD(ForceCategory,GetForceLevelsEast,SPM_Force_GetForceLevelsEast);
	OO_DEFINE_PROPERTY(ForceCategory,Area,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(ForceCategory,Reserves,"SCALAR",1e30);
	OO_DEFINE_PROPERTY(ForceCategory,SideWest,"SIDE",west);
	OO_DEFINE_PROPERTY(ForceCategory,SideEast,"SIDE",east);
	OO_DEFINE_PROPERTY(ForceCategory,RatingsWest,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ForceCategory,RatingsEast,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ForceCategory,CallupsEast,"ARRAY",[]); // Make sure there is a rating for every callup
	OO_DEFINE_PROPERTY(ForceCategory,ForceUnits,"ARRAY",[]);
OO_END_SUBCLASS(ForceCategory);