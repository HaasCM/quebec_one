/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_MissionRaidTown_Update) =
{
	params ["_mission"];

	private _updateTime = diag_tickTime + 10;
	OO_SET(_mission,Strongpoint,UpdateTime,_updateTime);

	if (not OO_GET(_mission,MissionRaidTown,MissionAnnounced)) then
	{
		private _objectives = OO_GET(_mission,Mission,MissionObjectives);

		if (({ OO_GET(_x,MissionObjective,State) == "starting" } count _objectives) == 0) then
		{
			private _objectiveDescriptions = _objectives apply { [] call OO_METHOD(_x,MissionObjective,GetDescription) };

			private _positionDescription = [OO_GET(_mission,Strongpoint,Position)] call SPM_Util_PositionDescription;
			[["Mission Orders"] + _objectiveDescriptions + ["Area of operation: " + _positionDescription]] call SPM_Mission_Message;

			OO_SET(_mission,MissionRaidTown,MissionAnnounced,true);
		};
	};

	if (not OO_GET(_mission,MissionRaidTown,MissionAnnounced)) exitWith {};

	[] call OO_METHOD_PARENT(_mission,Mission,UpdateMissionStatus,Mission);
};

SPM_Util_CivilianRelocateProbabilityByTimeOfDay =
{
	private _high = 0.010;
	private _medium = 0.005;
	private _low = 0.0001;

	private _map =
	[
		[0.0, _low],
		[6.5, _low],
		[9.0, _high],
		[12.0, _medium],
		[17.0, _high],
		[20.0, _medium],
		[22.0, _low],
		[24.0, _low]
	];

	[dayTime, _map] call SPM_Util_MapValueRange;
};

SPM_MissionRaidTown_Armor_CallupsEast =
[
	["O_LSV_02_armed_F",
		[10, 2, {}]],
	["O_MRAP_02_hmg_F",
		[15, 3, {}]],
	["I_MRAP_03_hmg_F",
		[15, 3, {}]],
	["O_APC_Wheeled_02_rcws_F",
		[20, 3,
			{
				(_this select 0) removeMagazines "96Rnd_40mm_G_belt";
				(_this select 0) removeWeapon "GMG_40mm";
			}
		]],
	["I_APC_tracked_03_cannon_F",
		[35, 3, {}]]
];

SPM_MissionRaidTown_Armor_RatingsEast = SPM_MissionRaidTown_Armor_CallupsEast apply { [_x select 0, (_x select 1) select [0, 2]] };

