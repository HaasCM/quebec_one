/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//#define TEST
if (not isServer) exitWith {};

#include "strongpoint.h"

#define INFANTRY_WALKING_DISTANCE 300

#define UPDATE_INTERVAL 10

if (isNil "SPM_StrongpointDifficulty") then { SPM_StrongpointDifficulty = [] };
SPM_StrongpointDifficulty pushBack ["infantry", 5];

SPM_InfantryGarrison_RatingsWest =
[
	["B_Competitor_F", [2, 1]],
	["B_crew_F", [2, 1]],
	["B_ghillie_ard_F", [2, 1]],
	["B_Fighter_Pilot_F", [2, 1]],
	["B_helicrew_F", [2, 1]],
	["B_Helipilot_F", [2, 1]],
	["B_medic_F", [2, 1]],
	["B_recon_JTAC_F", [2, 1]],
	["B_recon_LAT_F", [2, 1]],
	["B_recon_M_F", [2, 1]],
	["B_recon_medic_F", [2, 1]],
	["B_Recon_Sharpshooter_F", [2, 1]],
	["B_recon_TL_F", [2, 1]],
	["B_sniper_F", [2, 1]],
	["B_soldier_AR_F", [2, 1]],
	["B_soldier_AT_F", [2, 1]],
	["B_soldier_exp_F", [2, 1]],
	["B_soldier_GL_F", [2, 1]],
	["B_soldier_M_F", [2, 1]],
	["B_soldier_repair_F", [2, 1]],
	["B_soldier_SL_F", [2, 1]],
	["B_soldier_UAV_F", [2, 1]],
	["B_spotter_F", [2, 1]],
	["B_support_Mort_F", [2, 1]]
];

SPM_InfantryGarrison_RatingsEast =
[
	["O_soldier_F", [1, 1]],
	["O_medic_F", [1, 1]],
	["O_soldier_A_F", [1, 1]],
	["O_soldier_AR_F", [1, 1]],
	["O_soldier_LAT_F", [1, 1]],
	["O_soldier_AT_F", [1, 1]],
	["O_soldier_GL_F", [1, 1]],
	["O_soldier_M_F", [1, 1]],
	["O_soldier_TL_F", [1, 1]],
	["O_soldier_SL_F", [1, 1]]
];

