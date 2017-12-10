/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveDestroyRadioTower_CreateRadioTower) =
{
	params ["_objective"];

	private _area = OO_GET(_objective,ObjectiveDestroyRadioTower,Area);
	private _center = OO_GET(_area,StrongpointArea,Center);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _positions = [];
	while { _innerRadius <= _outerRadius } do
	{
		_positions = [_center, _innerRadius, _innerRadius + 20, 4.0] call SPM_Util_SampleAreaGrid;
		[_positions, ["#GdtRoad", "#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 4.0, ["FENCE", "WALL", "BUILDING", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;

		if (count _positions > 0) exitWith {};

		diag_log format ["SPM_ObjectiveDestroyRadioTower_CreateTower: Unable to create communications tower %1, %2, %3", _center, _innerRadius, _innerRadius + 20];
		_innerRadius = _innerRadius + 20;
	};

	private _towerPosition = [_positions, _center] call SPM_Util_ClosestPosition;

	private _towerDirection = 0;
	private _building = nearestObject [_towerPosition, "Building"];
	if (not isNull _building) then
	{
		_towerDirection = getDir _building;
	};

	//TODO: Instead of a tower, could put a vehicle next to the building or at the tower position
	//TODO: Ifrit antenna at [0,-2.5,0.7]
	//TODO: Strider antenna at [0,-0.2,0.9]

	private _towerType = OO_GET(_objective,ObjectiveDestroyRadioTower,TowerType);
	private _radioTower = [_towerType, _towerPosition, _towerDirection, "can_collide"] call SPM_fnc_spawnVehicle;
	_radioTower setVectorUp [0,0,1];  // Will rotate around the origin of the object, which is usually in its middle

	OO_SET(_objective,MissionObjective,ObjectiveObject,_radioTower);
	OO_SET(_objective,ObjectiveDestroyObject,ObjectiveObjectDescription,"communications tower");

	[_radioTower, "ODRT", "TOWER"] call TRACE_SetObjectString;

	true
};

OO_TRACE_DECL(SPM_ObjectiveDestroyRadioTower_GetDescription) =
{
	params ["_objective"];

	"Destroy " + OO_GET(_objective,ObjectiveDestroyObject,ObjectiveObjectDescription);
};

OO_TRACE_DECL(SPM_ObjectiveDestroyRadioTower_Create) =
{
	params ["_objective", "_towerType", "_area"];

	OO_SET(_objective,ObjectiveDestroyRadioTower,TowerType,_towerType);
	OO_SET(_objective,ObjectiveDestroyRadioTower,Area,_area);

	private _vehicleDescription = getText (configFile >> "CfgVehicles" >> _towerType >> "displayName");
	OO_SET(_objective,ObjectiveDestroyObject,ObjectiveObjectDescription,_vehicleDescription);
};

OO_TRACE_DECL(SPM_ObjectiveDestroyRadioTower_Delete) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Root,Delete,ObjectiveDestroyObject);

	private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
	if (not isNull _object) then { deleteVehicle _object };
};

OO_BEGIN_SUBCLASS(ObjectiveDestroyRadioTower,ObjectiveDestroyObject);
	OO_OVERRIDE_METHOD(ObjectiveDestroyRadioTower,Root,Create,SPM_ObjectiveDestroyRadioTower_Create);
	OO_OVERRIDE_METHOD(ObjectiveDestroyRadioTower,Root,Delete,SPM_ObjectiveDestroyRadioTower_Delete);
	OO_OVERRIDE_METHOD(ObjectiveDestroyRadioTower,MissionObjective,GetDescription,SPM_ObjectiveDestroyRadioTower_GetDescription);
	OO_OVERRIDE_METHOD(ObjectiveDestroyRadioTower,ObjectiveDestroyObject,CreateObjectiveObject,SPM_ObjectiveDestroyRadioTower_CreateRadioTower);
	OO_DEFINE_PROPERTY(ObjectiveDestroyRadioTower,TowerType,"STRING","");
	OO_DEFINE_PROPERTY(ObjectiveDestroyRadioTower,Area,"ARRAY",OO_NULL);
OO_END_SUBCLASS(ObjectiveDestroyRadioTower);
