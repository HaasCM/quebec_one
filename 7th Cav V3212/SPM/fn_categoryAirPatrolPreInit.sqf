/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

if (isNil "SPM_StrongpointDifficulty") then { SPM_StrongpointDifficulty = [] };
SPM_StrongpointDifficulty pushBack ["apatrol", 5];

#define CALLUP_DISTANCE 2000
#define RETIRE_DISTANCE 4000

SPM_AirPatrol_RatingsWest =
[
	["B_APC_Tracked_01_AA_F", [50, 3]],
	["B_Plane_Fighter_01_F", [100, 1]],
	["B_Plane_Fighter_01_Stealth_F", [100, 1]],

	["O_Plane_Fighter_02_F", [100, 1]],
	["O_Plane_Fighter_02_Stealth_F", [150, 1]],

	["I_Plane_Fighter_03_AA_F", [100, 1]],
	["I_Plane_Fighter_03_dynamicLoadout_F", [100, 1]],
	["I_Plane_Fighter_04_F", [100, 1]]
];

SPM_AirPatrol_CallupsEast =
[
	["O_Plane_Fighter_02_F", [100, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["O_Plane_Fighter_02_Stealth_F", [150, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]],

	["I_Plane_Fighter_03_AA_F", [100, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["I_Plane_Fighter_03_dynamicLoadout_F", [100, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["I_Plane_Fighter_04_F", [100, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]]
];

SPM_AirPatrol_CallupsEastOld =
[
	["O_T_VTOL_02_infantry_F", [50, 2,
			{
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["O_T_VTOL_02_infantry_dynamicLoadout_F", [50, 2,
			{
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["O_Plane_CAS_02_F", [100, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["O_Plane_CAS_02_dynamicLoadout_F", [100, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["O_Plane_Fighter_02_F", [100, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["O_Plane_Fighter_02_Stealth_F", [150, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]],

	["I_Plane_Fighter_03_CAS_F", [100, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["I_Plane_Fighter_03_AA_F", [100, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["I_Plane_Fighter_03_dynamicLoadout_F", [100, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]],
	["I_Plane_Fighter_04_F", [100, 1,
			{
				(_this select 0) engineOn true;
				(_this select 0) setVelocityModelSpace [0, 300 * 0.2778, 0];
				(_this select 0) flyInHeight (100 + random 200);
			}]]
];

SPM_AirPatrol_RatingsEast = SPM_AirPatrol_CallupsEast apply { [_x select 0, (_x select 1) select [0, 2]] };

SPM_WS_SalvageAirPatrol =
{
	params ["_leader", "_units", "_category"];

	[_category, group _leader] call SPM_Force_SalvageForceUnit;
};

SPM_AirPatrol_Retire =
{
	params ["_forceUnitIndex", "_category"];

	private _area = OO_GET(_category,ForceCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Center);
	private _radius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _awayFromBase = (getMarkerPos "respawn_west") vectorFromTo _center;
	private _perpendicular = [_awayFromBase select 1, -(_awayFromBase select 0), 0];

	private _position = _center vectorAdd (_awayFromBase vectorMultiply (_radius + RETIRE_DISTANCE));
	_position = _position vectorAdd (_perpendicular vectorMultiply (-500 + random 1000)) vectorAdd [0, 0, 100 + random 200];

	private _forceUnit = OO_GET(_category,ForceCategory,ForceUnits) select _forceUnitIndex;

	{
		[_x] call SPM_DeletePatrolWaypoints;

		[units _x] call SPM_Util_AIOnlyMove;

		private _waypoint = [_x, _position] call SPM_AddPatrolWaypoint;
		[_waypoint, SPM_WS_SalvageAirPatrol, _category] call SPM_AddPatrolWaypointStatements;
		_x setVariable ["SPM_Retiring", true];
	} forEach ([] call OO_METHOD(_forceUnit,ForceUnit,GetGroups));
};

SPM_AirPatrol_Reinstate =
{
	params ["_forceUnitIndex", "_category"];

	private _forceUnit = OO_GET(_category,ForceCategory,ForceUnits) select _forceUnitIndex;

	{
		[_x] call SPM_DeletePatrolWaypoints;

		[units _x] call SPM_Util_AIFullCapability;

		_x setVariable ["SPM_Retiring", nil];
		[_x, _category] call SPM_AirPatrol_Task_Patrol;
	} forEach OO_GET(_forceUnit,ForceUnit,GetGroups);
};

SPM_AirPatrol_Task_Patrol =
{
	params ["_patrolGroup", "_category"];

	private _area = OO_GET(_category,ForceCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Center);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _circumference = 2 * pi * ((_innerRadius + _outerRadius) / 2.5);

	_task = [_patrolGroup, _center, _innerRadius, _outerRadius, random 1 < 0.5, _circumference * 0.2, _circumference * 0.4, 0, 0, 0, 0] call SPM_fnc_patrolPerimeter;
	[_task, SPM_AirPatrol_TC_Patrol, _category] call SPM_TaskOnComplete;
};

SPM_AirPatrol_TC_Patrol =
{
	params ["_task", "_category"];

	private _group = [_task] call SPM_TaskGetObject;

	[_group, _category] call SPM_AirPatrol_Task_Patrol;
};

SPM_AirPatrol_CreateUnit =
{
	params ["_category", "_position", "_direction", "_type"];

	private _vehicleDescriptor = [OO_GET(_category,ForceCategory,CallupsEast), _type] call BIS_fnc_getFromPairs;

	private _unitVehicle = [_type, _position, _direction, "fly"] call SPM_fnc_spawnVehicle;
	[_unitVehicle] call (_vehicleDescriptor select 2);

	private _crew = [_unitVehicle] call SPM_fnc_groupFromVehicleCrew;
	private _crewSide = _crew select 0;
	private _crewDescriptor = _crew select 1;

	_crewDescriptor = [[_unitVehicle]] + _crewDescriptor;

	private _unitGroup = [_crewSide, _crewDescriptor, [_unitVehicle, 0.0] call SPM_PositionInFrontOfVehicle, 0, true] call SPM_fnc_spawnGroup;

	[_category, _unitGroup] call OO_GET(_category,Category,InitializeObject);
	[_category, _unitVehicle] call OO_GET(_category,Category,InitializeObject);

	if (_unitVehicle isKindOf "Plane") then
	{
		_unitVehicle addEventHandler ["GetOut",
			{
				params ["_vehicle", "_position", "_unit"];

				deleteVehicle vehicle _unit; // Ejection seat
				deleteVehicle _unit; // Crewman
			}];
	};

	[_unitGroup, _category] call SPM_AirPatrol_Task_Patrol;

	private _forceUnit = [_unitVehicle, units _unitGroup] call OO_CREATE(ForceUnit);

	OO_GET(_category,ForceCategory,ForceUnits) pushBack _forceUnit;
	private _force = [OO_GET(_forceUnit,ForceUnit,Units), OO_GET(_category,ForceCategory,RatingsEast)] call SPM_Force_GetForceRatings;

	private _reserves = OO_GET(_category,ForceCategory,Reserves) - OO_GET(_force select 0,ForceRating,Rating);
	OO_SET(_category,ForceCategory,Reserves,_reserves);

	_forceUnit
};

SPM_AirPatrol_CallUp =
{
	params ["_position", "_direction", "_category", "_type"];

	private _forceUnit = [_category, _position, _direction, _type] call SPM_AirPatrol_CreateUnit;

	sleep 5;

	if (not alive OO_GET(_forceUnit,ForceUnit,Vehicle) || { _position distance OO_GET(_forceUnit,ForceUnit,Vehicle) < 10 }) exitWith
	{
		[_category, _forceUnit] call SPM_Force_SalvageForceUnit;
	};
};

SPM_AirPatrol_Update =
{
	params ["_category"];

	private _updateTime = diag_tickTime + (120 + random 120);
	OO_SET(_category,Category,UpdateTime,_updateTime);

	[OO_GET(_category,ForceCategory,ForceUnits), { not alive OO_GET(_x,ForceUnit,Vehicle) }] call SPM_Force_DeleteForceUnits;

	private _westForce = [5000] call OO_METHOD(_category,ForceCategory,GetForceLevelsWest);
	private _eastForce = [-1] call OO_METHOD(_category,ForceCategory,GetForceLevelsEast);

	private _difficulty = [SPM_StrongpointDifficulty, "apatrol"] call BIS_fnc_getFromPairs;

	private _changes = [_westForce, _eastForce, OO_GET(_category,ForceCategory,CallupsEast), OO_GET(_category,ForceCategory,Reserves), _difficulty] call SPM_Force_Rebalance;

	private _units = OO_GET(_category,ForceCategory,ForceUnits);
	{
		[[_units, { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, _category] call SPM_AirPatrol_Retire;
	} forEach CHANGES(_changes,retire);
	{
		[[_units, { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, _category] call SPM_AirPatrol_Reinstate;
	} forEach CHANGES(_changes,reinstate);

	if (count CHANGES(_changes,callup) > 0) then
	{
		private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
		private _strongpointPosition = OO_GET(_strongpoint,Strongpoint,Position);
		private _strongpointRadius = OO_GET(_strongpoint,Strongpoint,Radius);
		private _spawnManager = OO_GET(_strongpoint,Strongpoint,SpawnManager);

		private _awayFromBase = (getMarkerPos "respawn_west") vectorFromTo _strongpointPosition;
		private _perpendicular = [_awayFromBase select 1, -(_awayFromBase select 0), 0];

		private _position = _strongpointPosition vectorAdd (_awayFromBase vectorMultiply (_strongpointRadius + CALLUP_DISTANCE));
		_position = _position vectorAdd (_perpendicular vectorMultiply (-500 + random 1000)) vectorAdd [0, 0, 100 + random 200];

		private _direction = _position getDir _strongpointPosition;

		{
			[_position, _direction, SPM_AirPatrol_CallUp, [_category, _x select 0]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);
		} forEach CHANGES(_changes,callup);
	};
};

SPM_AirPatrol_Create =
{
	params ["_category", "_area"];

	OO_SET(_category,ForceCategory,RatingsWest,SPM_AirPatrol_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_AirPatrol_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_AirPatrol_CallupsEast);
	OO_SET(_category,ForceCategory,Area,_area);
};

OO_BEGIN_SUBCLASS(AirPatrolCategory,ForceCategory);
	OO_OVERRIDE_METHOD(AirPatrolCategory,Root,Create,SPM_AirPatrol_Create);
	OO_OVERRIDE_METHOD(AirPatrolCategory,Category,Update,SPM_AirPatrol_Update);
OO_END_SUBCLASS(AirPatrolCategory);