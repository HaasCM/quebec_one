/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ProvideGarrisonUnit_MemberDescription) =
{
	params ["_appearanceType"];

	private _description = getText (configFile >> "CfgVehicles" >> _appearanceType >> "displayName");

	private _side = "";
	if (_appearanceType find "O_" == 0) then { _side = "CSAT "};
	if (_appearanceType find "I_G_" == 0) then { _side = "FIA "};
	if (_appearanceType find "I_C_" == 0) then { _side = "Syndikat "};
	if (_appearanceType find "I_" == 0) then { _side = "AAF "};
	if (_appearanceType find "B_" == 0) then { _side = "NATO "};
	// Don't do 'civilian'

	"the " + _side + _description
};

OO_TRACE_DECL(SPM_ProvideGarrisonUnit_Update) =
{
	params ["_category"];

	private _updateTime = diag_tickTime + 1;
	OO_SET(_category,Category,UpdateTime,_updateTime);

	private _garrison = OO_GET(_category,ProvideGarrisonUnit,Garrison);
	private _forceUnits = OO_GET(_garrison,ForceCategory,ForceUnits);

	if (count _forceUnits > 0) then
	{
		_forceUnits = _forceUnits select { alive OO_GET(_x,ForceUnit,Vehicle) };

		if (count _forceUnits > 0) then
		{
			private _garrisonIndex = OO_GET(_category,ProvideGarrisonUnit,GarrisonIndex);

			private _forceUnit = if (_garrisonIndex != -1) then { _forceUnits select _garrisonIndex } else { selectRandom _forceUnits };
			private _unit = OO_GET(_forceUnit,ForceUnit,Vehicle);

			private _appearanceType = OO_GET(_category,ProvideGarrisonUnit,AppearanceType);
			if (_appearanceType != "") then
			{
				private _unitPosition = getPosATL _unit;
				private _unitDirection = getDir _unit;

				_unit setPos (call SPM_Util_RandomSpawnPosition);

				private _descriptor = [[_appearanceType]] call SPM_fnc_groupFromClasses;
				private _group = [_descriptor select 0, _descriptor select 1, _unitPosition, _unitDirection, false] call SPM_fnc_spawnGroup;
				private _replacement = leader _group;

				private _garrisonSide = OO_GET(_garrison,ForceCategory,SideEast);
				private _replacementSide = side _replacement;
				if (_replacementSide == _garrisonSide) then
				{
					[_replacement] join (group _unit);
					deleteGroup _group;
				}
				else
				{
					if (_garrisonSide getFriend _replacementSide < 0.6) then
					{
						_replacement setCaptive true;
					};
				};

				OO_SET(_forceUnit,ForceUnit,Vehicle,_replacement); //TODO: Tell garrison to swap out the unit
				deleteVehicle _unit;
				_unit = _replacement;
			};

			_unit setVariable ["SGM_Category", _category];

			private _curatorTag = OO_GET(_category,ProvideGarrisonUnit,CuratorTag);
			if (_curatorTag != "") then
			{
				[_unit, "SGM", _curatorTag] call TRACE_SetObjectString;
			};

			_unit addEventHandler ["Killed",
				{
					params ["_unit", "_killer", "_instigator"];

					private _category = _unit getVariable "SGM_Category";
					private _unitDescription = OO_GET(_category,UnitProvider,UnitDescription);
					if (_unitDescription == "") then { _unitDescription = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName" )};

					private _name = if (not isNull _instigator) then { name _instigator } else { "A series of unfortunate events" };

					private _message = format ["%1 has killed %2", _name, _unitDescription];
					[_message, "systemchat"] call SPM_Mission_RemoteExecSpecOpsMembers;
				}];

			OO_SET(_category,UnitProvider,Unit,_unit);
			OO_SET(_category,Category,UpdateTime,1e30);
		};
	};
};

OO_TRACE_DECL(SPM_ProvideGarrisonUnit_Create) =
{
	params ["_category", "_garrison", "_garrisonIndex", "_appearanceType", "_unitDescription", "_curatorTag"];

	OO_SET(_category,ProvideGarrisonUnit,Garrison,_garrison);

	if (not isNil "_garrisonIndex") then
	{
		OO_SET(_category,ProvideGarrisonUnit,GarrisonIndex,_garrisonIndex);
	};

	if (not isNil "_appearanceType") then
	{
		OO_SET(_category,ProvideGarrisonUnit,AppearanceType,_appearanceType);
		private _unitDescription = [_appearanceType] call SPM_ProvideGarrisonUnit_MemberDescription;
		OO_SET(_category,UnitProvider,UnitDescription,_unitDescription);
	};

	if (not isNil "_unitDescription") then
	{
		OO_SET(_category,UnitProvider,UnitDescription,_unitDescription);
	};

	if (not isNil "_curatorTag") then
	{
		OO_SET(_category,ProvideGarrisonUnit,CuratorTag,_curatorTag);
	};
};

OO_BEGIN_SUBCLASS(UnitProvider,Category);
	OO_DEFINE_PROPERTY(UnitProvider,Unit,"OBJECT",""); // Empty string indicates "value never set"
	OO_DEFINE_PROPERTY(UnitProvider,UnitDescription,"STRING","");
OO_END_SUBCLASS(UnitProvider);

OO_BEGIN_SUBCLASS(ProvideGarrisonUnit,UnitProvider);
	OO_OVERRIDE_METHOD(ProvideGarrisonUnit,Root,Create,SPM_ProvideGarrisonUnit_Create);
	OO_OVERRIDE_METHOD(ProvideGarrisonUnit,Category,Update,SPM_ProvideGarrisonUnit_Update);
	OO_DEFINE_PROPERTY(ProvideGarrisonUnit,Garrison,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(ProvideGarrisonUnit,GarrisonIndex,"SCALAR",-1);
	OO_DEFINE_PROPERTY(ProvideGarrisonUnit,AppearanceType,"STRING","");
	OO_DEFINE_PROPERTY(ProvideGarrisonUnit,CuratorTag,"STRING","");
OO_END_SUBCLASS(ProvideGarrisonUnit);