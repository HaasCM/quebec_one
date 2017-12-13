/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveCompound_AddObjective) =
{
	params ["_compound", "_objective"];

	OO_GET(_compound,ObjectiveCompound,_Objectives) pushBack _objective;
	private _mission = OO_GET(_compound,Category,Strongpoint);
	if (OO_ISNULL(_mission)) then { diag_log "ObjectiveCompound: ERROR: Category,Strongpoint must be set prior to calls to AddObjective" };
	OO_SET(_objective,Category,Strongpoint,_mission);
};

OO_TRACE_DECL(SPM_ObjectiveCompound_GetDescription) =
{
	params ["_compound"];

	OO_GET(_compound,ObjectiveCompound,ObjectiveDescription);
};

OO_TRACE_DECL(SPM_ObjectiveCompound_Create) =
{
	params ["_compound", "_compoundDescription"];

	OO_SET(_compound,ObjectiveCompound,ObjectiveDescription,_compoundDescription);
};

OO_TRACE_DECL(SPM_ObjectiveCompound_Update) =
{
	params ["_compound"];

	private _updateTime = diag_tickTime + 10;
	private _objectives = OO_GET(_compound,ObjectiveCompound,_Objectives);

	private _starting = 0;
	private _active = 0;
	private _failed = 0;
	private _completed = 0;
	{
		if (diag_tickTime > OO_GET(_x,Category,UpdateTime)) then
		{
			[] call OO_METHOD(_x,Category,Update);
			_updateTime = _updateTime min OO_GET(_x,Category,UpdateTime);
		};

		switch (OO_GET(_x,MissionObjective,State)) do
		{
			case "starting": { _starting = _starting + 1 };
			case "active": { _active = _active + 1 };
			case "failed": { _failed = _failed + 1 };
			case "completed": { _completed = _completed + 1 };
		};
	} forEach _objectives;

	OO_SET(_compound,Category,UpdateTime,_updateTime);

	//TODO: More complex completion/failure options
	switch (true) do
	{
		case (_starting > 0):
		{
			OO_SET(_compound,MissionObjective,State,"starting");
		};

		case (_active == count _objectives):
		{
			OO_SET(_compound,MissionObjective,State,"active");
		};

		case (_failed > 0):
		{
			OO_SET(_compound,MissionObjective,State,"failed");
		};

		case (_completed == count _objectives):
		{
			OO_SET(_compound,MissionObjective,State,"completed");
		};
	};

	if (OO_GET(_compound,MissionObjective,State) in ["completed", "failed"]) then
	{
		private _completionText = [] call OO_METHOD(_compound,MissionObjective,GetDescription);
		_completionText = format ["%1 (%2)", _completionText, OO_GET(_compound,MissionObjective,State)];
		[[_completionText], ["log", "chat"]] call SPM_Mission_Message;

		OO_SET(_compound,Category,UpdateTime,1e30);
	};

	[] call OO_METHOD_PARENT(_compound,Category,Update,MissionObjective);
};

OO_BEGIN_SUBCLASS(ObjectiveCompound,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveCompound,Root,Create,SPM_ObjectiveCompound_Create);
	OO_OVERRIDE_METHOD(ObjectiveCompound,Category,Update,SPM_ObjectiveCompound_Update);
	OO_OVERRIDE_METHOD(ObjectiveCompound,MissionObjective,GetDescription,SPM_ObjectiveCompound_GetDescription);
	OO_DEFINE_METHOD(ObjectiveCompound,AddObjective,SPM_ObjectiveCompound_AddObjective);
	OO_DEFINE_PROPERTY(ObjectiveCompound,ObjectiveDescription,"STRING","");
	OO_DEFINE_PROPERTY(ObjectiveCompound,_Objectives,"ARRAY",[]);
OO_END_SUBCLASS(ObjectiveCompound);