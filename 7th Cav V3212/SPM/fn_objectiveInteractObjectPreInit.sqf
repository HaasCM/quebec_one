/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

#define INTERACTION_DISTANCE 5

SPM_ObjectiveInteractObject_InteractCondition =
{
	params ["_target", "_caller"];

	if (vehicle _caller != _caller) exitWith { false };

	if (not (lifeState _caller in ["HEALTHY", "INJURED"])) exitWith { false };

	private _data = _target getVariable "SPM_ObjectiveInteractObject_Data";
	if (not ([_target, _caller] call (_data select 2))) exitWith { false };

	true
};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_Interact) =
{
	params ["_target", "_caller"];

	private _data = _target getVariable "SPM_ObjectiveInteractObject_Data";
	_target removeAction (_data select 1);
	[_target, _caller] call (_data select 3);
	[_caller, _data select 0] remoteExec ["SPM_ObjectiveInteractObject_S_InteractionComplete", 2];
};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_C_AddActions) =
{
	params ["_object", "_interactionDescription", "_interactionCondition", "_interaction", "_objectiveReference"];

	if (isNull _object) exitWith {};

	if (not ([player] call SPM_Mission_IsSpecOpsMember)) exitWith {};

	private _action = _object addAction [_interactionDescription, { [_this select 0, _this select 1] call SPM_ObjectiveInteractObject_Interact },  [], 10, true, true, "", "[_target, _this] call SPM_ObjectiveInteractObject_InteractCondition", INTERACTION_DISTANCE];

	_object setVariable ["SPM_ObjectiveInteractObject_Data", [_objectiveReference, _action, _interactionCondition, _interaction]];
};

if (not isServer) exitWith {};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_S_InteractionComplete) =
{
	params ["_caller", "_objectiveReference"];

	private _objective = OO_INSTANCE(_objectiveReference);

	[_caller] call OO_METHOD(_objective,ObjectiveInteractObject,OnInteractionComplete);
};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_OnInteractionComplete) =
{
	params ["_objective", "_interactor"];

	OO_SET(_objective,MissionObjective,State,"completed");
};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_GetDescription) =
{
	params ["_objective"];

	OO_GET(_objective,ObjectiveInteractObject,ObjectiveDescription);
};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_Update) =
{
	params ["_objective"];

	private _updateTime = diag_tickTime + 1;
	OO_SET(_objective,Category,UpdateTime,_updateTime);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
			if (not isNull _object) then
			{
				private _interactionDescription = OO_GET(_objective,ObjectiveInteractObject,InteractionDescription);
				private _interactionCondition = OO_GET(_objective,ObjectiveInteractObject,InteractionCondition);
				private _interaction = OO_GET(_objective,ObjectiveInteractObject,Interaction);
				[_object, _interactionDescription, _interactionCondition, _interaction, OO_REFERENCE(_objective)] remoteExec ["SPM_ObjectiveInteractObject_C_AddActions", 0, true]; //JIP
				OO_SET(_objective,MissionObjective,State,"active");
			};
		};

		case "active":
		{
			private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
			if (isNull _object) exitWith { OO_SET(_objective,MissionObjective,State,"error") };
			if (not alive _object) exitWith { OO_SET(_objective,MissionObjective,State,"failed") };
		};

		case "completed";
		case "failed":
		{
			private _completionText = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
			_completionText = format ["%1 (%2)", _completionText, OO_GET(_objective,MissionObjective,State)];
			[[_completionText], ["log", "chat"]] call SPM_Mission_Message;

			OO_SET(_objective,Category,UpdateTime,1e30);
		};
	};
};

OO_BEGIN_SUBCLASS(ObjectiveInteractObject,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveInteractObject,Category,Update,SPM_ObjectiveInteractObject_Update);
	OO_OVERRIDE_METHOD(ObjectiveInteractObject,MissionObjective,GetDescription,SPM_ObjectiveInteractObject_GetDescription);
	OO_DEFINE_METHOD(ObjectiveInteractObject,OnInteractionComplete,SPM_ObjectiveInteractObject_OnInteractionComplete);
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,ObjectiveDescription,"STRING","Deactivate object");
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,InteractionDescription,"STRING","Deactivate");
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,InteractionCondition,"CODE",{true});
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,Interaction,"CODE",{});
OO_END_SUBCLASS(ObjectiveInteractObject);
