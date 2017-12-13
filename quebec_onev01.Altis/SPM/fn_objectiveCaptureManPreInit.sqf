/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

#define INTERACTION_DISTANCE 2.0

SPM_ObjectiveCaptureMan_C_Accept =
{
	params ["_target"];

	_target switchMove "AmovPercMstpSsurWnonDnon_AmovPercMstpSnonWnonDnon";
};

SPM_ObjectiveCaptureMan_AcceptCondition =
{
	params ["_target", "_caller"];

	if (not alive _target) exitWith { false };

	if (not (lifeState _caller in ["HEALTHY", "INJURED"])) exitWith { false };

	animationState _target == "AmovPercMstpSsurWnonDnon"
};

SPM_ObjectiveCaptureMan_Accept =
{
	params ["_target", "_caller"];

	[_target, _caller] remoteExec ["SPM_ObjectiveCaptureMan_S_Accept", 2];
};

SPM_ObjectiveCaptureMan_C_SetupActions =
{
	params ["_target", "_targetDescription"];

	if (isNull _target) exitWith {};

	if (not ([player] call SPM_Mission_IsSpecOpsMember)) exitWith {};

	_target addAction ["Accept surrender of " + _targetDescription, { [_this select 0, _this select 1] call SPM_ObjectiveCaptureMan_Accept },  [], 10, true, true, "", "[_target, _this] call SPM_ObjectiveCaptureMan_AcceptCondition", INTERACTION_DISTANCE];
};

if (not isServer) exitWith {};

SPM_ObjectiveCaptureMan_S_Accept =
{
	params ["_target", "_caller"];

	[_target] remoteExec ["SPM_ObjectiveCaptureMan_C_Accept", 0, true]; //JIP

	_target enableAI "path"; // In case he was captured while garrisoned
	[_target] join group _caller;
	doStop _target;

	private _objective = (_target getVariable "OCM_S_State") select 0;
	OO_SET(_objective,MissionObjective,State,"completed");

	_target 
};

SPM_ObjectiveCaptureMan_GetDescription =
{
	params ["_objective"];

	private _unitProvider = OO_GET(_objective,ObjectiveCaptureMan,UnitProvider);
	private _unitDescription = OO_GET(_unitProvider,UnitProvider,UnitDescription);

	"Capture " + _unitDescription;
};

SPM_ObjectiveCaptureMan_Update =
{
	params ["_objective"];

	private _updateTime = diag_tickTime + 1;
	OO_SET(_objective,Category,UpdateTime,_updateTime);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			private _unitProvider = OO_GET(_objective,ObjectiveCaptureMan,UnitProvider);
			private _unit = OO_GET(_unitProvider,UnitProvider,Unit);

			if (typeName _unit != typeName "") then
			{
				OO_SET(_objective,MissionObjective,ObjectiveObject,_unit);

				_unit setVariable ["OCM_S_State", [_objective, false]];
				removeAllWeapons _unit;
				OO_SET(_objective,MissionObjective,State,"active");
			};
		};

		case "active":
		{
			private _unitProvider = OO_GET(_objective,ObjectiveCaptureMan,UnitProvider);
			private _unit = OO_GET(_unitProvider,UnitProvider,Unit);

			if (not alive _unit) exitWith { OO_SET(_objective,MissionObjective,State,"failed"); };

			private _surrendered = (_unit getVariable "OCM_S_State") select 1;
			if (not _surrendered) then
			{
				private _unitEyePosition = eyePos _unit;
				private _unitEyeDirection = eyeDirection _unit;

				private _nearestSoldiers = nearestObjects [_unit, ["B_soldier_base_F"], 10];
				{
					if (alive _x) then
					{
						private _toSoldier = (getPos _unit) vectorFromTo (getPos _x);
						private _dotProduct = _toSoldier vectorDotProduct _unitEyeDirection;

						if (_dotProduct > 0) then
						{
							if ([_unit, "GEOM", _x] checkVisibility [_unitEyePosition, eyePos _x] > 0) exitWith
							{
								_unit action ["surrender"];
								(_unit getVariable "OCM_S_State") set [1, true];
								private _unitDescription = OO_GET(_unitProvider,UnitProvider,UnitDescription);
								[_unit, _unitDescription] remoteExec ["SPM_ObjectiveCaptureMan_C_SetupActions", 0, true]; //JIP
							};
						};
					};
				} forEach _nearestSoldiers;
			};
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

SPM_ObjectiveCaptureMan_Create =
{
	params ["_objective", "_unitProvider"];

	OO_SET(_objective,ObjectiveCaptureMan,UnitProvider,_unitProvider);
};

OO_BEGIN_SUBCLASS(ObjectiveCaptureMan,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveCaptureMan,Root,Create,SPM_ObjectiveCaptureMan_Create);
	OO_OVERRIDE_METHOD(ObjectiveCaptureMan,Category,Update,SPM_ObjectiveCaptureMan_Update);
	OO_OVERRIDE_METHOD(ObjectiveCaptureMan,MissionObjective,GetDescription,SPM_ObjectiveCaptureMan_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveCaptureMan,UnitProvider,"ARRAY",OO_NULL);
OO_END_SUBCLASS(ObjectiveCaptureMan);
