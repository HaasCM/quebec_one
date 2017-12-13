/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

if (isNil "SPM_StrongpointDifficulty") then { SPM_StrongpointDifficulty = [] };
SPM_StrongpointDifficulty pushBack ["parmor", 5];

SPM_Armor_RatingsWest =
[
	["B_MBT_01_cannon_F", [50, 3]],
	["B_MBT_01_TUSK_F", [50, 3]],
	["B_T_MBT_01_cannon_F", [50, 3]],
	["B_T_MBT_01_TUSK_F", [50, 3]],
	["B_APC_Wheeled_01_cannon_F", [25, 3]],

	["B_Heli_Attack_01_F", [75, 2]],
	["B_Heli_Attack_01_dynamicLoadout_F", [75, 2]],
	["B_Plane_CAS_01_F", [150, 1]],
	["B_Plane_CAS_01_dynamicLoadout_F", [150, 1]],

	["O_MBT_02_cannon_F", [50, 3]],
	["O_APC_Tracked_02_cannon_F", [30, 3]],
	["O_APC_Wheeled_02_rcws_F", [20, 3]],

	["O_Plane_CAS_02_F", [150, 1]],
	["O_Plane_CAS_02_dynamicLoadout_F", [150, 1]],
	["O_Heli_Attack_02_F", [100, 2]],
	["O_Heli_Attack_02_dynamicLoadout_F", [100, 2]],
	["O_Heli_Light_02_F", [50, 2]],
	["O_Heli_Light_02_dynamicLoadout_F", [50, 2]],
	["O_T_VTOL_02_infantry_F", [100, 2]],
	["O_T_VTOL_02_infantry_dynamicLoadout_F", [100, 2]],

	["I_MBT_03_cannon_F", [50, 3]],

	["I_APC_tracked_03_cannon_F", [35, 3]],
	["I_APC_Wheeled_03_cannon_F", [25, 3]],
	["I_Plane_Fighter_03_CAS_F", [75, 1]]
];