SPM_InfantryGarrison_CallupsEast =
[
	[(configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSquad"), [1, 8]]
];

SPM_InfantryGarrison_InitialCallupsEast =
[
	[(configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSquad"), [1, 8]],
	[(configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam"), [1, 4]],
	[(configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSentry"), [1, 2]]
];

SPM_InfantryGarrison_RatingsEastWater =
[
	["O_diver_TL_F", [1, 1]],
	["O_diver_exp_F", [1, 1]],
	["O_diver_F", [1, 1]]
];

SPM_InfantryGarrison_CallupsEastWater =
[
	[(configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "SpecOps" >> "OI_diverTeam"), [1, 4]]
];

SPM_InfantryGarrison_InitialCallupsEastWater =
[
	[(configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "SpecOps" >> "OI_diverTeam"), [1, 4]]
];

SPM_InfantryGarrison_RatingsCivilian = "toLower (configName _x) find 'c_man' == 0" configClasses (configFile >> "CfgVehicles");
SPM_InfantryGarrison_RatingsCivilian = SPM_InfantryGarrison_RatingsCivilian apply { [configName _x, [1, 1]] };

SPM_InfantryGarrison_RatingsSyndikat = "toLower (configName _x) find 'i_c_soldier_bandit_' == 0" configClasses (configFile >> "CfgVehicles");
SPM_InfantryGarrison_RatingsSyndikat = SPM_InfantryGarrison_RatingsSyndikat apply { [configName _x, [1, 1]] };

SPM_InfantryGarrison_CallupsSyndikat =
[
	[(configFile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "BanditCombatGroup"), [1, 8]]
];

SPM_InfantryGarrison_InitialCallupsSyndikat =
[
	[(configFile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "BanditCombatGroup"), [1, 8]],
	[(configFile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "BanditFireTeam"), [1, 4]]
];


OO_TRACE_DECL(SPM_InfantryGarrison_SpawnGroup) =
{
	params ["_category", "_side", "_descriptor", "_positionInformation"];

	private _group = if (typeName _positionInformation == typeName objNull)
		then { [_side, [[_positionInformation]] + _descriptor, call SPM_Util_RandomSpawnPosition, 0, true, ["cargo"]] call SPM_fnc_spawnGroup }
		else { [_side, _descriptor, _positionInformation select 0, _positionInformation select 1, false] call SPM_fnc_spawnGroup };

	[_category, _group] call OO_GET(_category,Category,InitializeObject);
	_group setFormation (selectRandom SPM_InfantryGarrison_Formations);

	private _forceUnits = OO_GET(_category,ForceCategory,ForceUnits);
	{
		_forceUnits pushBack ([_x, [_x]] call OO_CREATE(ForceUnit));
	} forEach units _group;

	private _force = 0;
	{
		_force = _force + OO_GET(_x,ForceRating,Rating);
	} forEach ([units _group, OO_GET(_category,ForceCategory,RatingsEast)] call SPM_Force_GetForceRatings);

	[_group, _force]
};

OO_TRACE_DECL(SPM_InfantryGarrison_GetOccupationBuilding) =
{
	params ["_category", "_side", "_count", "_position"];

	private _occupationLimit = OO_GET(_category,InfantryGarrisonCategory,OccupationLimit);

	private _buildings = OO_GET(_category,InfantryGarrisonCategory,Buildings);
	_buildings = [_buildings, _side] call SPM_fnc_occupyGetBuildings;

	// Keep only buildings that can accommodate the requested number of infantry without going over the garrison's per-building occupation limit
	_buildings = _buildings select { (_x select 1) - (_x select 2) >= _count && { (_x select 2) + _count <= _occupationLimit } };

	if (count _buildings == 0) exitWith { diag_log format ["SPM_InfantryGarrison_GetOccupationBuilding: no building has room for %1 soldiers while staying under the %2 occupation limit", _count, _occupationLimit]; { diag_log str _x; } forEach _buildings; objNull };

	_buildings = _buildings apply { [(_x select 0) distanceSqr _position, (_x select 0)] };
	_buildings sort false;

	// Random is designed to pick closer buildings much more often than farther ones
	_buildings select (floor random [0, count _buildings, (count _buildings) * 0.8]) select 1;
};

OO_TRACE_DECL(SPM_InfantryGarrison_OutdoorPositions) =
{
	params ["_area"];

	private _center = OO_GET(_area,StrongpointArea,Center);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _positions = [_center, _innerRadius, _outerRadius, (_outerRadius -_innerRadius) * 0.2] call SPM_Util_SampleAreaGrid;
	[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, 4.0, ["BUILDING", "ROCK"]] call SPM_Util_ExcludeSamplesByProximity;
	[_positions, 10.0, ["BUILDING", "ROCK"], _outdoorPositions] call SPM_Util_ExcludeSamplesByProximity;

	_outdoorPositions = _outdoorPositions apply { [_x distanceSqr _center, _x] };
	_outdoorPositions sort true;

	_outdoorPositions
};

OO_TRACE_DECL(SPM_InfantryGarrison_CreateInitialForce) =
{
	params ["_category", "_initialReserves"];

	private _difficulty = [SPM_StrongpointDifficulty, "infantry"] call BIS_fnc_getFromPairs;
	_initialReserves = [_initialReserves, _difficulty] call SPM_Force_GetAdjustedForceValue;

	private _eastSide = OO_GET(_category,ForceCategory,SideEast);
	private _eastCallups = OO_GET(_category,InfantryGarrisonCategory,InitialCallupsEast);

	private _area = OO_GET(_category,ForceCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Center);

	private _houseOutdoors = OO_GET(_category,InfantryGarrisonCategory,HouseOutdoors);
	private _outdoorPositions = [];

	private _units = [];
	private _remainingReserves = _initialReserves;

	while { _remainingReserves > 0 } do
	{
		private _callup = selectRandom _eastCallups;
		private _building = [_category, _eastSide, _callup select 1 select 1, _center] call SPM_InfantryGarrison_GetOccupationBuilding;

		if (isNull _building && not _houseOutdoors) exitWith { diag_log format ["SPM_InfantryGarrison_CreateInitialForce: unable to house initial force (%1 remaining)", _remainingReserves] };

		private _descriptor = [];
		private _type = _callup select 0;
		switch (typeName _type) do
		{
			case "CONFIG": { _descriptor = ([_type] call SPM_fnc_groupFromConfig) select 1 };
			case "STRING": { _descriptor = ([[_type]] call SPM_fnc_groupFromClasses) select 1 };
			case "ARRAY": { _descriptor = ([_type] call SPM_fnc_groupFromClasses) select 1 };
			default { diag_log format ["SPM_InfantryGarrison_InitialGarrison: unhandled callup '%1'", _type] };
		};

		private _spawn = [_category, _eastSide, _descriptor, [call SPM_Util_RandomSpawnPosition, 0]] call SPM_InfantryGarrison_SpawnGroup;
		_remainingReserves = _remainingReserves - (_spawn select 1);
		private _group = _spawn select 0;

		_units append units _group;

		if (not isNull _building) then
		{
			[_group, _building, "instant"] call SPM_fnc_occupyEnter;
			deleteGroup _group;
		}
		else
		{
			if (count _outdoorPositions == 0) then { _outdoorPositions = [_area] call SPM_InfantryGarrison_OutdoorPositions; };

			if (count _outdoorPositions == 0) then { _outdoorPositions = [[0, _center]] };

			private _position = (_outdoorPositions deleteAt 0) select 1;
			{
				_x setPos _position;
			} forEach units _group;
		};
	};

	OO_GET(_category,InfantryGarrisonCategory,HousedUnits) append _units;
	OO_SET(_category,InfantryGarrisonCategory,_InitialForceCreated,true);
};

OO_TRACE_DECL(SPM_InfantryGarrison_GarrisonGroups) =
{
	params ["_category", "_groups"];

	private _outdoorPositions = [];

	{
		private _building = [_category, side leader _x, count units _x, getPos leader _x] call SPM_InfantryGarrison_GetOccupationBuilding;

		if (not isNull _building) then
		{
			OO_GET(_category,InfantryGarrisonCategory,HousedUnits) append units _x;

			[_x, _building, "simultaneous"] call SPM_fnc_occupyEnter;
		}
		else
		{
			if (count _outdoorPositions == 0) then { _outdoorPositions = [OO_GET(_category,ForceCategory,Area)] call SPM_InfantryGarrison_OutdoorPositions; };

			if (count _outdoorPositions == 0) then { private _area = OO_GET(_category,ForceCategory,Area); _outdoorPositions = [[0, OO_GET(_area,StrongpointArea,Center)]] };

			private _position = (_outdoorPositions deleteAt 0) select 1;

			private _waypoint = _x addWaypoint [_position, 0];
			_waypoint setWaypointType "move";
			_waypoint setWaypointSpeed "full";
			_waypoint setWaypointFormation "file";
			_waypoint setWaypointBehaviour "safe";
		};
	} forEach _groups;
};

SPM_InfantryGarrison_Formations = ["column", "stag column", "wedge", "ech left", "ech right", "vee", "line", "file", "diamond"];

OO_TRACE_DECL(SPM_InfantryGarrison_TransportOnLoad) =
{
	params ["_request"];

	private _clientData = OO_GET(_request,TransportRequest,ClientData);
	private _category = OO_INSTANCE(_clientData select 0);
	private _type = _clientData select 1;

	private _reserves = OO_GET(_category,ForceCategory,Reserves);
	if (_reserves <= 0) exitWith { false };

	private _side = OO_GET(_category,ForceCategory,SideEast);

	private _descriptor = [];
	switch (typeName _type) do
	{
		case "CONFIG": { _descriptor = ([_type] call SPM_fnc_groupFromConfig) select 1 };
		case "STRING": { _descriptor = ([[_type]] call SPM_fnc_groupFromClasses) select 1 };
		case "ARRAY": { _descriptor = ([_type] call SPM_fnc_groupFromClasses) select 1 };
		default { diag_log format ["SPM_InfantryGarrison_TransportOnLoad: unhandled callup '%1'", _type] };
	};

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _transportVehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	private _cargoSeatCount = count fullCrew [_transportVehicle, "cargo", true];
	if (_cargoSeatCount < count _descriptor) then
	{
		_descriptor = _descriptor select [0, _cargoSeatCount];
	};

	private _spawn = [];
	private _infantryGroup = grpNull;

	if (not (_transportVehicle isKindOf "Air")) then
	{
		_spawn = [_category, _side, _descriptor, _transportVehicle] call SPM_InfantryGarrison_SpawnGroup;
		_infantryGroup = _spawn select 0;
	}
	else
	{
		private _position = call SPM_Util_RandomSpawnPosition;
		_position set [2, 5000]; // About 90 seconds of freefall time before being yanked over to the aircraft to simulate a paradrop
		_spawn = [_category, _side, _descriptor, [_position, 0]] call SPM_InfantryGarrison_SpawnGroup;
		_infantryGroup = _spawn select 0;

		private _killedHandler = _transportVehicle addEventHandler ["Killed",
			{
				params ["_vehicle"];

				{ deleteVehicle _x } forEach units ((_vehicle getVariable "SPM_InfantryGarrison_Unload") select 0);
			}];

		_transportVehicle setVariable ["SPM_InfantryGarrison_Unload", [_infantryGroup, _killedHandler]];
	};

	_infantryGroup setSpeedMode "full";

	private _reserves = OO_GET(_category,ForceCategory,Reserves);
	_reserves = _reserves - (_spawn select 1);
	OO_SET(_category,ForceCategory,Reserves,_reserves);

	true
};

OO_TRACE_DECL(SPM_InfantryGarrison_Dismount) =
{
	params ["_units"];

	if (count _units == 0) exitWith {};

	private _vehicle = vehicle (_units select 0);
	if (not canMove _vehicle || random 0.5 < damage _vehicle) then
	{
		_vehicle fire "SmokeLauncher";
	};

	{
		unassignVehicle _x;
		[_x] allowGetIn false;
		[_x] orderGetIn false;
		sleep 1;
	} forEach _units;
};

OO_TRACE_DECL(SPM_InfantryGarrison_TransportOnUpdate) =
{
	params ["_request"];

	private _state = OO_GET(_request,TransportRequest,State);

	if (_state != "to-destination") exitWith {};

	private _transportForceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _transportDriver = driver OO_GET(_transportForceUnit,ForceUnit,Vehicle);
	private _transportPosition = getPos _transportDriver;

	private _operation = OO_GETREF(_request,TransportRequest,Operation);
	private _area = OO_GET(_operation,TransportOperation,Area);
	private _areaRadius = OO_GET(_area,StrongpointArea,OuterRadius);
	private _areaRadiusSqr = _areaRadius ^ 2;

	// If inside the area we want to get to
	if (OO_GET(_area,StrongpointArea,Center) distanceSqr _transportPosition < _areaRadiusSqr) exitWith
	{
		// Tell the transport to unload us in cover
		if (not ([50, 100] call OO_METHOD(_request,TransportRequestGround,CommandMoveToCover))) then
		{
			[] call OO_METHOD(_request,TransportRequestGround,CommandStop);
		};
	};

	// If within walking distance of the area
	if (OO_GET(_area,StrongpointArea,Center) distance _transportPosition < _areaRadius + INFANTRY_WALKING_DISTANCE) then
	{
		private _targets = _transportDriver targetsQuery [objNull, sideUnknown, "", [], 0];
		_targets = _targets select { alive (_x select 1) && vehicle (_x select 1) == (_x select 1) && (_x select 4) distance _transportPosition < 50 };

		private _eastSide = OO_GET(_category,ForceCategory,SideEast);
		private _eastCount = { _x select 2 == _eastSide } count _targets;

		private _westSide = OO_GET(_category,ForceCategory,SideWest);
		private _westCount = { _x select 2 == _westSide } count _targets;

		// If encountering noteworthy resistance
		if (_westCount >= 4 && _westCount * 2 > _eastCount) then
		{
			// Tell the transport to unload us in cover
			if (not ([50, 100] call OO_METHOD(_request,TransportRequestGround,CommandMoveToCover))) then
			{
				[] call OO_METHOD(_request,TransportRequestGround,CommandStop);
			};
		};
	};
};

OO_TRACE_DECL(SPM_InfantryGarrison_TransportOnArriveGround) =
{
	params ["_request"];

	//TODO: This will dismount the troops if the transport stops for any reason.  Might want to be more discriminating

	// We don't want to hear anything more from the transport guys
	OO_SET(_request,TransportRequest,OnUpdate,{});
	OO_SET(_request,TransportRequest,OnArrive,{});
	OO_SET(_request,TransportRequest,OnSalvage,{});

	private _clientData = OO_GET(_request,TransportRequest,ClientData);
	private _category = OO_INSTANCE(_clientData select 0);

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);

	private _groups = [];
	{
		_groups pushBackUnique group _x;
	} forEach assignedCargo OO_GET(_forceUnit,ForceUnit,Vehicle);

	private _units = [];
	{
		_units append units _x;
	} forEach _groups;

	[_category, _groups] call SPM_InfantryGarrison_GarrisonGroups;

	[_request, _units] spawn
	{
		params ["_request", "_units"];

		[_units] call SPM_InfantryGarrison_Dismount;
		[] call OO_METHOD(_request,TransportRequestGround,CommandRetire);
	};
};

OO_TRACE_DECL(SPM_InfantryGarrison_TransportOnArriveAir) =
{
	params ["_request"];

	// We don't want to hear anything more from the transport guys
	OO_SET(_request,TransportRequest,OnUpdate,{});
	OO_SET(_request,TransportRequest,OnArrive,{});
	OO_SET(_request,TransportRequest,OnSalvage,{});

	private _clientData = OO_GET(_request,TransportRequest,ClientData);
	private _category = OO_INSTANCE(_clientData select 0);

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);

	[_category, OO_GET(_forceUnit,ForceUnit,Vehicle)] spawn
	{
		params ["_category", "_aircraft"];

		private _unloadData = _aircraft getVariable "SPM_InfantryGarrison_Unload";
		private _infantryGroup = _unloadData select 0;
		private _killedHandler = _unloadData select 1;

		_aircraft removeEventHandler ["Killed", _killedHandler];

		private _aircraftExits = [_aircraft, ["cargo"], false] call JB_fnc_getInPoints;
		_aircraftExits = _aircraftExits select 0 select 1;
		_aircraftExits = _aircraftExits apply { _x select 1 };

		private _rearmostExit = [0, 10, 0];
		{
			if (_x select 1 < _rearmostExit select 1) then { _rearmostExit = _x };
		} forEach _aircraftExits;

		{
			if (not alive _aircraft) then
			{
				deleteVehicle _x;
			}
			else
			{
				private _position = _aircraft modelToWorldWorld _rearmostExit;
				_x setPosASL _position;

				private _velocity = velocity _aircraft;
				_x setVelocity _velocity;

				[_x, true] call JB_fnc_halo;

				sleep 0.5;
			};
		} forEach units _infantryGroup;

		// Wait until they're on the ground.  BUG: Waypoints are being deleted if we try this before then
		waitUntil { ({ alive _x } count units _infantryGroup) == ({ vehicle _x == _x } count units _infantryGroup) };
		[_category, [_infantryGroup]] call SPM_InfantryGarrison_GarrisonGroups;
	};
};

OO_TRACE_DECL(SPM_InfantryGarrison_TransportOnSalvage) =
{
	params ["_request"];

	private _clientData = OO_GET(_request,TransportRequest,ClientData);
	private _category = OO_INSTANCE(_clientData select 0);

	private _transportForceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _groups = [];
	{
		_groups pushBackUnique group _x;
	} forEach assignedCargo OO_GET(_transportForceUnit,ForceUnit,Vehicle);

	{
		{
			[_category, _x] call SPM_Force_SalvageForceUnit;
		} forEach units _x;
		deleteGroup _x;
	} forEach _groups;
};

OO_TRACE_DECL(SPM_InfantryGarrison_GetOperationUnloadPosition) =
{
	params ["_side", "_center", "_innerRadius", "_outerRadius"];

	private _outerRadiusSqr = _outerRadius ^ 2;
	private _westUnits = allUnits select { side _x == _side && { getPos _x distanceSqr _center < _outerRadiusSqr } };

	private _westClusters = [_westUnits, 5] call JB_fnc_unitClusters;

	private _westAreas = _westClusters apply { [_x select 0, 0, _x select 3] };

	private _positions = [_center, _innerRadius, _outerRadius, 10] call SPM_Util_SampleAreaGrid;
	[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, 10.0, ["WALL", "BUILDING", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;
	[_positions, _westAreas] call SPM_Util_ExcludeSamplesByAreas;

	if (count _positions == 0) exitWith { [] };

	selectRandom _positions
};

OO_TRACE_DECL(SPM_InfantryGarrison_FindOperationUnloadPosition) =
{
	params ["_area", "_sideWest"];

	private _unloadPosition = [];
	private _center = OO_GET(_area,StrongpointArea,Center);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);
	while { count _unloadPosition == 0 && _outerRadius < 500 } do
	{
		_unloadPosition = [_sideWest, _center, _innerRadius, _outerRadius] call SPM_InfantryGarrison_GetOperationUnloadPosition;
		_innerRadius = _outerRadius;
		_outerRadius = _outerRadius + 50;
	};
	if (count _unloadPosition == 0) then { _unloadPosition = OO_GET(_area,StrongpointArea,Center) };

	_unloadPosition;
};

OO_TRACE_DECL(SPM_InfantryGarrison_Balance) =
{
	params ["_category"];

	private _difficulty = [SPM_StrongpointDifficulty, "infantry"] call BIS_fnc_getFromPairs;

	// Remove dead or deleted infantry units from unit list
	[OO_GET(_category,ForceCategory,ForceUnits), { private _unit = OO_GET(_this select 2,ForceUnit,Vehicle); isNull _unit || { not alive _unit } }] call SPM_Util_DeleteArrayElements;

	// If our reserves are to the point where we cannot form any more units, discard the remaining reserves because we never recall units
	private _cheapestUnit = 1e10;
	{
		private _unitCost = (_x select 1 select 0) * (_x select 1 select 1);
		if (_unitCost < _cheapestUnit) then { _cheapestUnit = _unitCost };
	} forEach OO_GET(_category,ForceCategory,CallupsEast);

	if (_cheapestUnit > OO_GET(_category,ForceCategory,Reserves)) then { OO_SET(_category,ForceCategory,Reserves,0) };

	// Get the force levels of east and west
	private _westForce = [200] call OO_METHOD(_category,ForceCategory,GetForceLevelsWest);
	private _eastForce = [-1] call OO_METHOD(_category,ForceCategory,GetForceLevelsEast);

	// If necessary, pad the west's force so that the east always responds with a certain minimum force

	private _minimumWestForce = OO_GET(_category,InfantryGarrisonCategory,MinimumWestForce);

	private _westRating = 0;
	{ _westRating = _westRating + OO_GET(_x,ForceRating,Rating); } forEach _westForce;

	private _minimumWestRating = 0;
	{ _minimumWestRating = _minimumWestRating + OO_GET(_x,ForceRating,Rating); } forEach _minimumWestForce;

	{
		if (_westRating >= _minimumWestRating) exitWith {};

		_westForce pushBack _x;
		_westRating = _westRating + OO_GET(_x,ForceRating,Rating);
	} forEach _minimumWestForce;

	// Find out what we need to do to balance things out

	private _changes = [_westForce, _eastForce, OO_GET(_category,ForceCategory,CallupsEast), OO_GET(_category,ForceCategory,Reserves), _difficulty] call SPM_Force_Rebalance;

	private _callups = CHANGES(_changes,callup);
	private _reserves = CHANGES(_changes,reserves);

	if (count _callups > 0) then
	{
		private _transport = OO_GET(_category,InfantryGarrisonCategory,Transport);
		if (OO_ISNULL(_transport)) then
		{
			//TODO: Walk in if no transport
		}
		else
		{
			private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
			private _area = OO_GET(_category,ForceCategory,Area);
			private _center = OO_GET(_area,StrongpointArea,Center);

			// Where to spawn
			private _transportType = "";
			private _spawnpoint = [];

			if (random 1 < 0.5) then // 50% chance of air drop regardless of whether they can get in by ground
			{
				_transportType = "air";
			}
			else // Otherwise, try ground and if that's not possible, again go by air
			{
				_spawnpoint = [_strongpoint, _center, OO_GET(_area,StrongpointArea,OuterRadius) max 100] call SPM_Util_GetRoadSpawnpoint;
				_transportType = if (count _spawnpoint > 0) then { "ground" } else { "air" };
			};

			private _beachPosition = [];

			if (_transportType == "air") then
			{
				_spawnpoint = [_strongpoint, 500, 100] call SPM_Util_GetAirSpawnpoint;

				if (surfaceIsWater (_spawnpoint select 0) && random 1 < 0.75) then // 75% change of sea landing
				{
					_beachPosition = [_spawnpoint select 0, _center] call SPM_Util_KeepOutOfWater;
					_beachPosition set [2, 0];
					if (_beachPosition distance _center < INFANTRY_WALKING_DISTANCE) then
					{
						_spawnpoint select 0 set [2, 0];
						_transportType = "boat";
					};
				};
			};

			// The location of an area where multiple vehicles can unload
			private _operationUnloadPosition = [_area, OO_GET(_category,ForceCategory,SideWest)] call SPM_InfantryGarrison_FindOperationUnloadPosition;

			// Create transport operation
			private _operation = [_area, _spawnpoint] call OO_CREATE(TransportOperation);

			{
				private _request = OO_NULL;

				switch (_transportType) do
				{
					case "ground":
					{
						OO_SET(_operation,TransportOperation,VehicleCallups,SPM_Transport_CallupsEastGround);

						private _destination = [_operationUnloadPosition, count _callups * 10] call SPM_Util_OpenPositionForVehicle;
						_request = [_x select 1 select 1, _destination] call OO_CREATE(TransportRequestGround);
						OO_SET(_request,TransportRequest,OnArrive,SPM_InfantryGarrison_TransportOnArriveGround);
					};

					case "boat":
					{
						OO_SET(_operation,TransportOperation,VehicleCallups,SPM_Transport_CallupsEastBoat);

						private _destination = [_beachPosition, 50] call SPM_Util_OpenPositionForBoat;
						_request = [_x select 1 select 1, _destination] call OO_CREATE(TransportRequestGround);
						OO_SET(_request,TransportRequest,OnArrive,SPM_InfantryGarrison_TransportOnArriveGround);
					};

					case "air":
					{
						OO_SET(_operation,TransportOperation,VehicleCallups,SPM_Transport_CallupsEastAir);

						_request = [_x select 1 select 1, _operationUnloadPosition] call OO_CREATE(TransportRequestAir);
						OO_SET(_request,TransportRequest,OnArrive,SPM_InfantryGarrison_TransportOnArriveAir);
					};
				};

				if (not OO_ISNULL(_request)) then
				{
					private _clientData = [OO_REFERENCE(_category), _x select 0]; // infantry unit type to spawn

					OO_SET(_request,TransportRequest,OnLoad,SPM_InfantryGarrison_TransportOnLoad);
					OO_SET(_request,TransportRequest,OnUpdate,SPM_InfantryGarrison_TransportOnUpdate);
					OO_SET(_request,TransportRequest,OnSalvage,SPM_InfantryGarrison_TransportOnSalvage);
					OO_SET(_request,TransportRequest,ClientData,_clientData);

					[_request] call OO_METHOD(_operation,TransportOperation,AddRequest);
				};
			} forEach _callups;

			[_operation] call OO_METHOD(_transport,TransportCategory,AddOperation);
		};
	};
};

OO_TRACE_DECL(SPM_InfantryGarrison_LeaveBuilding) =
{
	params ["_category", "_soldiers"];

	{
		[_x] call SPM_UnchainSoldier;
		[_x] call SPM_FreeBuildingPosition;
	} forEach _soldiers;

	private _soldier = _soldiers select 0;

	private _group = createGroup side _soldier;
	_group setBehaviour "safe";
	_group setCombatMode "green";
	_group setSpeedMode "limited";
	_soldiers join _group;

	_group
};

OO_TRACE_DECL(SPM_InfantryGarrison_MoveGarrisonedSoldiers) =
{
	params ["_category", "_soldiers"];

	private _building = [_category, side (_soldiers select 0), count _soldiers, getPos (_soldiers select 0)] call SPM_InfantryGarrison_GetOccupationBuilding;

	if (not isNull _building) then
	{
		private _group = [_category, _soldiers] call SPM_InfantryGarrison_LeaveBuilding;

		[_group, _building, "simultaneous"] call SPM_fnc_occupyEnter;
	};
};

OO_TRACE_DECL(SPM_InfantryGarrison_BeginTemporaryDuty) =
{
	params ["_category", "_number"];

	private _housedUnits = OO_GET(_category,InfantryGarrisonCategory,HousedUnits);
	if (count _housedUnits < _number) exitWith { grpNull };

	private _dutyUnits = [];
	private _housedGroups = [];
	{
		if (not (group _x in _housedGroups)) then { _housedGroups pushBack group _x; _dutyUnits append units group _x };
		if (count _dutyUnits >= _number) exitWith {};
	} forEach _housedUnits;

	if (count _dutyUnits < _number) exitWith { grpNull };

	_dutyUnits = _dutyUnits select [0, _number];

	_housedUnits = _housedUnits - _dutyUnits;
	OO_SET(_category,InfantryGarrisonCategory,HousedUnits,_housedUnits);

#ifdef OO_TRACE
	diag_log format ["SPM_InfantryGarrison_BeginTemporaryDuty: count _dutyUnits: %1", count _dutyUnits];
#endif
	[_category, _dutyUnits] call SPM_InfantryGarrison_LeaveBuilding
};

OO_TRACE_DECL(SPM_InfantryGarrison_EndTemporaryDuty) =
{
	params ["_category", "_dutyGroup"];

	[_category, [_dutyGroup]] call SPM_InfantryGarrison_GarrisonGroups;
};

OO_TRACE_DECL(SPM_InfantryGarrison_Update) =
{
	params ["_category"];

	private _updateTime = diag_tickTime + UPDATE_INTERVAL;
	OO_SET(_category,Category,UpdateTime,_updateTime);

	if (not OO_GET(_category,InfantryGarrisonCategory,_InitialForceCreated)) then
	{
		[_category, OO_GET(_category,InfantryGarrisonCategory,InitialReserves)] call SPM_InfantryGarrison_CreateInitialForce;
	};

	private _balanceTime = OO_GET(_category,InfantryGarrisonCategory,BalanceTime);
	if (diag_tickTime > _balanceTime) then
	{
		[_category] call SPM_InfantryGarrison_Balance;

#ifdef TEST
		_balanceTime = diag_tickTime + 30;
#else
		_balanceTime = diag_tickTime + (30 + random 150);
#endif
		OO_SET(_category,InfantryGarrisonCategory,BalanceTime,_balanceTime);
	};

	private _forceUnits = OO_GET(_category,ForceCategory,ForceUnits);
	for "_i" from (count _forceUnits - 1) to 0 step -1 do
	{
		private _forceUnit = _forceUnits select _i;
		if (not alive OO_GET(_forceUnit,ForceUnit,Vehicle)) then { _forceUnits deleteAt _i };
	};

	private _housedUnits = OO_GET(_category,InfantryGarrisonCategory,HousedUnits);
	for "_i" from (count _housedUnits - 1) to 0 step -1 do
	{
		if (not alive (_housedUnits select _i)) then { _housedUnits deleteAt _i };
	};

	private _relocateProbability = OO_GET(_category,InfantryGarrisonCategory,RelocateProbability);
	if (typeName _relocateProbability == "CODE") then
	{
		_relocateProbability = [_category] call _relocateProbability;
	};

	private _relocations = _relocateProbability * UPDATE_INTERVAL * count _housedUnits;
	private _totalRelocations = floor _relocations;
	_relocations = _relocations - _totalRelocations;
	if (random 1 < _relocations) then { _totalRelocations = _totalRelocations + 1 };

	for "_i" from 1 to _totalRelocations do
	{
		private _soldier = selectRandom _housedUnits;
		if (behaviour _soldier == "SAFE") then
		{
			private _waypoints = waypoints _soldier;
			if (count _waypoints == 1 && { (waypointPosition (_waypoints select 0)) select 0 == 0 }) then
			{
				private _movingSoldiers = [_soldier];

				private _groupUnits = (units group _soldier) - [_soldier];
				if (count _groupUnits > 0) then
				{
					_movingSoldiers pushBack (selectRandom _groupUnits);
				};
			
				[_category, _movingSoldiers] call SPM_InfantryGarrison_MoveGarrisonedSoldiers;
			};
		};
	};

	private _traceObject = OO_GET(_category,InfantryGarrisonCategory,_TraceObject);
	[_traceObject, "CIG", format ["Rebalance in: %1, Reserves: %2, Force: %3, Housed: %4", round (_balanceTime - diag_tickTime), OO_GET(_category,ForceCategory,Reserves), count _forceUnits, count _housedUnits]] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_InfantryGarrison_Create) =
{
	params ["_category", "_area"];

	OO_SET(_category,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsEast);
	OO_SET(_category,ForceCategory,Area,_area);

	private _center = OO_GET(_area,StrongpointArea,Center);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _traceObject = "Land_FirePlace_F" createVehicle (_center vectorAdd ([0,1,0] vectorMultiply _outerRadius));
	_traceObject hideObjectGlobal true;
	OO_SET(_category,InfantryGarrisonCategory,_TraceObject,_traceObject);

	private _data = [];
	private _chain = [[SPM_Chain_FixedPosition, [_center]], [SPM_Chain_PositionToBuildings, [_innerRadius, _outerRadius]], [SPM_Chain_BuildingsToEnterableBuildings, []], [SPM_Chain_EnterableBuildingsToOccupancyBuildings, [4]]];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (_complete) then
	{
		private _buildings = [_data, "occupancy-buildings"] call SPM_GetDataValue;
		OO_SET(_category,InfantryGarrisonCategory,Buildings,_buildings);
	};
};

OO_TRACE_DECL(SPM_InfantryGarrison_Delete) =
{
	params ["_category"];

	private _traceObject = OO_GET(_category,InfantryGarrisonCategory,_TraceObject);
	deleteVehicle _traceObject;

	[] call OO_METHOD_PARENT(_category,Root,Delete,ForceCategory);
};

OO_BEGIN_SUBCLASS(InfantryGarrisonCategory,ForceCategory);
	OO_OVERRIDE_METHOD(InfantryGarrisonCategory,Root,Create,SPM_InfantryGarrison_Create);
	OO_OVERRIDE_METHOD(InfantryGarrisonCategory,Root,Delete,SPM_InfantryGarrison_Delete);
	OO_OVERRIDE_METHOD(InfantryGarrisonCategory,Category,Update,SPM_InfantryGarrison_Update);
	OO_DEFINE_METHOD(InfantryGarrisonCategory,BeginTemporaryDuty,SPM_InfantryGarrison_BeginTemporaryDuty);
	OO_DEFINE_METHOD(InfantryGarrisonCategory,EndTemporaryDuty,SPM_InfantryGarrison_EndTemporaryDuty);
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,InitialReserves,"SCALAR",0);
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,InitialCallupsEast,"ARRAY",SPM_InfantryGarrison_InitialCallupsEast);
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,_InitialForceCreated,"BOOL",false);
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,MinimumWestForce,"ARRAY",[]); // Assume that this enemy force must always be opposed
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,OccupationLimit,"SCALAR",1e30); // Per building, the maximum number of troops to house
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,RelocateProbability,"SCALAR",0.001); // Per second, the odds that a garrison soldier will relocate (also CODE)
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,HouseOutdoors,"BOOL",true);
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,Transport,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,BalanceTime,"SCALAR",0);
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,Buildings,"ARRAY",[]);
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,HousedUnits,"ARRAY",[]);
	OO_DEFINE_PROPERTY(InfantryGarrisonCategory,_TraceObject,"OBJECT",objNull);
OO_END_SUBCLASS(InfantryGarrisonCategory);