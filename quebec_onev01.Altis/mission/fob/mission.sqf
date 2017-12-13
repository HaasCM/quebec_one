ambushNull = [[], []];

// The distance from the FOB marker that the mission truck needs to be before the mission is considered complete
private _completeDistanceFromDestination = 20;

// The distance that the truck must be from the prior ambush point before the ambushers give up and are deleted
private _ambushDistanceEscape = 800;

// The distance from the mission truck's start point that the truck must be before an ambush can take place
private _ambushDistanceFromOrigin = 1500;

// The distance from the destination that the truck must be if a new ambush can be created
private _ambushDistanceFromDestination = 500;

private _ambushUnitTypes =
[
	[30, "OIA_InfSquad"],
	[50, "OIA_InfTeam"],
	[10, "OIA_InfAssault"]
];

FOB_Hint =
{
	private _missionType = param [0, "", [""]];
	private _message = param [1, "", [""]];

	format ["<t align='center'><t size='2.2'>FOB Mission</t><br/><t size='1.5' color='#00B2EE'>%1</t><br/>____________________<br/>%2</t>", _missionType, _message];
};

FOB_DeleteAmbush =
{
	private _ambush = _this select 0;

	{
		{
			deleteVehicle _x;
		} forEach units _x;
		deleteGroup _x;
	} forEach (_ambush select 0);

	{
		deleteVehicle _x;
	} forEach (_ambush select 1);
};

FOB_CreateAmbushUnit =
{
	private _position = _this select 0;

	private _ambushUnitType = [_ambushUnitTypes] call JB_fnc_randomItemFromWeightedArray;
	private _ambushUnit = [_position, EAST, (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> _ambushUnitType)] call BIS_fnc_spawnGroup;
	[units _ambushUnit] call QS_fnc_setSkill1;
	[_ambushUnit] call SERVER_RegisterDeaths;
	[_ambushUnit] call JB_fnc_downgradeATEquipment;
	[units _ambushUnit] call SERVER_CurateEditableObjects;

	_ambushUnit
};

FOB_CreateWildernessAmbush =
{
	private _ambushUnits = [];

	private _numberAmbushers = 0;
	private _maximumAmbushers = 10 + random 10;

	while { _numberAmbushers < _maximumAmbushers } do
	{
		private _unitPosition = [FOB_MissionTruck, 250 + (random 250), getDir FOB_MissionTruck + ((random 30) - 15)] call BIS_fnc_relPos;

		_ambushUnit = [_unitPosition] call FOB_CreateAmbushUnit;
		private _waypoint = _ambushUnit addWaypoint [FOB_MissionTruck, 0];
		_waypoint waypointAttachVehicle FOB_MissionTruck;
		_waypoint setWaypointType "destroy";

		_numberAmbushers = _numberAmbushers + (count units _ambushUnit);

		_ambushUnits pushBack _ambushUnit;
	};

	[_ambushUnits, []]
};

FOB_SpawnMineField =
{
	private _fieldPosition = _this select 0;
	private _fieldWidth = _this select 1;
	private _fieldDepth = _this select 2;
	private _fieldDirection = _this select 3;

	private _mineField = [];
	if (count (_fieldPosition nearObjects ["House", _fieldWidth]) < 3) then
	{
		private _natural = nearestTerrainObjects [_fieldPosition, ["HIDE"], _fieldWidth];
		private _density = (0.05 + random 0.05) - (count _natural * 0.01);
		if (_density > 0.0) then
		{
			_mineField = [_fieldPosition, _fieldWidth, _fieldDepth, _fieldDirection, (_fieldWidth * _fieldDepth) * _density, ["ATMine_Range_Ammo"]] call SPM_fnc_spawnMineField;
			[_mineField] call SERVER_CurateEditableObjects;
		};
	};

	_mineField
};

