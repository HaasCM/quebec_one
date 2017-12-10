/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

//#define TEST

#include "strongpoint.h"

SERVER_SpecialOperationsBlacklist =
{
	private _blacklist = [];

	private _parameters = [_blacklist];
	private _code =
		{
			params ["_blacklist"];
			_blacklist pushBack [OO_GET(_x,Strongpoint,Radius), OO_GET(_x,Strongpoint,Position)];
			false
		};
	OO_FOREACHINSTANCE(Strongpoint,_parameters,_code);

	if (currentAO != "") then
	{
		_blacklist pushBack [PARAMS_AOSize, getMarkerPos currentAO];
	};

	_blacklist pushBack ([0, getPos Headquarters] + triggerArea Headquarters);
	_blacklist pushBack ([0, getPos Carrier] + triggerArea Carrier);

	_blacklist
};

SPM_SOC_PaddedBlacklist =
{
	params ["_blacklist", "_distance"];

	_blacklist = +_blacklist;
	{
		_x set [0, (_x select 0) + _distance];
	} forEach _blacklist;

	_blacklist
};

SPM_Chain_PositionToConvoyRoute =
{
	params ["_data", "_direction", "_distanceToRoad", "_lengthOfRoute", "_blacklist"];

	private _roads = [];

	if (_direction == -1) then
	{
		_roads = [_data, "convoy-start-roads"] call SPM_GetDataValue;
	}
	else
	{
		private _position = [_data, "position"] call SPM_GetDataValue;

		_roads = [];
		{
			private _road = _x;
			{
				_roads pushBack [_road, _x];
			} forEach roadsConnectedTo _x;
		} forEach (_position nearRoads _distanceToRoad);

		[_data, "convoy-start-roads", _roads] call SPM_SetDataValue;
	};

	private _route = [];

	while { count _roads > 0 } do
	{
		private _road = _roads deleteAt (floor random count _roads);

		_route = [_road select 0, _road select 1, (_road select 0) getDir (_road select 1), _lengthOfRoute, _blacklist] call SPM_Nav_FollowRoute;

		if (count _route > 0) exitWith
		{
			// Remove visited road segments near to the start point from our list of start roads.  No point in duplicating a search on the same path.
			private _nearbyRoads = _route select [0, floor (_distanceToRoad / 10)];
			{
				private _nearbyRoad = _x;
				{ if (_x select 1 == _nearbyRoad) exitWith { _roads deleteAt _forEachIndex } } forEach _roads;
			} forEach _nearbyRoads;

			[_data, "convoy-start-roads", _roads] call SPM_SetDataValue;
		};
	};

	if (count _route == 0) exitWith { false };

#ifdef OO_TRACE
	diag_log format ["SPM_Chain_PositionToConvoyRoute: from %1 to %2 (direct %3m)", _route select 0, _route select (count _route - 1), (_route select 0) distance (_route select (count _route - 1))];
#endif
	[_data, "convoy-route", _route] call SPM_SetDataValue;

	true
};

