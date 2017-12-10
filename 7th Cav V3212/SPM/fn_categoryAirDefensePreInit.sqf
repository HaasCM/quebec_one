/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

if (isNil "SPM_StrongpointDifficulty") then { SPM_StrongpointDifficulty = [] };
SPM_StrongpointDifficulty pushBack ["adefense", 5];

SPM_AirDefense_RatingsWest =
[
	["B_Heli_Attack_01_F", [50, 2]],
	["B_Heli_Attack_01_dynamicLoadout_F", [50, 2]],
	["B_Heli_Light_01_armed_F", [20, 2]],
	["B_Heli_Light_01_dynamicLoadout_F", [20, 2]],
	["B_Plane_CAS_01_F", [120, 1]],
	["B_Plane_CAS_01_dynamicLoadout_F", [120, 1]],
	["B_Plane_Fighter_01_F", [75, 1]],
	["B_Plane_Fighter_01_Stealth_F", [75, 1]],

	["O_Heli_Attack_02_F", [50, 2]],
	["O_Heli_Attack_02_dynamicLoadout_F", [50, 2]],
	["O_Heli_Light_02_F", [20, 2]],
	["O_Heli_Light_02_dynamicLoadout_F", [20, 2]],
	["O_Plane_CAS_02_F", [120, 1]],
	["O_Plane_CAS_02_dynamicLoadout_F", [120, 1]],
	["O_Plane_Fighter_02_F", [75, 1]],
	["O_Plane_Fighter_02_Stealth_F", [75, 1]],

	["I_Heli_light_03_F", [20, 2]],
	["I_Heli_light_03_dynamicLoadout_F", [20, 2]],
	["I_Plane_Fighter_03_CAS_F", [75, 1]],
	["I_Plane_Fighter_03_AA_F", [75, 1]],
	["I_Plane_Fighter_03_dynamicLoadout_F", [75, 1]],
	["I_Plane_Fighter_04_F", [75, 1]]
];

SPM_AirDefense_CallupsEast =
[
	["O_APC_Tracked_02_AA_F", [40, 3,
		{
			(_this select 0) setFuel 0;
			(_this select 0) removeMagazineTurret ["4Rnd_Titan_long_missiles", [0]];
			(_this select 0) addMagazineTurret ["4Rnd_Titan_long_missiles", [0], 1];
			(_this select 0) addEventHandler ["Fired", { [_this select 0, _this select 1, _this select 5, 10 + random 10] call SPM_AirDefense_Reload }];
		}]],

	["O_MRAP_02_hmg_F", [15, 3,
		{
			(_this select 0) setFuel 0;
			(_this select 0) addEventHandler ["Fired", { [_this select 0, _this select 1, _this select 5, 10 + random 10] call SPM_AirDefense_Reload }];
		}]],

	["O_HMG_01_high_F", [20, 1,
		{
			(_this select 0) addEventHandler ["Fired", { [_this select 0, _this select 1, _this select 5, 10 + random 10] call SPM_AirDefense_Reload }];
		}]]
];

SPM_AirDefense_RatingsEast = SPM_AirDefense_CallupsEast apply { [_x select 0, (_x select 1) select [0, 2]] };

OO_TRACE_DECL(SPM_AirDefense_Reload) =
{
	private _vehicle = _this select 0;
	private _weapon = _this select 1;
	private _magazineType = _this select 2;
	private _reloadDelay = _this select 3;

	if (([magazinesAmmo _vehicle, _magazineType] call BIS_fnc_findInPairs) == -1) then
	{
		if (_weapon in (_vehicle weaponsTurret [0])) then
		{
			[_vehicle, _magazineType, _reloadDelay] spawn
			{
				private _vehicle = _this select 0;
				private _magazineType = _this select 1;
				private _reloadDelay = _this select 2;

				sleep _reloadDelay;

				if (alive _vehicle) then
				{
					if (_magazineType == "4Rnd_Titan_long_missiles") then
					{
						_vehicle removeMagazineTurret [_magazineType, [0]];
						_vehicle addMagazineTurret [_magazineType, [0], 1];
					}
					else
					{
						_vehicle removeMagazineTurret [_magazineType, [0]];
						_vehicle addMagazineTurret [_magazineType, [0]];
					};
				};
			};
		};
	};
};

OO_TRACE_DECL(SPM_AirDefense_RequestSupport) =
{
	params ["_category", "_position"];

	private _supportPositions = OO_GET(_category,AirDefenseCategory,SupportPositions);

	private _matched = false;
	{
		if (_x distanceSqr _position < 300^2) exitWith { _matched = true };
	} forEach _supportPositions;

	if (not _matched) then { _supportPositions pushBack _position };
};