FOB_CreateRoadAmbush =
{
	private _blockadePoint = [roadAt FOB_MissionTruck, getPos FOB_MissionTruck, getDir FOB_MissionTruck, 200 + random 100] call SPM_fnc_roadFollow;

	if (isNull (_blockadePoint select 0)) exitWith
	{
		[] call FOB_CreateWildernessAmbush;
	};

	private _blockadePosition = getPos (_blockadePoint select 0);
	private _blockadeDirection = _blockadePoint select 1;

	private _blockadeForward = [sin _blockadeDirection, cos _blockadeDirection, 0];
	private _blockadeRight = [sin (_blockadeDirection + 90), cos (_blockadeDirection + 90), 0];

	private _sign = if (random 1 < 0.5) then { 1 } else { -1 };

	private _obstructions = [];
	_obstructions pushBack ("Land_Razorwire_F" createVehicle (_blockadePosition vectorAdd (_blockadeForward vectorMultiply (4 + random 6)) vectorAdd (_blockadeRight vectorMultiply (_sign * (2 + random 2)))));
	_obstructions pushBack ("Land_Razorwire_F" createVehicle (_blockadePosition vectorAdd (_blockadeForward vectorMultiply 0) vectorAdd (_blockadeRight vectorMultiply (-_sign * (2 + random 2)))));
	_obstructions pushBack ("Land_Razorwire_F" createVehicle (_blockadePosition vectorAdd (_blockadeForward vectorMultiply -(4 + random 6)) vectorAdd (_blockadeRight vectorMultiply (_sign * (2 + random 2)))));

	{
		_x allowDamage false;
		_x setDir _blockadeDirection;
	} forEach _obstructions;
	[_obstructions] call SERVER_CurateEditableObjects;

	private _fieldWidth = 20 + random 20;
	private _fieldDepth = 1 + random 1;
	private _fieldPosition = _blockadePosition vectorAdd (_blockadeRight vectorMultiply (3 + _fieldDepth / 2));
	private _mineField1 = [_fieldPosition, _fieldWidth, _fieldDepth, _blockadeDirection] call FOB_SpawnMineField;

	_fieldWidth = 30 + random 20;
	_fieldDepth = 5 + random 5;
	_fieldPosition = _blockadePosition vectorAdd (_blockadeRight vectorMultiply -(3 + _fieldDepth / 2));
	private _mineField2 = [_fieldPosition, _fieldWidth, _fieldDepth, _blockadeDirection] call FOB_SpawnMineField;

	private _ambushUnits = [];

	private _inTown = (count (_blockadePosition nearObjects ["House", 50]) > 5);

	private _ambushRadius = if (_inTown) then { 30 } else { 70 };
	private _ambushPosition = _blockadePosition vectorAdd (_blockadeForward vectorMultiply _ambushRadius);

	private _numberAmbushers = 0;
	private _maximumAmbushers = 10 + random 10;

	{
		_ambushUnit = [_x select 0] call FOB_CreateAmbushUnit;
		private _waypoint = _ambushUnit addWaypoint [FOB_MissionTruck, 0];
		_waypoint waypointAttachVehicle FOB_MissionTruck;
		_waypoint setWaypointType "destroy";

		_numberAmbushers = _numberAmbushers + (count units _ambushUnit);

		_ambushUnits pushBack _ambushUnit;

		if (_numberAmbushers >= _maximumAmbushers) exitWith {};
	} forEach selectBestPlaces [_ambushPosition, _ambushRadius, "hills+trees+forest+3*houses-2*meadow", 10, 10];

	[_ambushUnits, _obstructions + _mineField1 + _mineField2]
};

FOB_AmbushIsActive =
{
	count ((_this select 0) select 0) > 0
};

private _truckType = param [0, "", [""]];
private _missionType = param [1, "", [""]];
private _missionSuppliesType = param [2, "", [""]];
private _missionSuppliesInit = param [3, {}, [{}]];
private _missionSuppliesMarker = param [4, "", [""]];
private _missionRewardMarker = param [5, "", [""]];

private _originMarker = "FOB_Depot";
private _destinationMarker = "FOB_Marker";
private _truckMarker = "FOB_Truck";

FOB_MissionTruck = _truckType createVehicle getMarkerPos _originMarker;
FOB_MissionTruck setDir (markerDir _originMarker);
FOB_MissionTruck setAmmoCargo 0;
FOB_MissionTruck setFuelCargo 0;
FOB_MissionTruck setRepairCargo 0;
// Disallow towing or slinging of this truck
FOB_MissionTruck setVariable ["AT_DONOTTOW", true];
FOB_MissionTruck setVariable ["ASL_DONOTSLING", true];
// Suspend driving restriction on this truck
FOB_MissionTruck setVariable ["Restriction_MayNotDriveVehicle", "suspended", true]; // public
[FOB_MissionTruck] call JB_fnc_downgradeATInventory;

[[FOB_MissionTruck]] call SERVER_CurateEditableObjects;

// Have marker follow depot truck until truck is gone

[_truckMarker, _originMarker] spawn
{
	private _truckMarker = _this select 0;
	private _originMarker = _this select 1;

	while { not isNull FOB_MissionTruck } do
	{
		if ( FOB_MissionTruck distance (getMarkerPos _originMarker) > 200 && { isNull (driver FOB_MissionTruck) } ) then
		{
			_truckMarker setMarkerPos getPos FOB_MissionTruck;
		}
		else
		{
			_truckMarker setMarkerPos [-20000,-20000,-20000];
		};

		sleep 0.5;
	};

	_truckMarker setMarkerPos [-20000,-20000,-20000];
};

