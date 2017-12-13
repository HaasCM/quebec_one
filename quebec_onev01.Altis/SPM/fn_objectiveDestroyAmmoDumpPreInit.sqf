/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_DetonateAmmoDump) =
{
	params ["_objective"];

	private _barrel = OO_GET(_objective,MissionObjective,ObjectiveObject);
	deleteVehicle _barrel;

	private _explosivesObjects = OO_GET(_objective,ObjectiveDestroyAmmoDump,_ExplosivesObjects);

	[_explosivesObjects] spawn
	{
		params ["_explosivesObjects"];

		private _explosionProxies = ["HelicopterExploBig", "Bo_GBU12_LGB"];

		private _primaries = count _explosivesObjects;

		private _averagePosition = [0,0,0];
		while { count _explosivesObjects > 0 } do
		{
			private _explosivesObject = _explosivesObjects deleteAt 0;
			_averagePosition = _averagePosition vectorAdd getPos _explosivesObject;

			(selectRandom _explosionProxies) createVehicle (getPos _explosivesObject);
			deleteVehicle _explosivesObject;
			sleep random 1;
		};
		_averagePosition = _averagePosition vectorMultiply (1 / _primaries);

		private _remains = createVehicle ["Land_GarbagePallet_F", _averagePosition, [], 0, "can_collide"];
		[_remains, [0,0,0], 120, { deleteVehicle (_this select 0) }, _remains] call SPM_Util_Fire;

		private _explosives = ("getNumber (_x >> 'explosive') == 1 && getText (_x >> 'explosionEffects') != 'ExplosionEffects'" configClasses (configFile >> "CfgAmmo")) apply { configName _x };

		_averagePosition set [2, 2];

		private _delay = 2^-4;
		while { alive _remains } do
		{
			private _explosive = (selectRandom _explosives) createVehicle _averagePosition;
			[_explosive, -90 + random 180, -90 + random 180] call BIS_fnc_setPitchBank;
			
			_delay = _delay * 2;
			sleep random (_delay max 0.5);
		};
	};
};

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_BarrelHit) =
{
	params ["_barrel", "_causedBy", "_damage", "_instigator"];

	if (_damage > 10) then
	{
		[_barrel, _causedBy, _instigator] call SPM_ObjectiveDestroyAmmoDump_BarrelKilled;
	};
};

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_BarrelKilled) =
{
	params ["_barrel"];

	private _objective = _barrel getVariable "SPM_ObjectiveDestroyAmmoDump_Objective";
	[] call OO_METHOD(_objective,ObjectiveDestroyAmmoDump,DetonateAmmoDump);
};

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_CreateAmmoDumpObjects) =
{
	params ["_position", "_direction", "_enclosureObjects", "_explosivesObjects", "_triggerObjects"];

	private _objectPosition = [];

	_objectPosition = _position vectorAdd ([[0,3.7,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_5_F", _objectPosition, _direction, "can_collide"] call SPM_fnc_spawnVehicle);

	_objectPosition = _position vectorAdd ([[0,-3.7,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_5_F", _objectPosition, _direction, "can_collide"] call SPM_fnc_spawnVehicle);

	_objectPosition = _position vectorAdd ([[4.19,2.25,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_5_F", _objectPosition, _direction + 90, "can_collide"] call SPM_fnc_spawnVehicle);

	_objectPosition = _position vectorAdd ([[-5.16,2.22,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_5_F", _objectPosition, _direction + 90, "can_collide"] call SPM_fnc_spawnVehicle);

	_objectPosition = _position vectorAdd ([[-1.46,3.95,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_3_F", _objectPosition, _direction + 90, "can_collide"] call SPM_fnc_spawnVehicle);

	_objectPosition = _position vectorAdd ([[-1.46,-1.76,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_3_F", _objectPosition, _direction + 90, "can_collide"] call SPM_fnc_spawnVehicle);

	_objectPosition = _position vectorAdd ([[0.0,0.0,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["CamoNet_INDP_big_F", _objectPosition, _direction, "can_collide"] call SPM_fnc_spawnVehicle);

	private _boxType = "";
	private _boxTypes = ["Land_PaperBox_closed_F", "Land_PaperBox_open_full_F", "Land_PaperBox_open_empty_F", "Land_Pallet_MilBoxes_F"];

	_objectPosition = _position vectorAdd ([[2.56,2.1,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack (["Land_PaperBox_closed_F", _objectPosition, _direction, "can_collide"] call SPM_fnc_spawnVehicle);

	_boxType = "CargoNet_01_box_F";
	_objectPosition = _position vectorAdd ([[2.56,0.6,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack ([_boxType, _objectPosition, _direction, "can_collide"] call SPM_fnc_spawnVehicle);

	private _container = _explosivesObjects select (count _explosivesObjects - 1);
	private _capacity = getNumber (configFile >> "CfgVehicles" >> typeOf _container >> "maximumLoad");
	[_container, _capacity, true] call SERVER_Supply_StockAmmunitionContainer;

	_boxType = "CargoNet_01_box_F";
	_objectPosition = _position vectorAdd ([[2.56,-2.1,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack ([_boxType, _objectPosition, _direction, "can_collide"] call SPM_fnc_spawnVehicle);

	private _container = _explosivesObjects select (count _explosivesObjects - 1);
	private _capacity = getNumber (configFile >> "CfgVehicles" >> typeOf _container >> "maximumLoad");
	[_container, _capacity, true] call SERVER_Supply_StockExplosivesContainer;

	_boxType = selectRandom _boxTypes;
	_objectPosition = _position vectorAdd ([[1.06,2.1,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack ([_boxType, _objectPosition, _direction, "can_collide"] call SPM_fnc_spawnVehicle);

	_boxType = selectRandom _boxTypes;
	_objectPosition = _position vectorAdd ([[1.06,0.6,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack ([_boxType, _objectPosition, _direction, "can_collide"] call SPM_fnc_spawnVehicle);

	_boxType = selectRandom _boxTypes;
	_objectPosition = _position vectorAdd ([[1.06,-2.1,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack ([_boxType, _objectPosition, _direction, "can_collide"] call SPM_fnc_spawnVehicle);

	_objectPosition = _position vectorAdd ([[2.56,-0.8,0], _direction] call SPM_Util_RotatePosition2D);
	_triggerObjects pushBack (["Land_MetalBarrel_F", _objectPosition, _direction, "can_collide"] call SPM_fnc_spawnVehicle);

	[_triggerObjects select (count _triggerObjects - 1), "ODAD", "AMMO DUMP"] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_CreateAmmoDump) =
{
	params ["_objective"];

	private _area = OO_GET(_objective,ObjectiveDestroyAmmoDump,Area);
	private _center = OO_GET(_area,StrongpointArea,Center);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _positions = [];
	while { true } do
	{
		// Find a spot clear of this stuff
		_positions = [_center, _innerRadius, _outerRadius, 10] call SPM_Util_SampleAreaGrid;
		[_positions, ["#GdtRoad", "#GdtWater", "#GdtConcrete"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 6.0, ["FENCE", "WALL", "BUILDING", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;

		if (count _positions > 0) exitWith {};

		diag_log format ["SPM_ObjectiveDestroyAmmoDump_CreateAmmoDump: Unable to create ammo dump %1, %2, %3", _center, _innerRadius, _outerRadius];
		_innerRadius = _outerRadius;
		_outerRadius = _outerRadius + 50;
	};

	private _position = [_positions, _center] call SPM_Util_ClosestPosition;

	// Remove miscellaneous items
	private _blockingObjects = nearestTerrainObjects [_position, ["TREE", "SMALL TREE", "BUSH", "HIDE"], 10, false, true];
	{
		_x hideObjectGlobal true;
	} forEach _blockingObjects;
	OO_SET(_objective,ObjectiveDestroyAmmoDump,_BlockingObjects,_blockingObjects);

	private _direction = 0;
	private _building = nearestObject [_position, "Building"];
	if (not isNull _building) then
	{
		_direction = getDir _building;
	};

	private _explosivesObjects = OO_GET(_objective,ObjectiveDestroyAmmoDump,_ExplosivesObjects);
	private _enclosureObjects = OO_GET(_objective,ObjectiveDestroyAmmoDump,_EnclosureObjects);
	private _triggerObjects = [];

	private _dumpObjects = [_position, _direction, _enclosureObjects, _explosivesObjects, _triggerObjects] call SPM_ObjectiveDestroyAmmoDump_CreateAmmoDumpObjects;

	private _triggerObject = _triggerObjects select 0;
	_triggerObject setVariable ["SPM_ObjectiveDestroyAmmoDump_Objective", _objective];
	_triggerObject addEventHandler ["HandleDamage", { false }];
	_triggerObject addEventHandler ["Hit", SPM_ObjectiveDestroyAmmoDump_BarrelHit];
	_triggerObject addEventHandler ["Killed", SPM_ObjectiveDestroyAmmoDump_BarrelKilled];

	OO_SET(_objective,MissionObjective,ObjectiveObject,_triggerObject);
	OO_SET(_objective,ObjectiveDestroyObject,ObjectiveObjectDescription,"ammunition dump");
};

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_GetDescription) =
{
	params ["_objective"];

	"Destroy ammunition dump"
};

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_Delete) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Root,Delete,ObjectiveDestroyObject);

	private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
	if (not isNull _object) then { deleteVehicle _object };

	{
		if (not isNull _x) then { deleteVehicle _x; };
	} forEach OO_GET(_objective,ObjectiveDestroyAmmoDump,_EnclosureObjects);

	{
		if (not isNull _x) then { deleteVehicle _x; };
	} forEach OO_GET(_objective,ObjectiveDestroyAmmoDump,_ExplosivesObjects);

	private _blockingObjects = OO_GET(_objective,ObjectiveDestroyAmmoDump,_BlockingObjects);
	{
		_x hideObjectGlobal false;
	} forEach _blockingObjects;
};

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_Create) =
{
	params ["_objective", "_area"];

	OO_SET(_objective,ObjectiveDestroyAmmoDump,Area,_area);
};

OO_BEGIN_SUBCLASS(ObjectiveDestroyAmmoDump,ObjectiveDestroyObject);
	OO_OVERRIDE_METHOD(ObjectiveDestroyAmmoDump,Root,Create,SPM_ObjectiveDestroyAmmoDump_Create);
	OO_OVERRIDE_METHOD(ObjectiveDestroyAmmoDump,Root,Delete,SPM_ObjectiveDestroyAmmoDump_Delete);
	OO_OVERRIDE_METHOD(ObjectiveDestroyAmmoDump,MissionObjective,GetDescription,SPM_ObjectiveDestroyAmmoDump_GetDescription);
	OO_OVERRIDE_METHOD(ObjectiveDestroyAmmoDump,ObjectiveDestroyObject,CreateObjectiveObject,SPM_ObjectiveDestroyAmmoDump_CreateAmmoDump);
	OO_DEFINE_METHOD(ObjectiveDestroyAmmoDump,DetonateAmmoDump,SPM_ObjectiveDestroyAmmoDump_DetonateAmmoDump);
	OO_DEFINE_PROPERTY(ObjectiveDestroyAmmoDump,Area,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveDestroyAmmoDump,_EnclosureObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveDestroyAmmoDump,_ExplosivesObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveDestroyAmmoDump,_BlockingObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveDestroyAmmoDump,_Position,"ARRAY",[]);
OO_END_SUBCLASS(ObjectiveDestroyAmmoDump);