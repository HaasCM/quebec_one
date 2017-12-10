/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_GuardObjectiveObject_WS_GuardArrived) =
{
	params ["_leader", "_units", "_guardGroup"];

	[_leader] call SPM_ChainSoldier;

	private _group = group _leader;
	if (group _leader != _guardGroup) then
	{
		[_leader] join _guardGroup;
		deleteGroup _group;
	};
};

OO_TRACE_DECL(SPM_GuardObjectiveObject_ObjectiveKilled) =
{
	params ["_object", "_killer", "_instigator"];

	private _objectData = _object getVariable "SPM_GuardObjectiveObject_Objective";
	private _category = _objectData select 0;
	private _handler = _objectData select 1;

	private _garrison = OO_GET(_category,GuardObjectiveObject,Garrison);
	private _guards = OO_GET(_category,GuardObjectiveObject,_Guards);

	{
		[_x] call SPM_UnchainSoldier;
	} forEach _guards;

	[group (_guards select 0)] call OO_METHOD(_garrison,InfantryGarrisonCategory,EndTemporaryDuty);
	OO_SET(_category,GuardObjectiveObject,_Guards,[]);

	_object removeEventHandler ["Killed", _handler];
	_object setVariable ["SPM_GuardObjectiveObject_Objective", nil];
};

OO_TRACE_DECL(SPM_GuardObjectiveObject_Update) =
{
	params ["_category"];

	private _updateTime = diag_tickTime + 1;
	OO_SET(_category,Category,UpdateTime,_updateTime);

	private _objective = OO_GET(_category,GuardObjectiveObject,Objective);
	private _objectiveObject = OO_GET(_objective,MissionObjective,ObjectiveObject);
	if (not alive _objectiveObject) exitWith {};

	private _numberGuards = OO_GET(_category,GuardObjectiveObject,NumberGuards);

	private _garrison = OO_GET(_category,GuardObjectiveObject,Garrison);
	private _group = [_numberGuards] call OO_METHOD(_garrison,InfantryGarrisonCategory,BeginTemporaryDuty);
	if (isNull _group) exitWith {};

	OO_SET(_category,GuardObjectiveObject,_Guards,units _group);

	// Quick and dirty version of "building occupy" at spots around the objective
	private _position = getPos _objectiveObject;
	private _guardGroup = grpNull;
	private _directions = [];
	private _direction = random 15;
	while { _direction < 360 } do { _directions pushBack _direction; _direction = _direction + (15 + random 15) };

	{
		private _soloGroup = createGroup (side _x);
		[_x] join _soloGroup;
		_x setBehaviour "safe";
		_x setCombatMode "green";
		_x setSpeedMode "limited";

		if (isNull _guardGroup) then { _guardGroup = _soloGroup };

		private _direction = _directions deleteAt (floor random count _directions);
		private _distance = 5.0 + random 2.0;
		private _directionVector = [_distance * sin _direction, _distance * cos _direction, 0]; //TODO: Go by a property on the objective to know how widely spaced the guards should be
		private _guardPosition = _position vectorAdd _directionVector;

		private _waypoint = [_soloGroup, _guardPosition] call SPM_AddPatrolWaypoint;
		[_waypoint, SPM_GuardObjectiveObject_WS_GuardArrived, _guardGroup] call SPM_AddPatrolWaypointStatements;
	} forEach units _group;

	// If the objective is killed, let the guards return to garrison duty
	private _eventHandler = _objectiveObject addEventHandler ["Killed", SPM_GuardObjectiveObject_ObjectiveKilled];
	_objectiveObject setVariable ["SPM_GuardObjectiveObject_Objective", [_category, _eventHandler]];

	OO_SET(_category,Category,UpdateTime,1e30);
};

OO_TRACE_DECL(SPM_GuardObjectiveObject_Delete) =
{
	params ["_category"];

	private _guards = OO_GET(_category,GuardObjectiveObject,_guards);

	if (count _guards > 0) then
	{
		private _groups = [];
		{ _groups pushBackUnique group _x } forEach _guards;

		private _garrison = OO_GET(_category,GuardObjectiveObject,Garrison);
		{
			[_x] call OO_METHOD(_garrison,InfantryGarrisonCategory,EndTemporaryDuty);
		} forEach _groups;
	};
};

OO_TRACE_DECL(SPM_GuardObjectiveObject_Create) =
{
	params ["_category", "_objective", "_garrison", "_numberGuards"];

	OO_SET(_category,GuardObjectiveObject,Objective,_objective);
	OO_SET(_category,GuardObjectiveObject,Garrison,_garrison);
	OO_SET(_category,GuardObjectiveObject,NumberGuards,_numberGuards);
};

OO_BEGIN_SUBCLASS(GuardObjectiveObject,Category);
	OO_OVERRIDE_METHOD(GuardObjectiveObject,Root,Create,SPM_GuardObjectiveObject_Create);
	OO_OVERRIDE_METHOD(GuardObjectiveObject,Root,Delete,SPM_GuardObjectiveObject_Delete);
	OO_OVERRIDE_METHOD(GuardObjectiveObject,Category,Update,SPM_GuardObjectiveObject_Update);
	OO_DEFINE_PROPERTY(GuardObjectiveObject,Objective,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(GuardObjectiveObject,Garrison,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(GuardObjectiveObject,NumberGuards,"SCALAR",0);
	OO_DEFINE_PROPERTY(GuardObjectiveObject,_Guards,"ARRAY",[]);
OO_END_SUBCLASS(GuardObjectiveObject);