SPM_Armor_CallupsEast =
[
	["O_MBT_02_cannon_F",
		[50, 3, {}]],
	["O_APC_Tracked_02_cannon_F",
		[30, 3, {}]],
	["O_APC_Wheeled_02_rcws_F",
		[20, 3,
			{
				(_this select 0) removeMagazines "96Rnd_40mm_G_belt";
				(_this select 0) removeWeapon "GMG_40mm";
			}
		]],

	["I_MBT_03_cannon_F",
		[50, 3, {}]],
	["I_APC_tracked_03_cannon_F",
		[35, 3, {}]],
	["I_APC_Wheeled_03_cannon_F",
		[25, 3, {}]],

	["O_Heli_Light_02_F", [50, 2,
			{
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["O_Heli_Light_02_dynamicLoadout_F", [50, 2,
			{
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["I_Heli_light_03_F", [35, 2,
			{
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["I_Heli_light_03_dynamicLoadout_F", [35, 2,
			{
				(_this select 0) flyInHeight (100 + random 200);
			}]]

];

SPM_Armor_RatingsEast = SPM_Armor_CallupsEast apply { [_x select 0, (_x select 1) select [0, 2]] };

OO_TRACE_DECL(SPM_Armor_Task_Patrol) =
{
	private _category = _this select 0;
	private _patrolGroup = _this select 1;

	private _area = OO_GET(_category,ForceCategory,Area);

	private _minRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _maxRadius = OO_GET(_area,StrongpointArea,OuterRadius);
	private _circumference = 2 * pi * ((_minRadius + _maxRadius) / 2.0);

	_task = [_patrolGroup, OO_GET(_area,StrongpointArea,Center), _minRadius, _maxRadius, random 1 < 0.5, _circumference * 0.05, _circumference * 0.1, 0, 0, 0] call SPM_fnc_patrolPerimeter;
	[_task, SPM_Armor_TC_Patrol, _category] call SPM_TaskOnComplete;
};

OO_TRACE_DECL(SPM_Armor_TC_Patrol) =
{
	params ["_task", "_category"];

	private _group = [_task] call SPM_TaskGetObject;

	[_category, _group] call SPM_Armor_Task_Patrol;
};

OO_TRACE_DECL(SPM_Armor_WS_Salvage) =
{
	params ["_leader", "_units", "_category"];

	[_category, group _leader] call SPM_Force_SalvageForceUnit;
};

OO_TRACE_DECL(SPM_Armor_Spawnpoint) =
{
	params ["_category"];

	private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
	private _area = OO_GET(_category,ForceCategory,Area);
	_spawnpoint = [_strongpoint, OO_GET(_area,StrongpointArea,Center), OO_GET(_area,StrongpointArea,OuterRadius)] call SPM_Util_GetRoadSpawnpoint;
	if (count _spawnpoint == 0) then
	{
		_spawnpoint = [_strongpoint, 0, 100] call SPM_Util_GetGroundSpawnpoint;
	};

	_spawnpoint;
};

OO_TRACE_DECL(SPM_Armor_Retire) =
{
	params ["_forceUnitIndex", "_category"];

	private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
	private _center = OO_GET(_strongpoint,Strongpoint,Position);
	private _radius = OO_GET(_strongpoint,Strongpoint,Radius);

	private _forceUnit = OO_GET(_category,ForceCategory,ForceUnits) select _forceUnitIndex;
	private _units = OO_GET(_forceUnit,ForceUnit,Units);

	// Can't retire duty units
	private _dutyUnits = [];
	{
		_dutyUnits append OO_GET(_x,ForceUnit,Units);
	} forEach OO_GET(_category,ArmorCategory,DutyUnits);

	if (count _dutyUnits != count (_dutyUnits - _units)) exitWith {}; //TODO: Rebalance needs a way to ignore certain units so it won't try to retire duty units

	private _toUnit = _center vectorFromTo getPos (_units select 0);

	private _exitPosition = _center vectorAdd (_toUnit vectorMultiply (_radius + 100));
	_exitPosition = [_exitPosition, _center] call SPM_Util_KeepOutOfWater;

	private _retirementPlaces = selectBestPlaces [_exitPosition, 100, "meadow-trees-houses-sea", 20, 1];

	{
		[_x] call SPM_DeletePatrolWaypoints;

		[units _x] call SPM_Util_AIOnlyMove;

		private _waypoint = [_x, (_retirementPlaces select 0) select 0] call SPM_AddPatrolWaypoint;
		[_waypoint, SPM_Armor_WS_Salvage, _category] call SPM_AddPatrolWaypointStatements;
		_x setVariable ["SPM_Retiring", true];
	} forEach ([] call OO_METHOD(_forceUnit,ForceUnit,GetGroups));
};

OO_TRACE_DECL(SPM_Armor_Reinstate) =
{
	private _category = _this select 0;
	private _forceUnitIndex = _this select 1;

	private _forceUnit = OO_GET(_category,ForceCategory,ForceUnits) select _forceUnitIndex;

	{
		[_x] call SPM_DeletePatrolWaypoints;

		[units _x] call SPM_Util_AIFullCapability;

		_x setVariable ["SPM_Retiring", nil];
		[_category, _x] call SPM_Armor_Task_Patrol;
	} forEach ([] call OO_METHOD(_forceUnit,ForceUnit,GetGroups));
};

OO_TRACE_DECL(SPM_Armor_CreateUnit) =
{
	params ["_category", "_position", "_direction", "_type"];

	private _sideEast = OO_GET(_category,ForceCategory,SideEast);
	private _vehicleDescriptor = [OO_GET(_category,ForceCategory,CallupsEast), _type] call BIS_fnc_getFromPairs;

	private _unitVehicle = [_type, _position, _direction, "fly"] call SPM_fnc_spawnVehicle;

	[_unitVehicle] call (_vehicleDescriptor select 2);

	private _crew = [_unitVehicle] call SPM_fnc_groupFromVehicleCrew;
	private _crewDescriptor = _crew select 1;

	[_crewDescriptor select 0] call SPM_Util_SubstituteRepairCrewman;
	
	_crewDescriptor = [[_unitVehicle]] + _crewDescriptor;

	private _unitGroup = [_sideEast, _crewDescriptor, [_unitVehicle, 0.0] call SPM_PositionInFrontOfVehicle, 0, true] call SPM_fnc_spawnGroup;

	[_category, _unitGroup] call OO_GET(_category,Category,InitializeObject);
	[_category, _unitVehicle] call OO_GET(_category,Category,InitializeObject);

	_unitGroup setSpeedMode "full";

	switch (true) do
	{
		case (_unitVehicle isKindOf "LandVehicle"):
		{
			[_unitVehicle, 40] call JB_fnc_limitSpeed;
		};
		case (_unitVehicle isKindOf "Air"):
		{
			_unitVehicle setPos (getPos _unitVehicle vectorAdd [0, 0, 50]);
		};
	};

	[_category, _unitGroup] call SPM_Armor_Task_Patrol;

	private _forceUnit = [_unitVehicle, units _unitGroup] call OO_CREATE(ForceUnit);

	OO_GET(_category,ForceCategory,ForceUnits) pushBack _forceUnit;
	private _force = [OO_GET(_forceUnit,ForceUnit,Units), OO_GET(_category,ForceCategory,RatingsEast)] call SPM_Force_GetForceRatings;

	private _reserves = OO_GET(_category,ForceCategory,Reserves) - OO_GET(_force select 0,ForceRating,Rating);
	OO_SET(_category,ForceCategory,Reserves,_reserves);

	_forceUnit
};

OO_TRACE_DECL(SPM_Armor_CallUp) =
{
	params ["_position", "_direction", "_category", "_type"];

	private _forceUnit = [_category, _position, _direction, _type] call SPM_Armor_CreateUnit;

	[OO_GET(_forceUnit,ForceUnit,Vehicle), 20, 10, 20] call SPM_Util_WaitForVehicleToMove;

	if (not alive OO_GET(_forceUnit,ForceUnit,Vehicle) || { _position distance OO_GET(_forceUnit,ForceUnit,Vehicle) < 10 }) exitWith
	{
		[_category, _forceUnit] call SPM_Force_SalvageForceUnit;
	};
};

OO_TRACE_DECL(SPM_Armor_Create) =
{
	params ["_category", "_area"];

	OO_SET(_category,ForceCategory,RatingsWest,SPM_Armor_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_Armor_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_Armor_RatingsEast);
	OO_SET(_category,ForceCategory,Area,_area);
};

OO_TRACE_DECL(SPM_Armor_BeginTemporaryDuty) =
{
	params ["_category"];

	private _forceUnits = OO_GET(_category,ForceCategory,ForceUnits);

	if (count _forceUnits == 0) exitWith { diag_log "SPM_Armor_BeginTemporaryDuty: No units available"; [objNull, []] call OO_CREATE(ForceUnit) };

	private _dutyUnits = OO_GET(_category,ArmorCategory,DutyUnits);
	private _dutyVehicles = _dutyUnits apply { OO_GET(_x,ForceUnit,Vehicle) };

	private _availableUnits = _forceUnits select { not isNull OO_GET(_x,ForceUnit,Vehicle) && { not (OO_GET(_x,ForceUnit,Vehicle) in _dutyVehicles) } };

	if (count _availableUnits == 0) exitWith { diag_log "SPM_Armor_BeginTemporaryDuty: No units available"; [objNull, []] call OO_CREATE(ForceUnit) };

	private _dutyUnit = selectRandom _availableUnits;

	_dutyUnits pushBack _dutyUnit;

	{
		[_x] call SPM_DeletePatrolWaypoints;
	} forEach ([] call OO_METHOD(_dutyUnit,ForceUnit,GetGroups));

	_dutyUnit
};

OO_TRACE_DECL(SPM_Armor_EndTemporaryDuty) =
{
	params ["_category", "_forceUnit"];

	private _dutyUnits = OO_GET(_category,ArmorCategory,DutyUnits);
	private _forceUnitGroups = [] call OO_METHOD(_forceUnit,ForceUnit,GetGroups);

	private _index = -1;
	{ private _groups = [] call OO_METHOD(_x,ForceUnit,GetGroups); if (count _groups != count (_groups - _forceUnitGroups)) exitWith { _index = _forEachIndex } } forEach _dutyUnits;

	if (_index == -1) exitWith { diag_log format ["SPM_Armor_EndTemporaryDuty: unknown duty unit: %1", _forceUnit] };

	{
		[_category, _x] call SPM_Armor_Task_Patrol;
	} forEach _forceUnitGroups;

	_dutyUnits deleteAt _index
};

//TODO: Have clients null out the vehicle based on GetInMan or some such thing
// If a vehicle is captured, null out the vehicle from its forceunit as if it had been destroyed
OO_TRACE_DECL(SPM_Armor_RemoveCapturedForceUnits) =
{
	params ["_forceUnits", "_sideWest"];

	for "_i" from (count _forceUnits - 1) to 0 step -1 do
	{
		private _forceUnit = _forceUnits select _i;
		if (side OO_GET(_forceUnit,ForceUnit,Vehicle) == _sideWest) then
		{
			OO_SET(_forceUnit,ForceUnit,Vehicle,objNull);
		};
	};
};

OO_TRACE_DECL(SPM_Armor_Update) =
{
	params ["_category"];

	private _updateTime = diag_tickTime + (30 + random 150);
	OO_SET(_category,Category,UpdateTime,_updateTime);

	private _sideWest = OO_GET(_category,ForceCategory,SideWest);

	private _forceUnits = OO_GET(_category,ForceCategory,ForceUnits);
	[_forceUnits, _sideWest] call SPM_Armor_RemoveCapturedForceUnits;
	private _dutyUnits = OO_GET(_category,ArmorCategory,DutyUnits);
	[_dutyUnits, _sideWest] call SPM_Armor_RemoveCapturedForceUnits;

	[_forceUnits, { not alive OO_GET(_x,ForceUnit,Vehicle) }] call SPM_Force_DeleteForceUnits; //TODO: Retire?

	private _difficulty = [SPM_StrongpointDifficulty, "parmor"] call BIS_fnc_getFromPairs;

	private _westForce = [1500] call OO_METHOD(_category,ForceCategory,GetForceLevelsWest);
	private _eastForce = [-1] call OO_METHOD(_category,ForceCategory,GetForceLevelsEast);

	// If necessary, pad the west's force so that the east always responds with a certain minimum force

	private _firstRebalance = OO_GET(_category,ArmorCategory,_FirstRebalance);

	private _minimumWestForce = if (_firstRebalance) then { OO_GET(_category,ArmorCategory,InitialMinimumWestForce) } else { OO_GET(_category,ArmorCategory,MinimumWestForce) };

	private _westRating = 0;
	{ _westRating = _westRating + OO_GET(_x,ForceRating,Rating); } forEach _westForce;

	private _minimumWestRating = 0;
	{ _minimumWestRating = _minimumWestRating + OO_GET(_x,ForceRating,Rating); } forEach _minimumWestForce;

	{
		if (_westRating >= _minimumWestRating) exitWith {};

		_westForce pushBack _x;
		_westRating = _westRating + OO_GET(_x,ForceRating,Rating);
	} forEach _minimumWestForce;

	private _changes = [_westForce, _eastForce, OO_GET(_category,ForceCategory,CallupsEast), OO_GET(_category,ForceCategory,Reserves), _difficulty] call SPM_Force_Rebalance;
	
	private _units = OO_GET(_category,ForceCategory,ForceUnits);
	{
		[[_units, { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, _category] call SPM_Armor_Retire;
	} forEach CHANGES(_changes,retire);

	{
		[[_units, { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, _category] call SPM_Armor_Reinstate;
	} forEach CHANGES(_changes,reinstate);

	if (count CHANGES(_changes,callup) > 0) then
	{
		private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
		private _spawnManager = OO_GET(_strongpoint,Strongpoint,SpawnManager);

		if (not _firstRebalance) then
		{
			private _spawnpoint = [_category] call SPM_Armor_Spawnpoint;
			{
				[_spawnpoint select 0, _spawnpoint select 1, SPM_Armor_CallUp, [_category, _x select 0]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);
			} forEach CHANGES(_changes,callup);
		}
		else
		{
			OO_SET(_category,ArmorCategory,_FirstRebalance,false);

			private _area = OO_GET(_category,ForceCategory,Area);
			private _center = OO_GET(_area,StrongpointArea,Center);
			private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
			private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

			private _positions = [_center, _innerRadius, _outerRadius, 50] call SPM_Util_SampleAreaGrid;
			[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
			[_positions, 0, 45] call SPM_Util_ExcludeSamplesBySurfaceNormal;
			[_positions, 10.0, ["WALL", "BUILDING", "ROCK"]] call SPM_Util_ExcludeSamplesByProximity;

			{
				private _position = _positions deleteAt (floor random count _positions);

				[_position, random 360, SPM_Armor_CallUp, [_category, _x select 0]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);
			} forEach CHANGES(_changes,callup);
		};
	};
};

OO_BEGIN_SUBCLASS(ArmorCategory,ForceCategory);
	OO_OVERRIDE_METHOD(ArmorCategory,Root,Create,SPM_Armor_Create);
	OO_OVERRIDE_METHOD(ArmorCategory,Category,Update,SPM_Armor_Update);
	OO_DEFINE_METHOD(ArmorCategory,BeginTemporaryDuty,SPM_Armor_BeginTemporaryDuty);
	OO_DEFINE_METHOD(ArmorCategory,EndTemporaryDuty,SPM_Armor_EndTemporaryDuty);
	OO_DEFINE_PROPERTY(ArmorCategory,InitialMinimumWestForce,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ArmorCategory,MinimumWestForce,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ArmorCategory,_FirstRebalance,"BOOL",true);
	OO_DEFINE_PROPERTY(ArmorCategory,DutyUnits,"ARRAY",[]);
OO_END_SUBCLASS(ArmorCategory);