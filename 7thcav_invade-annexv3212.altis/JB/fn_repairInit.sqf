#define IDC_OK 1
#define IDC_CANCEL 2

#define REPAIR_DIALOG 2800
#define SYSTEMS_LIST 1200

JBR_GetVehicleComponents =
{
	params ["_vehicle"];

	private _componentsIndex = [JBR_VehicleComponents, typeOf _vehicle] call BIS_fnc_findInPairs;
	if (_componentsIndex >= 0) exitWith { JBR_VehicleComponents select _componentsIndex select 1 };

	private _systems = getAllHitPointsDamage _vehicle select 1;

	private _wheelIndex = 0;

	_systems apply
		{
			switch (true) do
			{
				case (_x find "wheel" >= 0): { _wheelIndex = _wheelIndex + 1; [format ["Wheel %1", _wheelIndex], 10] };
				case (_x find "glass" >= 0): { ["Glass", 2] };
				case (_x find "light" >= 0): { ["Lights", 5] };
				default { ["", 0] };
			}
		};
};

// Given a vehicle class and a system name, return a list of hitpoint indices and the number of points allocated to each
// The format of the return is [[index, [system-name, points]], [index, [system-name, points]], ...]
JBR_GetSystemDescriptor =
{
	private _vehicle = _this select 0;
	private _systemName = _this select 1;

	private _descriptor = [];
	if (typeOf _vehicle != "" && _systemName != "") then
	{
		{
			if (_x select 0 == _systemName) then
			{
				_descriptor pushBack [_forEachIndex, _x];
			};
		} forEach ([_vehicle] call JBR_GetVehicleComponents);
	};

	_descriptor;
};

#define END_OF_SEQUENCE "AinvPknlMstpSnonWnonDnon_medicEnd"

JBR_RunAnimationSequence =
{
	private _animations =
	[
		"AinvPknlMstpSnonWnonDnon_medic_1",
		"AinvPknlMstpSnonWnonDnon_medicUp1",
		"AinvPknlMstpSnonWnonDnon_medicUp3",
		"AinvPknlMstpSnonWnonDnon_medicUp5",
		"AinvPknlMstpSnonWnonDr_medicUp1",
		"AinvPknlMstpSnonWnonDr_medicUp4",
		"Acts_carFixingWheel",
		"Acts_carFixingWheel"
	];
	private _index = 0;
	while { count _animations > 0 } do
	{
		_index = random (count _animations);
		player playMove (_animations select _index);
		_animations deleteAt _index;
	};
	player playMove END_OF_SEQUENCE;
};

JBR_OriginalAnimationState = "";

JBR_R_RepairSystemDamage =
{
	private _vehicle = _this select 0;
	private _componentIndex = _this select 1;
	private _repairPercent = _this select 2;
	private _damageLimit = _this select 3;

//	player sidechat format ["JBR_R_RepairSystemDamage: %1, %2", _repairPercent, _damageLimit];
	private _damagePercent = _vehicle getHitIndex _componentIndex;
	if (_damagePercent > _damageLimit) then
	{
		private _componentDamage = (_damagePercent - _repairPercent) max _damageLimit;
//		player sidechat format ["JBR_R_RepairSystemDamage: %1, %2, %3", _vehicle, _componentIndex, _componentDamage];
		_vehicle setHitIndex [_componentIndex, _componentDamage]
	};
};

JBR_GetSystemDamage =
{
	private _vehicle = _this select 0;
	private _descriptor = _this select 1;

	{
		_x set [2, _vehicle getHitIndex (_x select 0)];
	} forEach _descriptor;
};

JBR_PointsSystemDamageToRepair =
{
	private _descriptor = _this select 0;
	private _targetDamagePC = _this select 1;

	private _totalPoints = 0;
	{
		private _damagePC = (_x select 2) - _targetDamagePC;
		if (_damagePC > 0) then
		{
			_totalPoints = _totalPoints + _damagePC * ((_x select 1) select 1);
		};
	} forEach _descriptor;

	_totalPoints;
};

JBR_GetSystemRepairProfile =
{
	private _engineer = param [0, objNull, [objNull]];
	private _vehicle = param [1, objNull, [objNull]];
	private _systemName = param [2, "", [""]];

	if (_systemName == "") exitWith { [] };

	private _repairProfile = _engineer getVariable ["JBR_RepairProfile", []];
	if (count _repairProfile == 0) exitWith { [] };

	[_engineer, _vehicle, _systemName] call (_repairProfile select 0);
};

