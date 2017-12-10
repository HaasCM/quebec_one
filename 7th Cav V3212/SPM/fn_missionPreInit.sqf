/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_Mission_AddObjective) =
{
	params ["_mission", "_objective"];

	[_objective] call OO_METHOD(_mission,Strongpoint,AddCategory);

	OO_GET(_mission,Mission,MissionObjectives) pushBack _objective;
};

OO_TRACE_DECL(SPM_Mission_UpdateMissionStatus) =
{
	params ["_mission"];

	private _objectives = OO_GET(_mission,Mission,MissionObjectives);

	private _objectiveStates = _objectives apply { OO_GET(_x,MissionObjective,State) };

	if ({ _x == "error" } count _objectiveStates > 0) then
	{
		private _objectiveDescriptions = [];
		{
			_objectiveDescriptions pushBack format ["%1 (%2)", [] call OO_METHOD(_x,MissionObjective,GetDescription), _objectiveStates select _forEachIndex];
		} forEach _objectives;

		[["Mission Status Report", "Mission ABORTED"] + _objectiveDescriptions] call SPM_Mission_Message;

		OO_SET(_mission,Strongpoint,RunState,"completed-error");
	};

	if ({ _x == "completed" } count _objectiveStates == count _objectives) then
	{
		private _objectiveDescriptions = [];
		{
			_objectiveDescriptions pushBack format ["%1 (%2)", [] call OO_METHOD(_x,MissionObjective,GetDescription), _objectiveStates select _forEachIndex];
		} forEach _objectives;

		[["Mission Status Report", "Mission COMPLETED"] + _objectiveDescriptions] call SPM_Mission_Message;

		OO_SET(_mission,Strongpoint,RunState,"completed-success");
	};

	if ({ _x == "failed" } count _objectiveStates > 0) then
	{
		private _objectiveDescriptions = [];
		{
			_objectiveDescriptions pushBack format ["%1 (%2)", [] call OO_METHOD(_x,MissionObjective,GetDescription), _objectiveStates select _forEachIndex];
		} forEach _objectives;

		[["Mission Status Report", "Mission FAILED"] + _objectiveDescriptions] call SPM_Mission_Message;

		OO_SET(_mission,Strongpoint,RunState,"completed-failure")
	};
};

OO_TRACE_DECL(SPM_Mission_Create) =
{
	params ["_mission", "_soc", "_center", "_radius"];

	[_center, _radius] call OO_METHOD_PARENT(_mission,Root,Create,Strongpoint);

	OO_SETREF(_mission,Mission,SpecialOperationsCommand,_soc);
};

OO_TRACE_DECL(SPM_Mission_Delete) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Root,Delete,Strongpoint);
};

OO_BEGIN_SUBCLASS(Mission,Strongpoint);
	OO_OVERRIDE_METHOD(Mission,Root,Create,SPM_Mission_Create);
	OO_OVERRIDE_METHOD(Mission,Root,Delete,SPM_Mission_Delete);
	OO_DEFINE_METHOD(Mission,AddObjective,SPM_Mission_AddObjective);
	OO_DEFINE_METHOD(Mission,UpdateMissionStatus,SPM_Mission_UpdateMissionStatus);
	OO_DEFINE_PROPERTY(Mission,SpecialOperationsCommand,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(Mission,MissionObjectives,"ARRAY",[]);
OO_END_SUBCLASS(Mission);

OO_BEGIN_SUBCLASS(MissionObjective,Category);
	OO_DEFINE_METHOD(MissionObjective,GetDescription,{""});
	OO_DEFINE_PROPERTY(MissionObjective,State,"STRING","starting"); // starting, active, failed, completed, error
	OO_DEFINE_PROPERTY(MissionObjective,ObjectiveObject,"OBJECT",objNull);
OO_END_SUBCLASS(MissionObjective);