OO_TRACE_DECL(SPM_AirDefense_CreateUnit) =
{
	params ["_category", "_position", "_direction", "_type"];

	private _vehicleDescriptor = [OO_GET(_category,ForceCategory,CallupsEast), _type] call BIS_fnc_getFromPairs;

	private _unitVehicle = [_type, _position, _direction] call SPM_fnc_spawnVehicle;
	[_unitVehicle] call (_vehicleDescriptor select 2);

	private _crew = [_unitVehicle] call SPM_fnc_groupFromVehicleCrew;
	private _crewSide = _crew select 0;
	private _crewDescriptor = _crew select 1;

	[_crewDescriptor select 0] call SPM_Util_SubstituteRepairCrewman;
	
	_crewDescriptor = [[_unitVehicle]] + _crewDescriptor;

	private _unitGroup = [_crewSide, _crewDescriptor, [_unitVehicle, 0.0] call SPM_PositionInFrontOfVehicle, 0, true] call SPM_fnc_spawnGroup;

	[_category, _unitGroup] call OO_GET(_category,Category,InitializeObject);
	[_category, _unitVehicle] call OO_GET(_category,Category,InitializeObject);

	private _forceUnit = [_unitVehicle, units _unitGroup] call OO_CREATE(ForceUnit);

	OO_GET(_category,ForceCategory,ForceUnits) pushBack _forceUnit;
	private _force = [OO_GET(_forceUnit,ForceUnit,Units), OO_GET(_category,ForceCategory,CallupsEast)] call SPM_Force_GetForceRatings;

	private _reserves = OO_GET(_category,ForceCategory,Reserves) - OO_GET(_force select 0,ForceRating,Rating);
	OO_SET(_category,ForceCategory,Reserves,_reserves);

	_forceUnit
};

OO_TRACE_DECL(SPM_AirDefense_Retire) =
{
	params ["_forceUnitIndex", "_category"];

	[_category, _forceUnitIndex] call SPM_Force_SalvageForceUnit;
};

OO_TRACE_DECL(SPM_AirDefense_Reinstate) =
{
	params ["_forceUnitIndex", "_category"];
};

OO_TRACE_DECL(SPM_AirDefense_CallUp) =
{
	params ["_position", "_direction", "_category", "_type"];

	private _forceUnit = [_category, _position, _direction, _type] call SPM_AirDefense_CreateUnit;

	sleep 5;

	if (not alive OO_GET(_forceUnit,ForceUnit,Vehicle)) exitWith
	{
		[_category, _forceUnit] call SPM_Force_SalvageForceUnit;
	};
};

OO_TRACE_DECL(SPM_AirDefense_Create) =
{
	params ["_category", "_area"];

	OO_SET(_category,ForceCategory,RatingsWest,SPM_AirDefense_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_AirDefense_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_AirDefense_CallupsEast);
	OO_SET(_category,ForceCategory,Area,_area);
};

OO_TRACE_DECL(SPM_AirDefense_Update) =
{
	params ["_category"];

	private _updateTime = diag_tickTime + 10; // A relatively quick update time so that it reacts to support requests.  But will only spawn when requests come in.
	OO_SET(_category,Category,UpdateTime,_updateTime);

	[OO_GET(_category,ForceCategory,ForceUnits), { not alive OO_GET(_x,ForceUnit,Vehicle) }] call SPM_Force_DeleteForceUnits;

	// If no possibility of callups or retirements, we're done
	private _supportPositions = OO_GET(_category,AirDefenseCategory,SupportPositions);
	if (count _supportPositions == 0 && count OO_GET(_category,ForceCategory,ForceUnits) == 0) exitWith {};

	private _westForce = [10000] call OO_METHOD(_category,ForceCategory,GetForceLevelsWest);
	private _eastForce = [2000] call OO_METHOD(_category,ForceCategory,GetForceLevelsEast);

	private _difficulty = [SPM_StrongpointDifficulty, "adefense"] call BIS_fnc_getFromPairs;

	private _changes = [_westForce, _eastForce, OO_GET(_category,ForceCategory,CallupsEast), OO_GET(_category,ForceCategory,Reserves), _difficulty] call SPM_Force_Rebalance;
	{
		[[OO_GET(_category,ForceCategory,ForceUnits), { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, _category] call SPM_AirDefense_Retire;
	} forEach CHANGES(_changes,retire);
	{
		[[OO_GET(_category,ForceCategory,ForceUnits), { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, _category] call SPM_AirDefense_Reinstate;
	} forEach CHANGES(_changes,reinstate);

	private _callups = CHANGES(_changes,callup);
	if (count _callups > 0 && count _supportPositions > 0) then
	{
		private _supportIndex = 0;
		private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
		private _spawnManager = OO_GET(_strongpoint,Strongpoint,SpawnManager);

		{
			private _supportPosition = _supportPositions select _supportIndex;
			_supportIndex = (_supportIndex + 1) mod (count _supportPositions);

			private _toSupportPosition = (OO_GET(_strongpoint,Strongpoint,Position)) vectorFromTo _supportPosition;
			private _supportCenter = _supportPosition vectorAdd (_toSupportPosition vectorMultiply 150);

			private _positions = [_supportCenter, 0, 100, 20] call SPM_Util_SampleAreaGrid;
			[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
			[_positions, 5.0, ["WALL", "BUILDING", "ROCK", "TREE"]] call SPM_Util_ExcludeSamplesByProximity;

			if (count _positions > 0) then
			{
				[selectRandom _positions, random 360, SPM_AirDefense_CallUp, [_category, _x select 0]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);
			};
		} forEach CHANGES(_changes,callup);
	};

	while { count _supportPositions > 0 } do
	{
		_supportPositions deleteAt 0;
	};
};

OO_BEGIN_SUBCLASS(AirDefenseCategory,ForceCategory);
	OO_OVERRIDE_METHOD(AirDefenseCategory,Root,Create,SPM_AirDefense_Create);
	OO_OVERRIDE_METHOD(AirDefenseCategory,Category,Update,SPM_AirDefense_Update);
	OO_DEFINE_METHOD(AirDefenseCategory,RequestSupport,SPM_AirDefense_RequestSupport);
	OO_DEFINE_PROPERTY(AirDefenseCategory,SupportPositions,"ARRAY",[]);
OO_END_SUBCLASS(AirDefenseCategory);