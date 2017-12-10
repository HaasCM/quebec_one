/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveDestroyVehicle_CreateVehicle) =
{
	params ["_objective"];

	private _vehicleDescriptor = OO_GET(_objective,ObjectiveDestroyVehicle,VehicleDescriptor);
	private _vehicleType = _vehicleDescriptor select 0;
	private _vehicleInitializer = _vehicleDescriptor select 1;

	private _parkingPosition = [];
	if (_vehicleType isKindOf "LandVehicle") then
	{
		private _garrison = OO_NULL;
		{
			if (OO_GET(_x,Root,Class) == OO_InfantryGarrisonCategory) exitWith { _garrison = _x };
		} forEach OO_GET(_mission,Strongpoint,Categories);

		private _housedUnits = OO_GET(_garrison,InfantryGarrisonCategory,HousedUnits);

		_housedUnits = +_housedUnits;

		while { count _parkingPosition == 0 && count _housedUnits > 0 } do
		{
			private _unit = _housedUnits deleteAt (floor random count _housedUnits);
			_parkingPosition = [getPos _unit, "closest"] call SPM_CivilianVehiclesCategory_ParkingPosition;
		};
	};

	if (count _parkingPosition == 0) then
	{
		private _area = OO_GET(_objective,ObjectiveDestroyVehicle,Area);
		private _center = OO_GET(_area,StrongpointArea,Center);
		private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
		private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

		private _exclusions = ["WALL", "BUILDING", "ROCK", "ROAD"];
		if (_vehicleType isKindOf "Air") then { _exclusions append ["TREE", "SMALL TREE", "HIDE" ] };

		private _positions = [];
		while { _innerRadius < _outerRadius } do
		{
			_positions = [_center, _innerRadius, _innerRadius + 20, 4.0] call SPM_Util_SampleAreaGrid;
			[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
			[_positions, 6.0, _exclusions] call SPM_Util_ExcludeSamplesByProximity;

			if (count _positions > 0) exitWith {};

			diag_log format ["SPM_ObjectiveDestroyVehicle_CreateVehicle: Unable to create vehicle %1, %2, %3", _center, _innerRadius, _innerRadius + 20];
			_innerRadius = _innerRadius + 20;
		};

		_parkingPosition = [[_positions, _center] call SPM_Util_ClosestPosition, random 360];
	};

	private _vehicle = [_vehicleType, _parkingPosition select 0, _parkingPosition select 1, "can_collide"] call SPM_fnc_spawnVehicle;

	([_vehicle] + (_vehicleInitializer select 1)) call (_vehicleInitializer select 0);
	[_objective, _vehicle] call OO_GET(_category,Category,InitializeObject);

	_vehicle setVehicleLock "unlocked";

	OO_SET(_objective,MissionObjective,ObjectiveObject,_vehicle);

	[_vehicle, "ODV", "VEHICLE"] call TRACE_SetObjectString;

	true
};

OO_TRACE_DECL(SPM_ObjectiveDestroyVehicle_GetDescription) =
{
	params ["_objective"];

	"Destroy or capture " + OO_GET(_objective,ObjectiveDestroyObject,ObjectiveObjectDescription);
};

OO_TRACE_DECL(SPM_ObjectiveDestroyVehicle_Create) =
{
	params ["_objective", "_vehicleDescriptor", "_area"];

	OO_SET(_objective,ObjectiveDestroyVehicle,VehicleDescriptor,_vehicleDescriptor);
	OO_SET(_objective,ObjectiveDestroyVehicle,Area,_area);

	private _vehicleDescription = getText (configFile >> "CfgVehicles" >> (_vehicleDescriptor select 0) >> "displayName");
	OO_SET(_objective,ObjectiveDestroyObject,ObjectiveObjectDescription,_vehicleDescription);
};

OO_TRACE_DECL(SPM_ObjectiveDestroyVehicle_Delete) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Root,Delete,ObjectiveDestroyObject);

	private _state = OO_GET(_objective,MissionObjective,State);
	if (_state != "completed") then
	{
		private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
		if (not isNull _object) then { deleteVehicle _object };
	};
};

OO_BEGIN_SUBCLASS(ObjectiveDestroyVehicle,ObjectiveDestroyObject);
	OO_OVERRIDE_METHOD(ObjectiveDestroyVehicle,Root,Create,SPM_ObjectiveDestroyVehicle_Create);
	OO_OVERRIDE_METHOD(ObjectiveDestroyVehicle,Root,Delete,SPM_ObjectiveDestroyVehicle_Delete);
	OO_OVERRIDE_METHOD(ObjectiveDestroyVehicle,MissionObjective,GetDescription,SPM_ObjectiveDestroyVehicle_GetDescription);
	OO_OVERRIDE_METHOD(ObjectiveDestroyVehicle,ObjectiveDestroyObject,CreateObjectiveObject,SPM_ObjectiveDestroyVehicle_CreateVehicle);
	OO_DEFINE_PROPERTY(ObjectiveDestroyVehicle,VehicleDescriptor,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveDestroyVehicle,Area,"ARRAY",OO_NULL);
OO_END_SUBCLASS(ObjectiveDestroyVehicle);