OO_TRACE_DECL(SPM_SOC_MissionInterceptConvoy) =
{
	params ["_soc", "_escortType"];

#ifdef TEST
		_convoyStartTime = diag_tickTime + 10;
#else
		_convoyStartTime = diag_tickTime + (60 + random 120);
#endif

	private _referencePosition = OO_GET(_soc,SpecialOperationsCommand,ReferencePosition);
	private _blacklist = [OO_GET(_soc,SpecialOperationsCommand,Blacklist), 1000] call SPM_SOC_PaddedBlacklist;

	// Generate the convoy route

	private _data = [];
	private _chain =
		[
			[SPM_Chain_NearestLocation, [_referencePosition, 10000, ["NameLocal", "NameVillage","NameCity","NameCityCapital"]]],
			[SPM_Chain_PositionToIsolatedPosition, [_blacklist]],
			[SPM_Chain_PositionToConvoyRoute, [100, 6000, _blacklist]]
		];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (not _complete) exitWith { OO_NULL }; // This shouldn't happen

	private _convoyRoute = [_data, "convoy-route"] call SPM_GetDataValue;
	private _convoyPositions = _convoyRoute apply { getPos _x };
	_convoyPositions deleteAt 0; // Move away from starting intersection

	// Spacing before a given vehicle
	private _normalSpacing = [] call OO_CREATE(ConvoySpacing);
	private _wideSpacing = [50^2, 60^2, 80^2, 100^2, 150^2] call OO_CREATE(ConvoySpacing);

	private _teamDescriptor = [(configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam")] call SPM_fnc_groupFromConfig;

	private _convoyDescription = [];

	switch (_escortType) Do
	{
		case 1:
		{
			_convoyDescription pushBack (["O_MRAP_02_hmg_F", [{},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_APC_Wheeled_02_rcws_F", [{},[0]], [_teamDescriptor, _teamDescriptor], _wideSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_Truck_03_covered_F", [{},[0]], [_teamDescriptor, _teamDescriptor, _teamDescriptor, _teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_MRAP_02_F", [{},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
		};

		case 2:
		{
			_convoyDescription pushBack (["O_LSV_02_armed_F", [{},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_APC_Wheeled_02_rcws_F",
				[
					{
						[_this select 0] call SPM_Transport_RemoveWeapons;

						(_this select 0) addMagazine "500Rnd_65x39_Belt_Tracer_Green_Splash";
						(_this select 0) addWeapon "LMG_RCWS";
					},[0]], [_teamDescriptor, _teamDescriptor], _wideSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_APC_Wheeled_02_rcws_F",
				[
					{
						[_this select 0] call SPM_Transport_RemoveWeapons;

						(_this select 0) addMagazine "500Rnd_65x39_Belt_Tracer_Green_Splash";
						(_this select 0) addWeapon "LMG_RCWS";
					},[0]], [_teamDescriptor, _teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_LSV_02_unarmed_F", [{},[0]], [_teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
		};

		case 3:
		{
			_convoyDescription pushBack (["O_LSV_02_armed_F", [{},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_LSV_02_unarmed_F", [{},[0]], [_teamDescriptor], _wideSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_Truck_03_transport_F", [{},[0]], [_teamDescriptor, _teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_LSV_02_unarmed_F", [{},[0]], [_teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
		};

		case 4:
		{
			_convoyDescription pushBack (["O_G_Offroad_01_armed_F", [{},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_G_Offroad_01_armed_F", [{},[0]], [], _wideSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_G_Offroad_01_F", [{},[0]], [_teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_G_Offroad_01_F", [{},[0]], [_teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
		};
	};

	private _convoySpeed = 40;

	private _mission = [_soc, _convoyPositions, _convoyDescription, _convoyStartTime, _convoySpeed] call OO_CREATE(MissionInterceptConvoy);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionInterceptObjectiveVehicles) =
{
	params ["_soc"];

#ifdef TEST
		_convoyStartTime = diag_tickTime + 10;
#else
		_convoyStartTime = diag_tickTime + (120 + random 60);
#endif

	private _referencePosition = OO_GET(_soc,SpecialOperationsCommand,ReferencePosition);
	private _blacklist = [OO_GET(_soc,SpecialOperationsCommand,Blacklist), 1000] call SPM_SOC_PaddedBlacklist;

	// Generate the convoy route

	private _data = [];
	private _chain =
		[
			[SPM_Chain_NearestLocation, [_referencePosition, 10000, ["NameLocal", "NameVillage","NameCity","NameCityCapital"]]],
			[SPM_Chain_PositionToIsolatedPosition, [_blacklist]],
			[SPM_Chain_PositionToConvoyRoute, [100, 6000, _blacklist]]
		];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (not _complete) exitWith { OO_NULL }; // This shouldn't happen

	private _convoyRoute = [_data, "convoy-route"] call SPM_GetDataValue;
	private _convoyPositions = _convoyRoute apply { getPos _x };

	private _convoyDescription = [];
	private _convoySpeed = 60;

	private _mission = [_soc, _convoyPositions, _convoyDescription, _convoyStartTime, _convoySpeed] call OO_CREATE(MissionInterceptConvoy);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionRaidTown) =
{
	params ["_soc", "_garrisonRadius", "_garrisonCount"];

	private _referencePosition = OO_GET(_soc,SpecialOperationsCommand,ReferencePosition);
	private _blacklist = [OO_GET(_soc,SpecialOperationsCommand,Blacklist), 2000] call SPM_SOC_PaddedBlacklist;

	_data = [];
	_chain =
		[
			[SPM_Chain_NearestLocation, [_referencePosition, 10000, ["NameLocal", "NameVillage","NameCity","NameCityCapital"]]],
			[SPM_Chain_PositionToIsolatedPosition, [_blacklist]],
			[SPM_Chain_PositionToBuildings, [0, 700]],
			[SPM_Chain_BuildingsToEnterableBuildings, []],
			[SPM_Chain_EnterableBuildingsToOccupancyBuildings, [4]],
			[SPM_Chain_OccupancyBuildingsToGarrisonPosition, [_garrisonRadius, _garrisonCount, false]]
		];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (not _complete) exitWith { OO_NULL };

	private _position = [_data, "garrison-position"] call SPM_GetDataValue;

	private _mission = [_soc, _position, _garrisonRadius, _garrisonCount] call OO_CREATE(MissionRaidTown);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionCaptureOfficer) =
{
	params ["_soc"];

	private _mission = [_soc, 50, 40] call SPM_SOC_MissionRaidTown;

	private _infantryGarrison = OO_NULL;
	{
		if (OO_GET(_x,Root,Class) == OO_InfantryGarrisonCategory) exitWith { _infantryGarrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _category = [_infantryGarrison, nil, "O_officer_F", nil, "OFFICER"] call OO_CREATE(ProvideGarrisonUnit);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _unitProvider = _category;

	private _objective = [_unitProvider] call OO_CREATE(ObjectiveCaptureMan);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _debriefingArea = [0, getPos SpecOpsHQ] + triggerArea SpecOpsHQ;
	private _objective = [_unitProvider, _debriefingArea, "SpecOps headquarters"] call OO_CREATE(ObjectiveDebriefMan);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _objective = [] call OO_CREATE(ObjectiveProtectCivilians);
	OO_SET(_objective,ObjectiveProtectCivilians,DeathsPermitted,5);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionRescueSoldier) =
{
	params ["_soc"];

	private _mission = [_soc, 50, 40] call SPM_SOC_MissionRaidTown;

	private _infantryGarrison = OO_NULL;
	{
		if (OO_GET(_x,Root,Class) == OO_InfantryGarrisonCategory) exitWith { _infantryGarrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _category = [_infantryGarrison, nil, "B_survivor_F", nil, "SOLDIER"] call OO_CREATE(ProvideGarrisonUnit);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _unitProvider = _category;

	private _objective = [_unitProvider] call OO_CREATE(ObjectiveRescueMan);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _category = [_objective, _infantryGarrison, 4] call OO_CREATE(GuardObjectiveObject);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _debriefingArea = [0, getPos SpecOpsHQ] + triggerArea SpecOpsHQ;
	private _objective = [_unitProvider, _debriefingArea, "SpecOps headquarters"] call OO_CREATE(ObjectiveDebriefMan);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _objective = [] call OO_CREATE(ObjectiveProtectCivilians);
	OO_SET(_objective,ObjectiveProtectCivilians,DeathsPermitted,5);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionDestroyAmmoDump) =
{
	params ["_soc"];

	private _mission = [_soc, 50, 40] call SPM_SOC_MissionRaidTown;

	private _infantryGarrison = OO_NULL;
	{
		if (OO_GET(_x,Root,Class) == OO_InfantryGarrisonCategory) exitWith { _infantryGarrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _position = OO_GET(_mission,Strongpoint,Position);
	private _area = [_position, 0, 50] call OO_CREATE(StrongpointArea);

	private _objective = [_area] call OO_CREATE(ObjectiveDestroyAmmoDump);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _category = [_objective, _infantryGarrison, 4] call OO_CREATE(GuardObjectiveObject);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [] call OO_CREATE(ObjectiveProtectCivilians);
	OO_SET(_objective,ObjectiveProtectCivilians,DeathsPermitted,5);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionDestroyRadioTower) =
{
	params ["_soc"];

	private _mission = [_soc, 50, 40] call SPM_SOC_MissionRaidTown;

	private _infantryGarrison = OO_NULL;
	{
		if (OO_GET(_x,Root,Class) == OO_InfantryGarrisonCategory) exitWith { _infantryGarrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _position = OO_GET(_mission,Strongpoint,Position);
	private _area = [_position, 0, 50] call OO_CREATE(StrongpointArea);

	private _objective = ["Land_Communication_F", _area] call OO_CREATE(ObjectiveDestroyRadioTower);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _category = [_objective, _infantryGarrison, 2] call OO_CREATE(GuardObjectiveObject);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [] call OO_CREATE(ObjectiveProtectCivilians);
	OO_SET(_objective,ObjectiveProtectCivilians,DeathsPermitted,5);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

SPM_SOC_DestroyVehicleDescriptors =
[
	["B_Heli_Light_01_dynamicLoadout_F", [
		{
			(_this select 0) setObjectTexture [0,"\a3\air_f\heli_light_01\data\heli_light_01_ext_indp_co.paa"];
		}, [0]]],

	["I_Heli_light_03_dynamicLoadout_F", [{}, [0]]],
	["I_APC_tracked_03_cannon_F", [{}, [0]]]
];

OO_TRACE_DECL(SPM_SOC_MissionDestroyVehicle) =
{
	params ["_soc"];

	private _mission = [_soc, 50, 40] call SPM_SOC_MissionRaidTown;

	private _infantryGarrison = OO_NULL;
	{
		if (OO_GET(_x,Root,Class) == OO_InfantryGarrisonCategory) exitWith { _infantryGarrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _position = OO_GET(_mission,Strongpoint,Position);
	private _area = [_position, 0, 75] call OO_CREATE(StrongpointArea);

	private _objective = [selectRandom SPM_SOC_DestroyVehicleDescriptors, _area] call OO_CREATE(ObjectiveDestroyVehicle);
	OO_SET(_objective,ObjectiveDestroyObject,CaptureDistance,1000);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _category = [_objective, _infantryGarrison, 2] call OO_CREATE(GuardObjectiveObject);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [] call OO_CREATE(ObjectiveProtectCivilians);
	OO_SET(_objective,ObjectiveProtectCivilians,DeathsPermitted,5);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

SPM_SOC_ConvoyTargetVehicles =
[
	["Capture the device, move 500m clear of capture location", 1, ["O_Truck_03_device_F", [{},[0]]]],
	["Capture the communications gear, move 500m clear of capture location", 3, ["O_Truck_03_repair_F", [{ (_this select 0) setRepairCargo 0 },[0]]]],
	["Capture the advanced weaponry, move 500m clear of capture location", 1, ["O_Truck_03_ammo_F", [{ (_this select 0) setAmmoCargo 0 },[0]]]],
	["Capture the rocket fuel, move 500m clear of capture location", 4, ["O_Truck_03_fuel_F", [{ (_this select 0) setFuelCargo 0 },[0]]]],
	["Capture the biological materials, move 500m clear of capture location", 2, ["O_Truck_03_medical_F", [{},[0]]]]
];

OO_TRACE_DECL(SPM_SOC_MissionCaptureTruck) =
{
	params ["_soc"];

	private _target = selectRandom SPM_SOC_ConvoyTargetVehicles;

	private _mission = [_soc, _target select 1] call SPM_SOC_MissionInterceptConvoy;

	private _normalSpacing = [] call OO_CREATE(ConvoySpacing);
	private _convoyVehicle = [_target select 2 select 0, _target select 2 select 1, [], _normalSpacing] call OO_CREATE(ConvoyVehicle);
	private _objective = [_convoyVehicle, _target select 0] call OO_CREATE(ObjectiveCaptureConvoyVehicle);
	OO_SET(_objective,ObjectiveCaptureConvoyVehicle,CaptureDistance,500);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionRescueHostages) =
{
	params ["_soc"];

	private _hostageRadius = 50;
	private _hostageCount = 4;
	private _garrisonRadius = 50;
	private _garrisonCount = 40;

	private _referencePosition = OO_GET(_soc,SpecialOperationsCommand,ReferencePosition);
	private _blacklist = [OO_GET(_soc,SpecialOperationsCommand,Blacklist), 2000] call SPM_SOC_PaddedBlacklist;

	_data = [];
	_chain =
		[
			[SPM_Chain_NearestLocation, [_referencePosition, 10000, ["NameLocal", "NameVillage","NameCity","NameCityCapital"]]],
			[SPM_Chain_PositionToIsolatedPosition, [_blacklist]],
			[SPM_Chain_PositionToBuildings, [0, 700]],
			[SPM_Chain_BuildingsToEnterableBuildings, []],
			[SPM_Chain_EnterableBuildingsToOccupancyBuildings, [4]],
			[SPM_Chain_OccupancyBuildingsToGarrisonPosition, [_garrisonRadius, _garrisonCount, false]]
		];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (not _complete) exitWith { OO_NULL };

	private _position = [_data, "garrison-position"] call SPM_GetDataValue;

	private _numberHostages = 4;
	private _mission = [_soc, _position, 50, _numberHostages, 100, 40] call OO_CREATE(MissionRescueHostages);

	private _civilianGarrison = OO_NULL;
	{
		if (OO_GET(_x,Root,Class) == OO_InfantryGarrisonCategory && { OO_GET(_x,ForceCategory,SideEast) == civilian }) exitWith { _civilianGarrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _providers = [];
	for "_i" from 1 to _numberHostages do
	{
		private _provider = [_civilianGarrison, _i - 1, nil, "hostage", "HOSTAGE"] call OO_CREATE(ProvideGarrisonUnit);
		[_provider] call OO_METHOD(_mission,Strongpoint,AddCategory);
		_providers pushBack _provider;
	};

	private _compoundObjective = ["Rescue hostages"] call OO_CREATE(ObjectiveCompound);
	[_compoundObjective] call OO_METHOD(_mission,Mission,AddObjective); // Must be added to mission before its sub-objectives so it can tell the sub-objectives about the mission

	for "_i" from 1 to _numberHostages do
	{
		private _objective = [_providers select (_i - 1)] call OO_CREATE(ObjectiveRescueMan);
		[_objective] call OO_METHOD(_compoundObjective,ObjectiveCompound,AddObjective);
	};

	private _compoundObjective = ["Release hostages clear of area (500 meters)"] call OO_CREATE(ObjectiveCompound);
	[_compoundObjective] call OO_METHOD(_mission,Mission,AddObjective); // Must be added to mission before its sub-objectives so it can tell the sub-objectives about the mission

	for "_i" from 1 to _numberHostages do
	{
		private _objective = [_providers select (_i - 1), "hostage"] call OO_CREATE(ObjectiveDeliverMan);
		OO_SET(_objective,ObjectiveDeliverMan,DeliverDistance,500);
		[_objective] call OO_METHOD(_compoundObjective,ObjectiveCompound,AddObjective);
	};

	_mission
};

// Do not OO_TRACE_DECL this method.  It is sent to clients.
SPM_MissionInterceptCourier_InteractionCondition =
{
	params ["_target", "_caller"];

	if (side _target == east) exitWith { false };

	if (speed _target > 0) exitWith { false };

	true
};

// Do not OO_TRACE_DECL this method.  It is sent to clients.
SPM_MissionInterceptCourier_Interaction =
{
	params ["_target", "_caller"];

	private _doors = ["door_rf", "door_lf", "door_rm", "door_lm", "door_rear"];

	while { count _doors > 0 } do
	{
		[_target, [_doors deleteAt (floor random count _doors), 1]] remoteExec ["animateDoor", 0];
		sleep 0.5 + (random 0.5);
	};
};

OO_TRACE_DECL(SPM_SOC_MissionInterceptCourier) =
{
	params ["_soc"];

	private _mission = [_soc] call SPM_SOC_MissionInterceptObjectiveVehicles;

	private _normalSpacing = [] call OO_CREATE(ConvoySpacing);
	private _convoyVehicle = (["O_MRAP_02_hmg_F", [
		{
				[_this select 0] call SPM_Transport_RemoveWeapons;
				(_this select 0) addMagazine "500Rnd_65x39_Belt_Tracer_Green_Splash";
				(_this select 0) addWeapon "LMG_RCWS";
		},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
	private _objective = [_convoyVehicle, "Prevent courier vehicle from reaching destination"] call OO_CREATE(ObjectiveInterceptVehicle);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _interceptObjective = _objective;

	private _objective = [0] call OO_CREATE(ObjectiveInteractObjectConvoyVehicle);
	OO_SET(_objective,ObjectiveInteractObject,ObjectiveDescription,"Retrieve intel from courier vehicle");
	OO_SET(_objective,ObjectiveInteractObject,InteractionDescription,"Search vehicle for intel");
	OO_SET(_objective,ObjectiveInteractObject,InteractionCondition,SPM_MissionInterceptCourier_InteractionCondition);
	OO_SET(_objective,ObjectiveInteractObject,Interaction,SPM_MissionInterceptCourier_Interaction);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

#ifdef TEST
SPM_SOC_MissionTypes =
[
	[[], SPM_SOC_MissionCaptureOfficer],
	[[], SPM_SOC_MissionRescueSoldier],
	[[], SPM_SOC_MissionDestroyAmmoDump],
	[[], SPM_SOC_MissionDestroyRadioTower],
	[[], SPM_SOC_MissionDestroyVehicle],
	[[], SPM_SOC_MissionCaptureTruck],
	[[], SPM_SOC_MissionInterceptCourier],
	[[], SPM_SOC_MissionRescueHostages]
];
#else
SPM_SOC_MissionTypes =
[
	[[], SPM_SOC_MissionCaptureOfficer],
	[[], SPM_SOC_MissionRescueSoldier],
	[[], SPM_SOC_MissionDestroyAmmoDump],
	[[], SPM_SOC_MissionDestroyRadioTower],
	[[], SPM_SOC_MissionDestroyVehicle],
	[[], SPM_SOC_MissionCaptureTruck],
	[[], SPM_SOC_MissionInterceptCourier],
	[[], SPM_SOC_MissionRescueHostages]
];
#endif

OO_TRACE_DECL(SPM_SOC_RunMissionSequence) =
{
	params ["_soc"];

	OO_SET(_soc,SpecialOperationsCommand,CommandState,"running");

	private _missionSequence = OO_GET(_soc,SpecialOperationsCommand,MissionSequence);
	private _missionNumber = 0;

	private _missionComplete = false;

	while { (_missionNumber < count _missionSequence) && SPM_SpecialOperationsEnabled } do
	{
		private _missionDescriptor = _missionSequence select _missionNumber;
		_missionNumber = _missionNumber + 1;

		private _mission = ([_soc] + (_missionDescriptor select 0)) call (_missionDescriptor select 1);
		OO_SET(_soc,SpecialOperationsCommand,RunningMission,_mission);

		private _script = [_mission] spawn { params ["_mission"]; [] call OO_METHOD(_mission,Strongpoint,Run); }; // Cannot spawn OO_METHODs
		OO_SET(_soc,SpecialOperationsCommand,RunningMissionScript,_script);

		while { not scriptDone _script } do { sleep 1 };

		OO_SET(_soc,SpecialOperationsCommand,RunningMissionScript,scriptNull);
		OO_SET(_soc,SpecialOperationsCommand,RunningMission,OO_NULL);

		private _missionPosition = OO_GET(_mission,Strongpoint,Position);
		OO_SET(_soc,SpecialOperationsCommand,ReferencePosition,_missionPosition);

		private _blacklist = OO_GET(_soc,SpecialOperationsCommand,Blacklist);
		_blacklist pushBack [0, _missionPosition];

		private _commandState = OO_GET(_mission,Strongpoint,RunState);

		switch (_commandState) do
		{
			case "completed-error":
			{
				[["It looks like we received some bad intel", "Mission aborted", "Stand by", ""], ["screen-brief"]] call SPM_Mission_Message;
				[["Mission aborted due to error"], ["log"]] call SPM_Mission_Message;
				_missionNumber = _missionNumber - 1;
			};

			case "completed-failure":
			{
				_missionNumber = count _missionSequence;
			};

			case "completed-success":
			{
			};

			case "command-terminated":
			{
				[["Mission aborted by command", ""], ["screen-brief", "log"]] call SPM_Mission_Message;
			};
		};

		if (_missionNumber == count _missionSequence) then
		{
			if (_commandState == "completed-success") then
			{
				[["Mission sequence completed successfully", "Well done", ""], ["screen-brief", "log"]] call SPM_Mission_Message;
			};
			[["Mission sequence ends", ""], ["screen-brief", "log"]] call SPM_Mission_Message;
		}
		else
		{
			[["Mission sequence continues", "Stand by", ""], ["screen-brief"]] call SPM_Mission_Message;
		};
		
#ifdef TEST
		sleep 10;
#else
		sleep 120;
#endif

		call OO_DELETE(_mission);
	};

	OO_SET(_soc,SpecialOperationsCommand,MissionSequence,[]);
	OO_SET(_soc,SpecialOperationsCommand,CommandState,"ready");
};

OO_TRACE_DECL(SPM_SOC_RequestMission) =
{
	params ["_soc", "_player"];

	if (isNull _player) exitWith {};

	if (not ([_player] call SPM_Mission_IsSpecOpsMember)) exitWith
	{
		[[ "This device is restricted for use by the special operations team", "BLACK IN", 5]] remoteExec ["titleText", _player];
	};

	private _cs = OO_GET(_soc,SpecialOperationsCommand,CriticalSection);
	_cs call JB_fnc_criticalSectionEnter;

		private _commandState = OO_GET(_soc,SpecialOperationsCommand,CommandState);

		if (_commandState == "requested") exitWith
		{
			_cs call JB_fnc_criticalSectionLeave;
			[["Copy", "In work", "Wait one", ""], ["screen-brief"], _player] call SPM_Mission_Message;
		};

		if (_commandState == "running") exitWith
		{
			_cs call JB_fnc_criticalSectionLeave;

			if (OO_ISNULL(OO_GET(_soc,SpecialOperationsCommand,RunningMission))) then
			{
				[["Copy", "Reviewing results of last mission", ""], ["screen-brief"], _player] call SPM_Mission_Message;
			}
			else
			{
				[["Copy", "Mission sequence is underway", "Review special operations message log", ""], ["screen-brief"], _player] call SPM_Mission_Message;
			}
		};

		OO_SET(_soc,SpecialOperationsCommand,CommandState,"requested");

	_cs call JB_fnc_criticalSectionLeave;

	[["Copy", "Mission request acknowledged", "Wait one", ""], ["screen-brief"], _player] call SPM_Mission_Message;

	// Create mission sequence

	private _missionSequence = [];

	// Initial list of blacklisted locations
	private _blacklist = [] call SERVER_SpecialOperationsBlacklist;
	OO_SET(_soc,SpecialOperationsCommand,Blacklist,_blacklist);

	// Where to start the sequence
	private _referencePosition = [0, 0, 0];
	while { surfaceIsWater _referencePosition } do
	{
		_referencePosition = [random WorldSize, random WorldSize, 0];
	};
	OO_SET(_soc,SpecialOperationsCommand,ReferencePosition,_referencePosition);

	// Random mission order utilizing one of each mission type - save one
	private _missionTypes = +SPM_SOC_MissionTypes;
	private _numberMissions = (5 + round random 1) min (count _missionTypes);
	while { count _missionSequence < _numberMissions } do
	{
		private _mission = _missionTypes deleteAt floor random count _missionTypes;
		_missionSequence pushBack _mission;
	};

	OO_SET(_soc,SpecialOperationsCommand,MissionSequence,_missionSequence);

	// Run mission sequence

	[_soc] spawn SPM_SOC_RunMissionSequence;
};

SPM_SOC_Create =
{
	params ["_soc"];

	private _cs = call JB_fnc_criticalSectionCreate;
	OO_SET(_soc,SpecialOperationsCommand,CriticalSection,_cs);
};

OO_BEGIN_CLASS(SpecialOperationsCommand);
	OO_OVERRIDE_METHOD(SpecialOperationsCommand,Root,Create,SPM_SOC_Create);
	OO_DEFINE_METHOD(SpecialOperationsCommand,RequestMission,SPM_SOC_RequestMission);
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,CriticalSection,"ARRAY","[]");
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,ReferencePosition,"ARRAY","[]"); // Position of the prior mission in the chain
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,Blacklist,"ARRAY","[]");
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,CommandState,"STRING","inactive"); // inactive, requested, running
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,MissionSequence,"ARRAY",[]);
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,RunningMission,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,RunningMissionScript,"SCRIPT",scriptNull);
OO_END_CLASS(SpecialOperationsCommand);