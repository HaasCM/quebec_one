/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

// Buildings occupy data: [[group-east,group-west,group-independent,group-civilian], [[soldier, position], [soldier, position], ...]]
// Group occupy data: [building-occupying] 

#define UNCHAIN_ON_HEAR_WEAPON_PROBABILITY 0.5
#define HEAR_WEAPON_RANGE 15
#define HEAR_WEAPON_RANGE_SUPPRESSED 4

OO_TRACE_DECL(SPM_Occupy_SideToNumber) =
{
	params ["_side"];

	switch (_side) do
	{
		case east: { 0 };
		case west: { 1 };
		case independent: { 2 };
		case civilian: { 3 };
		default { diag_log format ["SPM_Occupy_SideToNumber: unexpected side: %1", _side]; -1 };
	};
};

OO_TRACE_DECL(SPM_NumberOccupiedPositions) =
{
	params ["_building", "_side"];

	private _occupyData = _building getVariable "SPM_OccupyData";

	if (isNil "_occupyData") exitWith { 0 };

	private _occupiers = (_occupyData select 1) select { alive (_x select 0) };

	if (not isNil "_side") exitWith { { side (_x select 0) == _side } count _occupiers };

	count _occupiers
};

OO_TRACE_DECL(SPM_BuildingIsOccupied) =
{
	params ["_building", "_side"];

	([_building, _side] call SPM_NumberOccupiedPositions) > 0
};

OO_TRACE_DECL(SPM_GetBuildingOccupyData) =
{
	params ["_building", "_side"];

	private _occupyData = _building getVariable "SPM_OccupyData";

	if (isNil "_occupyData") then
	{
		_occupyData = [[grpNull, grpNull, grpNull, grpNull], (_building buildingPos -1) apply { [objNull, _x] }];
		_building setVariable ["SPM_OccupyData", _occupyData];
	};

	private _groups = _occupyData select 0;
	private _sideIndex = [_side] call SPM_Occupy_SideToNumber;

	if (isNull (_groups select _sideIndex)) then
	{
		private _group = createGroup _side;
		_group setBehaviour "safe";
		_group setCombatMode "white";
		_group setSpeedMode "limited";

		_groups set [_sideIndex, _group];
	};

	_occupyData
};

OO_TRACE_DECL(SPM_AllocateBuildingPosition) =
{
	params ["_building", "_soldier"];

	private _occupyData = [_building, side _soldier] call SPM_GetBuildingOccupyData;
	private _emptyPositions = (_occupyData select 1) select { not alive (_x select 0) };

	if (count _emptyPositions == 0) exitWith { [] };

	private _emptyPosition = selectRandom _emptyPositions;

	_emptyPosition set [0, _soldier];

	_emptyPosition select 1
};

OO_TRACE_DECL(SPM_FreeBuildingPosition) =
{
	params ["_soldier"];

	private _soldierOccupyData = _soldier getVariable "SPM_OccupyData";

	if (isNil "_soldierOccupyData") exitWith {};

	private _building = _soldierOccupyData select 0;

	private _occupyData = [_building, side _soldier] call SPM_GetBuildingOccupyData;

	{
		if (_x select 0 == _soldier) exitWith
		{
			_x set [0, objNull];
			[_soldier] join grpNull;
		};
	} forEach (_occupyData select 1);

	{
		if (not isNull _x && { count units _x == 0}) then { deleteGroup _x };
	} forEach (_occupyData select 0);

	private _occupiedPositionsCount = { alive (_x select 0) } count (_occupyData select 1);
	if (_occupiedPositionsCount == 0) then
	{
		_building setVariable ["SPM_OccupyData", nil];
	};

	_soldier setVariable ["SPM_OccupyData", nil];
};

OO_TRACE_DECL(SPM_JoinOccupationGroup) =
{
	params ["_soldier"];

	private _occupyData = _soldier getVariable "SPM_OccupyData";

	if (isNil "_occupyData") exitWith
	{
		diag_log "SPM_JoinOccupationGroup: attempt to occupy with malformed soldier data";
	};

	private _building = _occupyData select 0;
	private _buildingData = [_building, side _soldier] call SPM_GetBuildingOccupyData;

	private _sideIndex = [side _soldier] call SPM_Occupy_SideToNumber;
	private _group = _buildingData select 0 select _sideIndex;
	[_soldier] join _group;
};

OO_TRACE_DECL(SPM_UnchainSoldier) =
{
	params ["_soldier"];

	_soldier enableAI "path";

	_soldier removeEventHandler ["Hit", _soldier getVariable ["SPM_OccupyHitHandler", -1]];
	_soldier setVariable ["SPM_OccupyHitHandler", nil];
	_soldier removeEventHandler ["FiredNear", _soldier getVariable ["SPM_OccupyFiredNearHandler", -1]];
	_soldier setVariable ["SPM_OccupyFiredNearHandler", nil];
};

OO_TRACE_DECL(SPM_Suppressors) = [];