JBR_ContinueRepairs =
{
	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if (player distance JBR_Vehicle > (sizeOf (typeOf JBR_Vehicle)) / 2) exitWith { false };

	if (not alive JBR_Vehicle) exitWith { false };

	true;
};

JBR_RepairSystemStop =
{
	JBR_InterruptRepair = true;
};

// How long one repair cycle lasts (seconds)
#define REPAIR_INTERVAL 2

JBR_RepairSystem =
{
	JBR_RepairsInProgress = true;

	_this spawn
	{
		private _systemIndex = param [0, 0, [0]];

		private _systemName = (JBR_VehicleSystems select _systemIndex) select 0;

		// Get the vehicle system repair descriptor
		private _descriptor = [JBR_Vehicle, _systemName] call JBR_GetSystemDescriptor;

		// Find out how much damage is on each component
		[JBR_Vehicle, _descriptor] call JBR_GetSystemDamage;

		// Get the player's profile for repairing this vehicle's system
		private _repairProfile = [player, JBR_Vehicle, _systemName] call JBR_GetSystemRepairProfile;

		private _knowsSystem = _repairProfile select 0;
		private _systemRepairPPS = _repairProfile select 1;
		private _systemRepairTargetPC = (_repairProfile select 2) max 0;
		private _systemRepairMessage = _repairProfile select 3;
		private _canRepair = _repairProfile select 4;

		ctrlSetText [1300, _systemRepairMessage];

		if (!_canRepair) exitWith
		{
			JBR_RepairsInProgress = nil;
		};

		JBR_OriginalAnimationState = animationState player;
		[] call JBR_RunAnimationSequence;

		sleep 2; // Repair prep time

		private _componentIndex = 0;
		private _componentPoints = 0;
		private _componentDamage = 0;
		private _componentTargetDamage = 0;

		{
			if (not ([] call JBR_ContinueRepairs)) exitWith {};

			_componentIndex = _x select 0;
			_componentPoints = (_x select 1) select 1;
			_componentDamage = _componentPoints * (_x select 2);
			_componentTargetDamage = _componentPoints * _systemRepairTargetPC;

//			player sidechat format ["Repairing component %1", (_x select 1) select 0];

			_componentRepairTime = (_componentDamage - _componentTargetDamage) / _systemRepairPPS;
//			player sidechat format ["_componentRepairTime: %1", _componentRepairTime];
			while { _componentRepairTime > 0 && isNil "JBR_InterruptRepair" } do
			{
				if (not ([] call JBR_ContinueRepairs)) exitWith {};

				if (!isNil "_repairRestrictions" && { !([JBR_Vehicle, _systemName] call _repairRestrictions) }) exitWith {};

				if (animationState player == END_OF_SEQUENCE) then
				{
					[] call JBR_RunAnimationSequence;
				};

				_repairStep = _componentRepairTime min REPAIR_INTERVAL;
//				player sidechat format ["_repairStep: %1", _repairStep];

				[JBR_Vehicle, _descriptor] call JBR_GetSystemDamage;
				private _systemRepairTime = ([_descriptor, _systemRepairTargetPC] call JBR_PointsSystemDamageToRepair) / _systemRepairPPS;

				private _minutes = floor (_systemRepairTime / 60);

				private _seconds = (round _systemRepairTime) mod 60;
				private _leadingZero = "";
				if (_seconds < 10) then { _leadingZero = "0" };

				private _progress = format ["%2:%3%4", (_x select 1) select 0, _minutes, _leadingZero, _seconds];
				lnbSetText [1200, [_systemIndex, 2], _progress];

				// Make repairs
				[JBR_Vehicle, _componentIndex, _repairStep / (_componentPoints / _systemRepairPPS), _systemRepairTargetPC] remoteExec ["JBR_R_RepairSystemDamage", JBR_Vehicle];

				sleep _repairStep;

				_componentRepairTime = _componentRepairTime - _repairStep;
				_systemRepairTime = _systemRepairTime - _repairStep;
			};

		} forEach _descriptor;

		lnbSetText [1200, [_systemIndex, 2], ""];
		ctrlSetText [1300, ""];

		player playMoveNow JBR_OriginalAnimationState;

		JBR_InterruptRepair = nil;
		JBR_RepairsInProgress = nil;
	};
};

