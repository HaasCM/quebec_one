/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

//#define TEST

#include "strongpoint.h"

#define UPDATE_INTERVAL (30 + random 150)

OO_TRACE_DECL(SPM_InfantryPatrol_PatrolComplete) =
{
	params ["_task", "_group"];

	private _patrol = _group getVariable "SPM_InfantryPatrol_Patrol";

	_patrol set [1, []];

	private _removePatrol = false;

	switch ([_task] call SPM_TaskGetState) do
	{
		case 1:
		{
			[_patrol] call OO_METHOD(_category,InfantryPatrolCategory,_CyclePatrol);
			if (count (_patrol select 1) == 0) then
			{
				_removePatrol = true;
			};
		};

		case -1:
		{
			_removePatrol = true;
		};
	};

	// If the patrol ended badly, get rid of it
	if (_removePatrol) then
	{
		[_category, _patrol] call SPM_InfantryPatrol_RemovePatrol;
	};
};

OO_TRACE_DECL(SPM_InfantryPatrol_StartPatrol) =
{
	params ["_category", "_patrol"];

	if (not isNull (_patrol select 0)) exitWith {};

	private _garrison = OO_GET(_category,InfantryPatrolCategory,Garrison);
	private _number = _patrol select 2 select 1;

	private _group = [_number] call OO_METHOD(_garrison,InfantryGarrisonCategory,BeginTemporaryDuty);

	if (isNull _group) exitWith { };

	_patrol set [0, _group];

	[_patrol] call OO_METHOD(_category,InfantryPatrolCategory,_CyclePatrol);

	// If the patrol doesn't start, get rid of it
	if (count (_patrol select 1) == 0) then
	{
		[_category, _patrol select 3] call SPM_InfantryPatrol_RemovePatrol;
	};
};

OO_TRACE_DECL(SPM_InfantryPatrol_StopPatrol) =
{
	params ["_category", "_patrol"];

	private _task = _patrol select 1;
	if (count _task != 0) then
	{
		[_task] call SPM_TaskStop;
	};
};

OO_TRACE_DECL(SPM_InfantryPatrol_AddPatrol) =
{
	params ["_category", "_number"];

	private _parameters = +_this;
	_parameters set [0, OO_REFERENCE(_parameters select 0)];

	private _patrolKey = -1;
	private _patrols = OO_GET(_category,InfantryPatrolCategory,Patrols);
	{
		_patrolKey = _patrolKey max (_x select 3);
	} forEach _patrols;
	_patrolKey = _patrolKey + 1;

	_patrols pushBack [grpNull, [], _parameters, _patrolKey];

	_patrolKey
};

OO_TRACE_DECL(SPM_InfantryPatrol_RemovePatrol) =
{
	params ["_category", "_patrolKey"];

	private _patrols = OO_GET(_category,InfantryPatrolCategory,Patrols);

	private _patrolIndex = -1;
	{
		if (_x select 3 == _patrolKey) exitWith { _patrolIndex = _forEachIndex };
	} forEach _patrols;

	if (_patrolIndex == -1) exitWith {};

	private _patrol = _patrols deleteAt _patrolIndex;

	private _task = _patrol select 1;
	if (count _task != 0) then
	{
		[_category, _patrol] call SPM_InfantryPatrol_StopPatrol;
	}
	else
	{
		private _group = _patrol select 0;
		if (not isNull _group) then
		{
			private _garrison = OO_GET(_category,InfantryPatrolCategory,Garrison);
			[_group] call OO_METHOD(_garrison,InfantryGarrisonCategory,EndTemporaryDuty);
		};
	};
};

OO_TRACE_DECL(SPM_InfantryPatrol_Create) =
{
	params ["_category", "_area", "_garrison"];

	OO_SET(_category,InfantryPatrolCategory,Area,_area);
	OO_SET(_category,InfantryPatrolCategory,Garrison,_garrison);
};

