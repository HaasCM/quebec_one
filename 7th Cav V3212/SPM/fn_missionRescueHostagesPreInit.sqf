/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_MissionRescueHostages_Update) =
{
	params ["_mission"];

	private _updateTime = diag_tickTime + 10;
	OO_SET(_mission,Strongpoint,UpdateTime,_updateTime);

	if (not OO_GET(_mission,MissionRescueHostages,MissionAnnounced)) then
	{
		private _objectives = OO_GET(_mission,Mission,MissionObjectives);

		if (({ OO_GET(_x,MissionObjective,State) == "starting" } count _objectives) == 0) then
		{
			private _objectiveDescriptions = _objectives apply { [] call OO_METHOD(_x,MissionObjective,GetDescription) };

			private _positionDescription = [OO_GET(_mission,Strongpoint,Position)] call SPM_Util_PositionDescription;
			[["Mission Orders"] + _objectiveDescriptions + ["Area of operation: " + _positionDescription]] call SPM_Mission_Message;

			OO_SET(_mission,MissionRescueHostages,MissionAnnounced,true);
		};
	};

	if (not OO_GET(_mission,MissionRescueHostages,MissionAnnounced)) exitWith {};

	[] call OO_METHOD_PARENT(_mission,Mission,UpdateMissionStatus,Mission);
};

SPM_MissionRescueHostages_Armor_CallupsSyndikat =
[
	["I_G_Offroad_01_armed_F", [10, 2, {}]]
];
SPM_MissionRescueHostages_Armor_RatingsSyndikat = SPM_MissionRescueHostages_Armor_CallupsSyndikat apply { [_x select 0, (_x select 1) select [0, 2]] };

OO_TRACE_DECL(SPM_MissionRescueHostages_Create) =
{
	params ["_mission", "_soc", "_missionPosition", "_hostageRadius", "_hostageCount", "_syndikatRadius", "_syndikatCount"];

	private _missionRadius = _syndikatRadius + 200;

	[_soc, _missionPosition, _missionRadius] call OO_METHOD_PARENT(_mission,Root,Create,Mission);

	OO_SET(_mission,Strongpoint,Name,"SpecialOperation");
	OO_SET(_mission,Strongpoint,InitializeObject,SERVER_InitializeObject);

	private _category = OO_NULL;
	private _categories = [];

	// Garrison
	_area = [_missionPosition, 0, _syndikatRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
	OO_SET(_category,ForceCategory,SideEast,independent);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsSyndikat);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsSyndikat);
	OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_InitialCallupsSyndikat);

	private _basicInfantryRatingEast = OO_GET(_category,ForceCategory,RatingsEast) select 0 select 1 select 0; // The rating of the first east soldier type
	private _syndikatReserves = _syndikatCount * _basicInfantryRatingEast;

	OO_SET(_category,ForceCategory,Reserves,_syndikatReserves*0.2);
	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_syndikatReserves*0.8);

	private _basicInfantryRating = OO_GET(_category,ForceCategory,RatingsWest) select 0 select 1 select 0; // The rating of the first west soldier type
	private _minimumWestForce = [];
	for "_i" from 0 to floor ((_syndikatReserves * 0.5) / _basicInfantryRating) do
	{
		_minimumWestForce pushBack ([objNull, _basicInfantryRating] call OO_CREATE(ForceRating));
	};
	OO_SET(_category,InfantryGarrisonCategory,MinimumWestForce,_minimumWestForce);

	_categories pushBack _category;

	private _infantry = _category;

	// Infantry Patrols
	_area = [_missionPosition, _syndikatRadius, _syndikatRadius + 50] call OO_CREATE(StrongpointArea);
	_category = [_area, _infantry] call OO_CREATE(PerimeterPatrolCategory);
	_categories pushBack _category;

	[4, true, _syndikatRadius * 0.5, _syndikatRadius, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[4, false, _syndikatRadius * 0.5, _syndikatRadius, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);

	_area = [_missionPosition, _syndikatRadius + 50, _syndikatRadius + 100] call OO_CREATE(StrongpointArea);
	_category = [_area, _infantry] call OO_CREATE(PerimeterPatrolCategory);
	_categories pushBack _category;

	[4, true, _syndikatRadius * 0.5, _syndikatRadius, 50, 1, 0.5, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[4, true, _syndikatRadius * 0.5, _syndikatRadius, 50, 1, 0.5, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);

	// Civilians
	_area = [_missionPosition, 0, _hostageRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
	OO_SET(_category,ForceCategory,SideEast,civilian);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsCivilian);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_RatingsCivilian);
	OO_SET(_category,InfantryGarrisonCategory,RelocateProbability,0);

	// Compose a unit to represent the hostages because units are housed together
	//TODO: Theme the hostage unit.  Scientists, Mayor and staff, Diplomats, and so on.  Allow caller to supply array of classes so he can theme this.
	private _hostageClasses = [];
	for "_i" from 1 to _hostageCount do
	{
		_hostageClasses pushBack ((selectRandom SPM_InfantryGarrison_RatingsCivilian) select 0);
	};
	private _hostageCallups = [[_hostageClasses, [1, _hostageCount]]];
	OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,_hostageCallups);
	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_hostageCount);
	OO_SET(_category,InfantryGarrisonCategory,OccupationLimit,_hostageCount);
	OO_SET(_category,InfantryGarrisonCategory,HouseOutdoors,false);
	OO_SET(_category,ForceCategory,Reserves,0);

	_categories pushBack _category;

	private _civilians = _category;

	// Armor
	_area = [_missionPosition, _syndikatRadius, _syndikatRadius + 100] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(ArmorCategory);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_MissionRescueHostages_Armor_RatingsSyndikat);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_MissionRescueHostages_Armor_CallupsSyndikat);

	private _armorReserves = 40;
	OO_SET(_category,ForceCategory,Reserves,_armorReserves);

	private _basicArmorRating = 35;
	private _minimumWestForce = [];
	_minimumWestForce pushBack ([objNull, _basicArmorRating] call OO_CREATE(ForceRating));
	_minimumWestForce pushBack ([objNull, _basicArmorRating] call OO_CREATE(ForceRating));
	_minimumWestForce pushBack ([objNull, _basicArmorRating] call OO_CREATE(ForceRating));
	OO_SET(_category,ArmorCategory,InitialMinimumWestForce,_minimumWestForce);
	OO_SET(_category,ArmorCategory,MinimumWestForce,_minimumWestForce);

	_categories pushBack _category;

	private _armor = _category;

	// Possibility of making an armor unit idle and available to players to steal
	if (random 1 < 0.25) then
	{
		_category = [_armor, 1] call OO_CREATE(ArmorIdleCategory);

		_categories pushBack _category;
	};

	{
		[_x] call OO_METHOD(_mission,Strongpoint,AddCategory);
	} forEach _categories;
};

OO_TRACE_DECL(SPM_MissionRescueHostages_Delete) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Root,Delete,Mission);
};

OO_BEGIN_SUBCLASS(MissionRescueHostages,Mission);
	OO_OVERRIDE_METHOD(MissionRescueHostages,Root,Create,SPM_MissionRescueHostages_Create);
	OO_OVERRIDE_METHOD(MissionRescueHostages,Root,Delete,SPM_MissionRescueHostages_Delete);
	OO_OVERRIDE_METHOD(MissionRescueHostages,Strongpoint,Update,SPM_MissionRescueHostages_Update);
	OO_DEFINE_PROPERTY(MissionRescueHostages,MissionAnnounced,"BOOL",false);
OO_END_SUBCLASS(MissionRescueHostages);