JBR_InspectVehicleCondition =
{
	private _vehicle = param [0, objNull, [objNull]];

	if (vehicle player != player) exitWith { false };

	if (isNull _vehicle) exitWith { false };

	if (!alive _vehicle) exitWith { false };

	if (locked _vehicle in [2, 3]) exitWith { false };

	if (side _vehicle getFriend side player < 0.6) exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if (player distance _vehicle > (sizeOf (typeOf _vehicle)) / 2) exitWith { false };

	if ([animationState player, ["cin", "inv"]] call JB_fnc_matchAnimationState) exitWith { false };

	private _repairProfile = player getVariable ["JBR_RepairProfile", []];

	if (count _repairProfile == 0) exitWith { false };

	[player, _vehicle] call (_repairProfile select 1);
};

JBR_InspectVehicle =
{
	JBR_Vehicle = param [0, objNull, [objNull]];

	createDialog "JBR_Repair";
	waitUntil { dialog };

	disableSerialization;
	private _dialog = findDisplay 2800;
	private _systemsList = _dialog displayCtrl 1200;

	JBR_VehicleSystems = [typeof JBR_Vehicle] call JBR_GetSystems;

	lbClear _systemsList;
	{
		_systemsList lnbAddRow [_x select 0];
		[_x, _forEachIndex] call JBR_UpdateSystemRow;
	} forEach JBR_VehicleSystems;

	[] spawn
	{
		while { dialog } do
		{
			{
				[_x, _forEachIndex] call JBR_UpdateSystemRow;
			} forEach JBR_VehicleSystems;
			sleep 1;
		};
	};
};

 // [[systemName, [component-index, component-index, ...]], [systemName, [component-index, component-index, ...]], ...]
JBR_GetSystems =
{
	private _systems = [];
	{
		_systemName = _x select 0;

		if (_systemName != "") then
		{
			private _profile = [player, JBR_Vehicle, _systemName] call JBR_GetSystemRepairProfile;
			if (_profile select 0) then
			{
				_systemIndex = [_systems, _systemName] call BIS_fnc_findInPairs;
				if (_systemIndex == -1) then
				{
					_systems pushBack [_systemName, [_forEachIndex]];
				}
				else
				{
					_system = _systems select _systemIndex;
					(_system select 1) pushBack _forEachIndex;
				};
			};
		};
	} forEach ([JBR_Vehicle] call JBR_GetVehicleComponents);

	_systems;
};

JBR_UpdateSystemRow =
{
	private _system = _this select 0;
	private _systemIndex = _this select 1;

	private _systemDamage = 0;
	{
		_systemDamage = _systemDamage + (JBR_Vehicle getHitIndex _x);
	} forEach (_system select 1);
	_systemDamage = _systemDamage / (count (_system select 1));

	_description = "";
	if (_systemDamage > 0.01) then { _description = "bent"; };
	if (_systemDamage > 0.33) then { _description = "damaged"; };
	if (_systemDamage > 0.66) then { _description = "disabled"; };
	if (_systemDamage > 0.99) then { _description = "destroyed"; };

	lnbSetText [1200, [_systemIndex, 1], _description];
};

JBR_RepairSystemsKeyDown =
{
	private _control = _this select 0;
	private _keyCode = _this select 1;
	private _shiftKey = _this select 2;
	private _controlKey = _this select 3;
	private _altKey = _this select 4;

	switch (_keyCode) do
	{
		case 57: // space
		{
			if (not _shiftKey && not _controlKey && not _altKey) then
			{
				if (isNil "JBR_RepairsInProgress") then
				{
					[lbCurSel _control] call JBR_RepairSystem;
				}
				else
				{
					[] call JBR_RepairSystemStop;
				};
			};
		};

		default
		{
		};
	};
};

JBR_RepairUnload =
{
	private _dialog = _this select 0;
	private _exitCode = _this select 1;

	if (not isNil "JBR_RepairsInProgress") then
	{
		[] call JBR_RepairSystemStop;
	};
};

JBR_RepairDoneAction =
{
	private _display = _this select 0;

	closeDialog IDC_OK;
};

JBR_SetupActions =
{
	player addAction ["Inspect vehicle condition", { [cursorTarget] call JBR_InspectVehicle; }, [], 0, false, true, "", "[cursorTarget] call JBR_InspectVehicleCondition;"];
};

private _unit = param [0, objNull, [objNull]];
private _repairProfile = param [1, [], [[]]];

_unit setVariable ["JBR_RepairProfile", _repairProfile];

[] call JBR_SetupActions;
player addEventHandler ["Respawn", { [] call JBR_SetupActions }];