OO_TRACE_DECL(SPM_ChainSoldier) =
{
	params ["_soldier"];

	_soldier disableAI "path";

	private _hitHandler = _soldier addEventHandler ["Hit",
		{
			[_this select 0] call SPM_UnchainSoldier;
			[_this select 0] call SPM_FreeBuildingPosition;
		}];

	_soldier setVariable ["SPM_OccupyHitHandler", _hitHandler];

	if (random 1 < UNCHAIN_ON_HEAR_WEAPON_PROBABILITY) then
	{
		private _firedNearHandler = _soldier addEventHandler ["FiredNear",
			{
				params ["_soldier", "_vehicle", "_distance", "_muzzle", "_weapon", "_mode", "_ammo", "_gunner"];

				if (side _gunner == side _soldier) exitWith {};

				private _detectDistance = HEAR_WEAPON_RANGE;
				if (currentWeapon _gunner == _weapon) then
				{
					private _suppressed = _gunner weaponAccessories currentweapon _gunner select 0 != "";
					if (_suppressed) then { _detectDistance = HEAR_WEAPON_RANGE_SUPPRESSED };
				};

				if (_distance < _detectDistance) then
				{
					[_soldier] call SPM_UnchainSoldier;
					[_soldier] call SPM_FreeBuildingPosition;
				};
			}];
		_soldier setVariable ["SPM_OccupyFiredNearHandler", _firedNearHandler];
	};
};

OO_TRACE_DECL(SPM_CompleteOccupation) =
{
	params ["_soldier"];

	if (not alive _soldier) exitWith
	{
		[_soldier] call SPM_FreeBuildingPosition;
	};

	[group _soldier] call SPM_StopWaypointMonitor;

	_soldier setUnitPos "auto";

	[_soldier] call SPM_ChainSoldier;

	[_soldier] call SPM_JoinOccupationGroup;
};

OO_TRACE_DECL(SPM_OccupyBuilding) =
{
	params ["_soldier", "_building", ["_onArrival", {}, [{}]]];

	private _buildingPosition = [_building, _soldier] call SPM_AllocateBuildingPosition;
	if (count _buildingPosition == 0) exitWith { false };

	_soldier setVariable ["SPM_OccupyData", [_building]];

	private _soloGroup = createGroup side _group;
	_soloGroup setBehaviour (behaviour _soldier);
	_soloGroup setCombatMode (combatMode _soldier);
	_soloGroup setSpeedMode (speedMode _soldier);

	[_soldier] join _soloGroup;

	private _waypoint = [_soloGroup, _buildingPosition] call SPM_AddPatrolWaypoint;
	_waypoint setWaypointType "move";
	[_waypoint, { [_this select 0] call SPM_CompleteOccupation; }] call SPM_AddPatrolWaypointStatements;
	[_waypoint, _onArrival] call SPM_AddPatrolWaypointStatements;

	[_soloGroup] call SPM_StartWaypointMonitor;

	true;
};

OO_TRACE_DECL(SPM_OccupyNextSoldier) =
{
	params ["_group", "_building"];

	private _units = units _group;

	if (count _units == 0) exitWith
	{
		deleteGroup _group;
	};

	private _soldierIndex = count _units - 1;

	private _soldier = _units select _soldierIndex;
	_soldier setVariable ["SPM_OriginalGroup", _group];

	private _onArrival =
	{
		params ["_soldier"];

		private _originalGroup = _soldier getVariable "SPM_OriginalGroup";
		private _occupyData = _soldier getVariable "SPM_OccupyData";

		[_originalGroup, _occupyData select 0] call SPM_OccupyNextSoldier;

		_soldier setVariable ["SPM_OriginalGroup", nil];
	};
	[_soldier, _building, _onArrival] call SPM_OccupyBuilding;
};

OO_TRACE_DECL(SPM_OccupyGetBuildings) =
{
	params ["_buildings", "_side"];

	private _data = [];

	{
		if (not ((_x buildingExit 0) isEqualTo [0,0,0])) then
		{
			private _numberPositions = count (_x buildingPos -1);

			if (_numberPositions > 0) then
			{
				_data pushBack [_x, _numberPositions, [_x] call SPM_NumberOccupiedPositions];
			};
		};
	} forEach _buildings;

	_data
};

OO_TRACE_DECL(SPM_OccupyEnter) =
{
	params ["_group", "_building", "_method"];

	switch (_method) do
	{
		case "simultaneous":
		{
			private _waypoint = _group addWaypoint [getPos _building, 0];
			_waypoint setWaypointFormation "diamond";

			[_group, _building] spawn
			{
				params ["_group", "_building"];

				{
					[_x, _building] call SPM_OccupyBuilding;
					sleep 0.1;
				} forEach +(units _group);

				if (count units _group == 0) then//TODO: This should be left to the caller
				{
					deleteGroup _group;
				};
			};
		};

		case "series":
		{
			private _waypoint = _group addWaypoint [getPos _building, 0];
			_waypoint setWaypointFormation "diamond";

			[_group, _building] call SPM_OccupyNextSoldier;
		};

		case "instant":
		{
			{
				private _soldier = _x;

				private _buildingPosition = [_building, _soldier] call SPM_AllocateBuildingPosition;
				if (count _buildingPosition == 0) exitWith { };

				_soldier setVariable ["SPM_OccupyData", [_building]];

				_soldier setPos _buildingPosition;
				_soldier setVectorDir (getPos _building vectorFromTo getPos _soldier);

				[_soldier] call SPM_CompleteOccupation;
			} forEach +(units _group);
		};
	};
};