OO_TRACE_DECL(SPM_InfantryPatrol_Delete) =
{
	params ["_category"];

	private _garrison = OO_GET(_category,InfantryPatrolCategory,Garrison);
	private _patrols = OO_GET(_category,InfantryPatrolCategory,Patrols);
	while { count _patrols > 0 } do
	{
		[_patrols select 0 select 1] call SPM_TaskStop;
		[_category, _patrols select 0 select 3] call SPM_InfantryPatrol_RemovePatrol;
	};
};

OO_TRACE_DECL(SPM_InfantryPatrol_Update) =
{
	params ["_category"];

#ifdef TEST
	_updateTime = diag_tickTime + 1;
#else
	_updateTime = diag_tickTime + 30;
#endif
	OO_SET(_category,Category,UpdateTime,_updateTime);

	{
		private _group = _x select 0;
		private _task = _x select 1;
		if (count _task > 0 && { (isNull _group || { count units _group == 0 }) }) then
		{
			[_category, _x] call SPM_InfantryPatrol_StopPatrol;

			if (not isNull _group) then { deleteGroup _group };
			_x set [0, grpNull];
			_x set [1, []];
		};

		[_category, _x] call SPM_InfantryPatrol_StartPatrol;
	} forEach OO_GET(_category,InfantryPatrolCategory,Patrols);
};

OO_BEGIN_SUBCLASS(InfantryPatrolCategory,Category);
	OO_OVERRIDE_METHOD(InfantryPatrolCategory,Root,Create,SPM_InfantryPatrol_Create);
	OO_OVERRIDE_METHOD(InfantryPatrolCategory,Root,Delete,SPM_InfantryPatrol_Delete);
	OO_OVERRIDE_METHOD(InfantryPatrolCategory,Category,Update,SPM_InfantryPatrol_Update);
	OO_DEFINE_METHOD(InfantryPatrolCategory,AddPatrol,SPM_InfantryPatrol_AddPatrol);
	OO_DEFINE_METHOD(InfantryPatrolCategory,RemovePatrol,SPM_InfantryPatrol_RemovePatrol);
	OO_DEFINE_METHOD(InfantryPatrolCategory,_CyclePatrol,{});
	OO_DEFINE_PROPERTY(InfantryPatrolCategory,Garrison,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(InfantryPatrolCategory,Area,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(InfantryPatrolCategory,Patrols,"ARRAY",[]); // [group,task,parameters,patrol-key]  parameters always starts with [OO_REFERENCE(_category), _number]
OO_END_SUBCLASS(InfantryPatrolCategory);

OO_TRACE_DECL(SPM_PerimeterPatrol__CyclePatrol) =
{
	params ["_category", "_patrol"];

	private _group = _patrol select 0;
	(_patrol select 2) params ["_categoryRef", "_number", "_clockwise", "_minStep", "_maxStep", "_checkRadius", "_visit", "_enter", "_loiterChance"];

	private _area = OO_GET(_category,InfantryPatrolCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Center);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _task = [_group, _center, _innerRadius, _outerRadius, _clockwise, _minStep, _maxStep, _checkRadius, _visit, _enter, _loiterChance] call SPM_fnc_patrolPerimeter;

	if (_task isEqualTo [] || { ([_task] call SPM_TaskGetState) != 0 }) exitWith
	{
		_patrol set [1, []];
	};

	_patrol set [1, _task];
	_group setVariable ["SPM_InfantryPatrol_Patrol", _patrol];
	[_task, SPM_InfantryPatrol_PatrolComplete, _group] call SPM_TaskOnComplete;
};

OO_BEGIN_SUBCLASS(PerimeterPatrolCategory,InfantryPatrolCategory);
	OO_OVERRIDE_METHOD(PerimeterPatrolCategory,InfantryPatrolCategory,_CyclePatrol,SPM_PerimeterPatrol__CyclePatrol);
OO_END_SUBCLASS(PerimeterPatrolCategory);