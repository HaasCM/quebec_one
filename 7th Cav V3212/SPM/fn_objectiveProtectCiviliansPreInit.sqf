/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveProtectCivilians_GetDescription) =
{
	params ["_objective"];

	"Protect civilian population"
};

OO_TRACE_DECL(SPM_ObjectiveProtectCivilians_Update) =
{
	params ["_objective"];

	private _updateTime = diag_tickTime + 2;
	OO_SET(_objective,Category,UpdateTime,_updateTime);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			private _garrison = OO_GET(_objective,ObjectiveProtectCivilians,_Garrison);

			if (OO_ISNULL(_garrison)) then
			{
				private _mission = OO_GETREF(_objective,Category,Strongpoint);
				{
					if (OO_GET(_x,Root,Class) == OO_InfantryGarrisonCategory && { OO_GET(_x,ForceCategory,SideEast) == civilian }) exitWith { _garrison = _x };
				} forEach OO_GET(_mission,Strongpoint,Categories);

				if (not OO_ISNULL(_garrison)) then
				{
					OO_SET(_objective,ObjectiveProtectCivilians,_Garrison,_garrison);
					OO_SET(_objective,MissionObjective,State,"completed"); // Optional objective.  Default to complete, but detect failure
				};
			};
		};

		case "completed":
		{
			private _garrison = OO_GET(_objective,ObjectiveProtectCivilians,_Garrison);
			private _numberCivilians = OO_GET(_objective,ObjectiveProtectCivilians,_NumberCivilians);
			private _deathsPermitted = OO_GET(_objective,ObjectiveProtectCivilians,DeathsPermitted);

			private _civilians = OO_GET(_garrison,ForceCategory,ForceUnits);

			_numberCivilians = _numberCivilians max (count _civilians);
			OO_SET(_objective,ObjectiveProtectCivilians,_NumberCivilians,_numberCivilians);

			if (count _civilians + _deathsPermitted < _numberCivilians) then
			{
				private _message = format ["Too many civilians have died during this operation"];
				[_message, "systemchat"] call SPM_Mission_RemoteExecSpecOpsMembers;

				OO_SET(_objective,MissionObjective,State,"failed");
				OO_SET(_objective,Category,UpdateTime,1e30);
			};
		};
	};

	[] call OO_METHOD_PARENT(_objective,Category,Update,MissionObjective);
};

OO_BEGIN_SUBCLASS(ObjectiveProtectCivilians,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveProtectCivilians,Category,Update,SPM_ObjectiveProtectCivilians_Update);
	OO_OVERRIDE_METHOD(ObjectiveProtectCivilians,MissionObjective,GetDescription,SPM_ObjectiveProtectCivilians_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveProtectCivilians,DeathsPermitted,"SCALAR",5);
	OO_DEFINE_PROPERTY(ObjectiveProtectCivilians,_Garrison,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveProtectCivilians,_NumberCivilians,"SCALAR",0);
OO_END_SUBCLASS(ObjectiveProtectCivilians);