OO_TRACE_DECL(SPM_MissionRaidTown_Create) =
{
	params ["_mission", "_soc", "_missionPosition", "_garrisonRadius", "_garrisonCount"];

	private _civilians = 40;
	private _syndikat = floor random (_civilians * 0.1);
	private _missionRadius = _garrisonRadius + 450;

	[_soc, _missionPosition, _missionRadius] call OO_METHOD_PARENT(_mission,Root,Create,Mission);

	OO_SET(_mission,Strongpoint,Name,"SpecialOperation");
	OO_SET(_mission,Strongpoint,InitializeObject,SERVER_InitializeObject);

	private _category = OO_NULL;
	private _categories = [];

	// Air defense
	_area = [_missionPosition, 0, _missionRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(AirDefenseCategory);
	_categories pushBack _category;

	// Transport
	_category = [] call OO_CREATE(TransportCategory);
	_categories pushBack _category;

	// Garrison
	_area = [_missionPosition, 0, _garrisonRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);

	private _basicInfantryRatingEast = OO_GET(_category,ForceCategory,RatingsEast) select 0 select 1 select 0; // The rating of the first east soldier type
	private _garrisonReserves = _garrisonCount * _basicInfantryRatingEast;

	OO_SET(_category,ForceCategory,Reserves,_garrisonReserves*0.2);
	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_garrisonReserves*0.8);

	private _basicInfantryRating = OO_GET(_category,ForceCategory,RatingsWest) select 0 select 1 select 0; // The rating of the first west soldier type
	private _minimumWestForce = [];
	for "_i" from 0 to floor ((_garrisonReserves * 0.5) / _basicInfantryRating) do
	{
		_minimumWestForce pushBack ([objNull, _basicInfantryRating] call OO_CREATE(ForceRating));
	};
	OO_SET(_category,InfantryGarrisonCategory,MinimumWestForce,_minimumWestForce);

	_categories pushBack _category;

	private _infantry = _category;

	// Infantry Patrols
	_area = [_missionPosition, _garrisonRadius, _garrisonRadius + 50] call OO_CREATE(StrongpointArea);
	_category = [_area, _infantry] call OO_CREATE(PerimeterPatrolCategory);
	_categories pushBack _category;

	[4, true, _garrisonRadius * 0.5, _garrisonRadius, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[4, true, _garrisonRadius * 0.5, _garrisonRadius, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[4, false, _garrisonRadius * 0.5, _garrisonRadius, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[4, false, _garrisonRadius * 0.5, _garrisonRadius, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);

	_area = [_missionPosition, _garrisonRadius + 50, _garrisonRadius + 100] call OO_CREATE(StrongpointArea);
	_category = [_area, _infantry] call OO_CREATE(PerimeterPatrolCategory);
	_categories pushBack _category;

	[2, true, _garrisonRadius * 0.5, _garrisonRadius, 50, 1, 0.5, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[2, true, _garrisonRadius * 0.5, _garrisonRadius, 50, 1, 0.5, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[2, false, _garrisonRadius * 0.5, _garrisonRadius, 50, 1, 0.5, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);

	// Civilians
	_area = [_missionPosition, _garrisonRadius + 75, _garrisonRadius + 350] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
	OO_SET(_category,Category,InitializeObject,SERVER_InitializeObject);
	OO_SET(_category,ForceCategory,SideEast,civilian);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsCivilian);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_RatingsCivilian);
	OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_RatingsCivilian);
	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_civilians);
	OO_SET(_category,InfantryGarrisonCategory,OccupationLimit,1);
	OO_SET(_category,InfantryGarrisonCategory,HouseOutdoors,false);
	OO_SET(_category,InfantryGarrisonCategory,RelocateProbability,SPM_Util_CivilianRelocateProbabilityByTimeOfDay);
	_categories pushBack _category;

	// Civilian Vehicles
	_category = [_area] call OO_CREATE(CivilianVehiclesCategory);
	OO_SET(_category,Category,InitializeObject,SERVER_InitializeObject);
	_categories pushBack _category;

	if (_syndikat > 0) then
	{
#ifdef OO_TRACE
		diag_log format ["SPM_MissionRaidTown_Create: creating %1 syndikat soldiers", _syndikat];
#endif
		_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
		OO_SET(_category,ForceCategory,SideEast,independent);
		OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsSyndikat);
		OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_RatingsSyndikat);
		OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_syndikat);
		OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_RatingsSyndikat);
		_categories pushBack _category;
	};

	// Armor
	_area = [_missionPosition, _garrisonRadius + 100, _garrisonRadius + 350] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(ArmorCategory);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_MissionRaidTown_Armor_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_MissionRaidTown_Armor_CallupsEast);

	private _armorReserves = 20 + (105 - random [0, 105, 0]); // At least a Qilin, then geometrically-diminishing chances of tougher vehicles
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

OO_TRACE_DECL(SPM_MissionRaidTown_Delete) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Root,Delete,Mission);
};

OO_BEGIN_SUBCLASS(MissionRaidTown,Mission);
	OO_OVERRIDE_METHOD(MissionRaidTown,Root,Create,SPM_MissionRaidTown_Create);
	OO_OVERRIDE_METHOD(MissionRaidTown,Root,Delete,SPM_MissionRaidTown_Delete);
	OO_OVERRIDE_METHOD(MissionRaidTown,Strongpoint,Update,SPM_MissionRaidTown_Update);
	OO_DEFINE_PROPERTY(MissionRaidTown,MissionAnnounced,"BOOL",false);
OO_END_SUBCLASS(MissionRaidTown);