private _hint = [_missionType, "Forward Operating Base (FOB) Vigilance has requested additional supplies.  There is a HEMTT ready to depart at the FOB depot at main headquarters."] call FOB_Hint;
[_hint] remoteExec ["AW_fnc_globalHint", 0, false];

private _ambush = ambushNull;
private _nextAmbushDistance = 0;
private _lastAmbushPosition = [];
private _retreatVector = [];

while { FOB_ContinueSupplyMissions && { alive FOB_MissionTruck } && { FOB_MissionTruck distance (getMarkerPos _destinationMarker) > _completeDistanceFromDestination } } do
{
	// If there are ambushers active and the mission truck has moved far enough, the truck has escaped and the ambushers should be deleted
	if ([_ambush] call FOB_AmbushIsActive && { FOB_MissionTruck distance _lastAmbushPosition > _ambushDistanceEscape }) then
	{
		[_ambush] call FOB_DeleteAmbush;
		_ambush = ambushNull;
	};

	// If we're in ambush country...
	if (FOB_MissionTruck distance (getMarkerPos _originMarker) > _ambushDistanceFromOrigin && { FOB_MissionTruck distance (getMarkerPos _destinationMarker) > _ambushDistanceFromDestination } ) then
	{
		// If the target position has never been set, do so now.
		if (count _lastAmbushPosition == 0) then
		{
			_lastAmbushPosition = getPos FOB_MissionTruck;
			_nextAmbushDistance = random 600;
		};

		// If there is no active ambush and the mission truck has moved far enough beyond the last one, start a new one
		if (not ([_ambush] call FOB_AmbushIsActive) && { FOB_MissionTruck distance _lastAmbushPosition > _nextAmbushDistance } ) then
		{
			_lastAmbushPosition = getPos FOB_MissionTruck;
			_nextAmbushDistance = _ambushDistanceEscape + random 600;

			_ambush = if (isOnRoad FOB_MissionTruck) then { [] call FOB_CreateRoadAmbush } else { [] call FOB_CreateWildernessAmbush };

			private _ambushUnits = _ambush select 0;
			_retreatVector = (getPos FOB_MissionTruck) vectorFromTo (getPos leader (_ambushUnits select 0));
		};
	};

	sleep 3;
};

private _delay = 120;

if (not FOB_ContinueSupplyMissions) then
{
	_hint = [_missionType, "Operations in the area have ceased.<br/><br/>The resources are no longer needed."] call FOB_Hint;
	[_hint] remoteExec ["AW_fnc_globalHint", 0, false];
}
else
{
	if (not alive FOB_MissionTruck) then
	{
		_hint = [_missionType, "The destruction of the supply truck is a sore loss.  Those supplies need to get through to FOB Vigilance."] call FOB_Hint;
		[_hint] remoteExec ["AW_fnc_globalHint", 0, false];
	}
	else
	{
		private _supplies = _missionSuppliesType createVehicle (getMarkerPos _missionSuppliesMarker);
		[_supplies] call _missionSuppliesInit;
		_supplies setDir (markerDir _missionSuppliesMarker);

		[[_supplies]] call SERVER_CurateEditableObjects;

		private _reward = [_missionRewardMarker] call compile loadFile "mission\fob\reward.sqf";

		_hint = [_missionType, format ["The supplies have reached FOB Vigilance, making that base much more valuable to our troops.<br/><br/>The FOB has also been reinforced by the addition of %1.", _reward select 1]] call FOB_Hint;
		[_hint] remoteExec ["AW_fnc_globalHint", 0, false];

		_delay = 0;
	};
};

[_ambush, FOB_MissionTruck, _retreatVector, _delay] spawn
{
	private _ambush = _this select 0;
	private _truck = _this select 1;
	private _retreatVector = _this select 2;
	private _delay = _this select 3;

	{
		private _waypoints = waypoints _x;
		for "_i" from (count _waypoints - 1) do 0 step -1 do
		{
			deleteWaypoint (_waypoints select _i);
		};

		private _waypoint = _x addWaypoint [(getPos (leader _x)) vectorAdd (_retreatVector vectorMultiply 500), 0];
		_waypoint setWaypointType "move";
		_waypoint setWaypointSpeed "full";

		_x allowFleeing 1.0;
	} forEach (_ambush select 0);

	sleep _delay;

	[_ambush] call FOB_DeleteAmbush;
	deleteVehicle _truck;
};