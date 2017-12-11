diag_log "JB_fnc_ammoPreInit start";

// JBA_S_TransportStores and JBA_C_TransportStores: [[magazine-type, round-count], [magazine-type, round-count], ...]

#define IDC_OK 1
#define IDC_CANCEL 2

JBA_FromUnit = objNull;
JBA_ToUnit = objNull;
JBA_WaitingForTransfer = false;

#define TRANSFER_DIALOG 2700
#define FROM_AMMO_LIST 1200
#define CHOSEN_COUNT 1300
#define TO_AMMO_LIST 1500
#define TO_SOURCES 1600
#define FROM_AMMO_TITLE 1700
#define FROM_CAPACITY 1800
#define TO_CAPACITY 1900

// By default, a vehicle will only permit transfers to the current player, and only if the player is near the edge of the vehicle.  This
// exists to cover vehicles that have ammo, but which are not ammo transport vehicles.  Ammo transporters have an explicit transfer filter on them.
#define DEFAULT_DIRECT_TRANSFER_FILTER [10, JBA_TransferOnlyToPlayer]

JBA_IsLogisticsSpecialist =
{
	private _unit = _this select 0;

	_unit getVariable ["JBA_LogisticsSpecialist", false]
};

JBA_TransferOnlyToPlayer =
{
	private _unit = _this select 0;
	private _candidate = _this select 1;

	if (not ([_candidate, _unit, 2] call JBA_IsNearUnit)) exitWith { false };

	if (((typeOf _candidate) find "Land_PalletTrolley_01_") == 0 && ([player] call JBA_IsLogisticsSpecialist)) exitWith { true };

	(_candidate == player && not ([_candidate] call JBA_CanTransportOtherAmmo))
};

// [magazine-name, [weight-per-round, weapon-name]]
JBA_Magazines =
[
	["2000Rnd_65x39_Belt_Tracer_Red", [0.016, "LMG_Minigun2"]],
	["1000Rnd_65x39_Belt_Tracer_Red", [0.016, "LMG_M200"]],
	["500Rnd_65x39_Belt_Tracer_Red_Splash", [0.016, "LMG_Minigun_Transport"]],
	["500Rnd_127x99_mag_Tracer_Red", [0.117, "HMG_127"]],
	["200Rnd_127x99_mag_Tracer_Red", [0.117, "HMG_127"]],
	["100Rnd_127x99_mag_Tracer_Red", [0.117, "HMG_M2"]],
	["130Rnd_338_Mag", [0.020, "MMG_02_vehicle"]],
	["32Rnd_120mm_APFSDS_shells_Tracer_Red", [18.6, "cannon_120mm"]],
	["140Rnd_30mm_MP_shells_Tracer_Red", [1.460, "autocannon_30mm_CTWS"]],
	["60Rnd_30mm_APFSDS_shells_Tracer_Red", [1.46, "autocannon_30mm_CTWS"]],
	["2Rnd_GAT_missiles", [15.8, "missiles_titan"]],
	["4Rnd_Titan_long_missiles", [15.8, "missiles_titan"]],
	["680Rnd_35mm_AA_shells_Tracer_Red", [1.565, "autocannon_35mm"]],
	["8Rnd_82mm_Mo_shells", [3.1, "mortar_82mm"]],
	["8Rnd_82mm_Mo_Flare_white", [3.1, "mortar_82mm"]],
	["8Rnd_82mm_Mo_Smoke_white", [3.1, "mortar_82mm"]],
	["40Rnd_20mm_G_belt", [0.150, "GMG_20mm"]],
	["60Rnd_40mm_GPR_Tracer_Red_shells", [2.1, "autocannon_40mm_CTWS"]],
	["40Rnd_40mm_APFSDS_Tracer_Red_shells", [2.1, "autocannon_40mm_CTWS"]],

	["200Rnd_40mm_G_belt", [0.230, "GMG_40mm"]],
	["Laserbatteries", [1, "Laserdesignator_mounted"]],
	["SmokeLauncherMag", [6, "SmokeLauncher"]],

	["1000Rnd_20mm_shells", [0.56, "gatling_20mm"]],
	["1000Rnd_Gatling_30mm_Plane_CAS_01_F", [0.397, "Gatling_30mm_Plane_CAS_01_F"]],
	["120Rnd_CMFlare_Chaff_Magazine", [0.175, "CMFlareLauncher"]],
	["168Rnd_CMFlare_Chaff_Magazine", [0.175, "CMFlareLauncher"]],
	["240Rnd_CMFlare_Chaff_Magazine", [0.175, "CMFlareLauncher"]],
	["24Rnd_missiles", [15.8, "missiles_DAR"]],
	["24Rnd_PG_missiles", [15.8, "missiles_DAGR"]],
	["2Rnd_GBU12_LGB", [230, "GBU12BombLauncher"]],
	["2Rnd_Missile_AA_03_F", [85.3, "Missile_AA_03_Plane_CAS_02_F"]],
	["4Rnd_AAA_missiles", [88, "missiles_ASRAAM"]],
	["4Rnd_Bomb_04_F", [230, "Bomb_04_Plane_CAS_01_F"]],
	["4Rnd_GAA_missiles", [88, "missiles_Zephyr"]],
	["500Rnd_Cannon_30mm_Plane_CAS_02_F", [0.397, "Cannon_30mm_Plane_CAS_02_F"]],
	["6Rnd_LG_scalpel", [45.3, "missiles_SCALPEL"]],
	["6Rnd_Missile_AGM_02_F", [45.5, "Missile_AGM_02_Plane_CAS_01_F"]],
	["7Rnd_Rocket_04_AP_F", [6.2, "Rocket_04_AP_Plane_CAS_01_F"]],
	["7Rnd_Rocket_04_HE_F", [6.2, "Rocket_04_HE_Plane_CAS_01_F"]],
	["SmokeLauncherMag_boat", [6, "SmokeLauncher"]],

	["24Rnd_125mm_APFSDS_T_Green", [20.4, "cannon_125mm"]],
	["12Rnd_125mm_HE_T_Green", [33, "cannon_125mm"]],
	["12Rnd_125mm_HEAT_T_Green", [19, "cannon_125mm"]],
	["140Rnd_30mm_MP_shells_Tracer_Green", [1.460, "autocannon_30mm_CTWS"]],
	["60Rnd_30mm_APFSDS_shells_Tracer_Green", [1.46, "autocannon_30mm_CTWS"]],
	["1000Rnd_65x39_Belt_Tracer_Green", [0.016, "LMG_M200"]],
	["2000Rnd_762x51_Belt_Green", [0.025, "LMG_coax"]],
	["450Rnd_127x108_Ball", [0.133, "HMG_NSVT"]],

	["28Rnd_120mm_APFSDS_shells_Tracer_Yellow", [18.6, "cannon_120mm_long"]],
	["14Rnd_120mm_HE_shells_Tracer_Yellow", [18.6, "cannon_120mm_long"]],
	["2000Rnd_762x51_Belt_Yellow", [0.025, "LMG_coax"]],
	["500Rnd_127x99_mag_Tracer_Yellow", [0.117, "HMG_127_APC"]],
	["140Rnd_30mm_MP_shells_Tracer_Yellow", [1.460, "autocannon_30mm_CTWS"]],
	["60Rnd_30mm_APFSDS_shells_Tracer_Yellow", [1.46, "autocannon_30mm_CTWS"]],
	["1000Rnd_65x39_Belt_Tracer_Yellow", [0.016, "LMG_M200"]]
];

JBA_RoundsPerMagazine =
{
	getNumber (configFile >> "CfgMagazines" >> (_this select 0) >> "count");
};

JBA_IsAmmoSource =
{
	private _candidate = _this select 0;
	private _unit = _this select 1;
	private _transferFilter = _this select 2;

	if (_candidate == _unit) exitWith { false };

	if (not alive _candidate) exitWith { false };

	if (isNil { _candidate getVariable "JBA_TransportCapacity" } && { count (weapons _candidate) == 0 }) exitWith { false };

	if (!([_unit, _candidate] call _transferFilter)) exitWith { false };

	true;
};

JBA_AmmoSourceName =
{
	private _source = _this select 0;

	if (isPlayer _source) exitWith { name _source };

	([typeOf _source, "CfgVehicles"] call JB_fnc_displayName)
};

JBA_SetToUnit =
{
	private _unit = _this select 0;

	if (JBA_ToUnit == _unit) exitWith {};

	if (not isNull JBA_ToUnit) then
	{
		[player, JBA_ToUnit] remoteExec ["JBA_S_MonitorChangesStop", 2];
	};

	JBA_ToUnit = _unit;
	if (not isNull JBA_ToUnit) then
	{
		[player, JBA_ToUnit] remoteExec ["JBA_S_MonitorChangesStart", 2];
	};
};

JBA_SetFromUnit =
{
	private _unit = _this select 0;

	if (JBA_FromUnit == _unit) exitWith {};

	if (not isNull JBA_FromUnit) then
	{
		[player, JBA_FromUnit] remoteExec ["JBA_S_MonitorChangesStop", 2];
	};

	JBA_FromUnit = _unit;
	if (not isNull JBA_FromUnit) then
	{
		[player, JBA_FromUnit] remoteExec ["JBA_S_MonitorChangesStart", 2];
	};
};

JBA_IsNearUnit =
{
	private _player = _this select 0;
	private _unit = _this select 1;
	private _distance = _this select 2;

	private _maxBounds = [];

	_maxBounds = (boundingBox _player) select 1;
	private _radiusPlayer = vectorMagnitude _maxBounds;

	_maxBounds = (boundingBox _unit) select 1;
	private _radiusUnit = vectorMagnitude _maxBounds;

	(_radiusPlayer + _radiusUnit + _distance) > (_player distance _unit)
};

JBA_StartMonitoringSources =
{
	_this spawn
	{
		private _unit = _this select 0;

		private _transfers = _unit getVariable ["JBA_DirectTransferFilter", DEFAULT_DIRECT_TRANSFER_FILTER];
		private _transferFilterRange = _transfers select 0;
		private _transferFilter = _transfers select 1;

		disableSerialization;
		private _dialog = findDisplay TRANSFER_DIALOG;

		private _toSources = _dialog displayCtrl TO_SOURCES;

		private _displayedSources = [];

		while { dialog && { [player, _unit, 2] call JBA_IsNearUnit } && { lifeState player in ["HEALTHY", "INJURED"] } } do
		{
			private _selectedIndex = lbCurSel TO_SOURCES;
			private _selection = objNull;
			if (_selectedIndex != -1) then
			{
				_selection = (_displayedSources select _selectedIndex) select 0;
			};

			[_selection] call JBA_SetToUnit;

			// Build a list of objects that are ammo sources
			private _nearestObjects = nearestObjects [_unit, ["All"], _transferFilterRange];
			private _sourceObjects = _nearestObjects select { [_x, _unit, _transferFilter] call JBA_IsAmmoSource };

			private _sources = [];
			{
				_sources pushBack [_x, [_x] call JBA_AmmoSourceName];
			} forEach _sourceObjects;

			// Sort list by distance
			_sources = [_sources, [], { (_x select 0) distanceSqr _unit }, "ASCEND"] call BIS_fnc_sortBy;

			// If the available sources has changed, reload the listbox and make sure the old selection is still valid
			if (not (_sources isEqualTo _displayedSources)) then
			{
				_selectedIndex = -1;
				lbClear _toSources;
				{
					_toSources lbAdd (_x select 1);
					if (_x select 0 == _selection) then { _selectedIndex = _forEachIndex };
				} forEach _sources;

				// If the current selection is no longer available, select a default
				if (_selectedIndex == -1) then
				{
					_selection = objNull;
					if (count _sources > 0) then
					{
						//TODO: This needs to be abstracted into some kind of a preference mechanism among ammo sources.  The highest
						// preference should be the default.  Right now, we're just making sure that the player's trolley is selected
						// by default.
						for "_i" from (count _sources) - 1 to 0 step -1 do
						{
							_selectedIndex = _i;
							_selection = (_sources select _selectedIndex) select 0;
							if (attachedTo _selection == player) exitWith {};
						};
					};
				};

				[_selection] call JBA_SetToUnit;

				lbSetCurSel [TO_SOURCES, _selectedIndex];

				_displayedSources = _sources;
			};

			private _wakeTime = diag_tickTime + 1;
			waitUntil { !dialog || diag_tickTime > _wakeTime };
		};

		if (dialog) then
		{
			closeDialog IDC_OK;
		};
	};
};

JBA_ShowAmmoListCondition =
{
	private _source = _this select 0;

	if (not isNull (findDisplay TRANSFER_DIALOG)) exitWith { false };

	// Player must be on foot
	if (vehicle player != player) exitWith { false };

	// Source must be either the player's side or civilian
	if (not (side _source in [side player, civilian])) exitWith { false };

	// Source must be capable either of transporting ammo or of using it
	// (the simpler "magazines" command is not used because it returns [] if all magazines are empty)
	if (isNil { _source getVariable "JBA_TransportCapacity" } && { count (magazinesAllTurrets _source) == 0 }) exitWith { false };

	([player, _source, 2] call JBA_IsNearUnit)
};

JBA_ShowAmmoList =
{
	private _unit = _this select 0;

	createDialog "JBA_Transfer";
	waitUntil { dialog };

	[_unit] call JBA_SetFromUnit;
	[objNull] call JBA_SetToUnit;

	ctrlSetText [FROM_AMMO_TITLE, [JBA_FromUnit] call JBA_AmmoSourceName];

	[JBA_FromUnit] call JBA_StartMonitoringSources;
};

JBA_S_SendStoresList =
{
	private _caller = _this select 0;
	private _unit = _this select 1;

	private _stores = _unit getVariable ["JBA_S_TransportStores", nil];

	// If the unit has no transport stores, then its weapons are its stores
	if (isNil "_stores") then
	{
		private _magazines = magazinesAllTurrets _unit;

		_stores = [];
		private _storeIndex = -1;
		private _store = [];
		private _rounds = 0;
		private _magazineType = "";

		{
			_magazineType = _x select 0;
			_rounds = _x select 2;

			if (not (_magazineType in ["FakeWeapon", "FakeMagazine"]) && _rounds > 0) then
			{
				_storeIndex = [_stores, _magazineType] call JBA_GetStoreIndex;
				if (_storeIndex == -1) then
				{
					_stores pushBack [_magazineType, _rounds];
				}
				else
				{
					_store = _stores select _storeIndex;
					_store set [1, (_store select 1) + (_rounds)];
				};
			};
		} forEach _magazines;
	};

	[_unit, _stores] remoteExec ["JBA_C_ReceiveStoresList", _caller];
};

JBA_S_MonitorChangesStart =
{
	private _caller = _this select 0;
	private _unit = _this select 1;

	JBA_S_CS_Monitor call JB_fnc_criticalSectionEnter;

	private _clients = _unit getVariable ["JBA_MonitoringClients", []];
	if (count _clients == 0) then
	{
		private _firedEventHandler = _unit addEventHandler ["Fired",
			{
				private _unit = _this select 0;
				private _magazineType = _this select 5;
				[objNull, _unit, _magazineType, -1] call JBA_NotifyStoreChanged;
			}];
		private _killedEventHandler = _unit addEventHandler ["Killed",
			{
				private _unit = _this select 0;
				private _magazineType = _this select 5;
				[objNull, _unit] call JBA_S_DestroyStores;
			}];
		_unit setVariable ["JBA_MonitoringClients_EventHandlers", [_firedEventHandler, _killedEventHandler]];
	};
	_unit setVariable ["JBA_MonitoringClients", _clients + [_caller]];

	JBA_S_CS_Monitor call JB_fnc_criticalSectionLeave;

	[_caller, _unit] call JBA_S_SendStoresList;
};

JBA_S_MonitorChangesStop =
{
	private _caller = _this select 0;
	private _unit = _this select 1;

	JBA_S_CS_Monitor call JB_fnc_criticalSectionEnter;

	private _clients = (_unit getVariable ["JBA_MonitoringClients", []]) - [_caller];
	if (count _clients == 0) then
	{
		private _eventHandlers = _unit getVariable ["JBA_MonitoringClients_EventHandlers", nil];
		if (!isNil "_eventHandlers") then
		{
			_unit removeEventHandler ["Fired", _eventHandlers select 0];
			_unit removeEventHandler ["Killed", _eventHandlers select 1];
			_unit setVariable ["JBA_MonitoringClients_EventHandlers", nil];
		};
	};
	_unit setVariable ["JBA_MonitoringClients", _clients];

	JBA_S_CS_Monitor call JB_fnc_criticalSectionLeave;
};

JBA_KnownMagazineType =
{
	private _magazineType = _this select 0;

	([JBA_Magazines, _magazineType] call BIS_fnc_findInPairs) != -1;
};

JBA_WeightOfStore =
{
	private _magazineType = _this select 0;
	private _rounds = _this select 1;

	private _magazine = [JBA_Magazines, _magazineType] call BIS_fnc_getFromPairs;
	if (isNil "_magazine") then { diag_log format ["JB_fnc_ammoPreInit: Missing %1", _magazineType]; 0};

	(_magazine select 0) * _rounds;
};

JBA_WeightOfStores =
{
	private _stores = _this select 0;

	private _weight = 0;
	{
		_weight = _weight + ([_x select 0, _x select 1] call JBA_WeightOfStore);
	} forEach _stores;

	_weight;
};

JBA_LoadStoresDisplay =
{
	private _unit = _this select 0;
	private _stores = _this select 1;
	private _listControl = _this select 2;
	private _progressControl = _this select 3;
	
	lbClear (_dialog displayCtrl _listControl);
	{
		[_listControl, _x select 0, _x select 1] call JBA_AddAmmoLine;
	} forEach (_unit getVariable ["JBA_C_TransportStores", []]);

	private _percentFilled = 0;

	private _capacity = _unit getVariable ["JBA_TransportCapacity", nil];
	if (!isNil "_capacity") then
	{
		_percentFilled = ([_stores] call JBA_WeightOfStores) / _capacity;
		_percentFilled = _percentFilled min 1;
	};

	(_dialog displayCtrl _progressControl) progressSetPosition _percentFilled;
};

JBA_C_ReceiveStoresList =
{
	private _unit = _this select 0;
	private _stores = _this select 1;

	disableSerialization;
	private _dialog = findDisplay TRANSFER_DIALOG;
	if (isNull (findDisplay TRANSFER_DIALOG)) then
	{
		if (_unit == player) then
		{
			_unit setVariable ["JBA_C_TransportStores", _stores];
		};
	}
	else
	{
		if (_unit == JBA_FromUnit) then
		{
			_unit setVariable ["JBA_C_TransportStores", _stores];
			[_unit, _stores, FROM_AMMO_LIST, FROM_CAPACITY] call JBA_LoadStoresDisplay;
		};

		if (_unit == JBA_ToUnit) then
		{
			_unit setVariable ["JBA_C_TransportStores", _stores];
			[_unit, _stores, TO_AMMO_LIST, TO_CAPACITY] call JBA_LoadStoresDisplay;
		};
	};

	[_unit, _stores] call (_unit getVariable ["JBA_OnStoresChanged", {}]);
};

JBA_AddAmmoLine =
{
	private _control = _this select 0;
	private _magazineType = _this select 1;
	private _rounds = _this select 2;

	private _magazineName = [_magazineType, "CfgMagazines"] call JB_fnc_displayName;
	if (_magazineName == "") then
	{
		private _weight = [JBA_Magazines, _magazineType] call BIS_fnc_getFromPairs;
		_magazineName = [_weight select 1, "CfgWeapons"] call JB_fnc_displayName;
	};
	private _roundsPerMagazine = [_magazineType] call JBA_RoundsPerMagazine;

	private _roundCountText = [_magazineType, _rounds, _roundsPerMagazine] call JBA_FormatRoundCount;

	((findDisplay TRANSFER_DIALOG) displayCtrl _control) lnbAddRow [format ["%1", _roundsPerMagazine], _magazineName, _roundCountText];
};

JBA_FormatRoundCount =
{
	private _magazineType = _this select 0;
	private _rounds = _this select 1;
	private _roundsPerMagazine = _this select 2;

	private _wholeMagazines = floor (_rounds / _roundsPerMagazine);
	private _looseRounds = _rounds - _wholeMagazines * _roundsPerMagazine;

/*
	private _roundCountText = "";
	if (_looseRounds == 0) then
	{
		_roundCountText = format ["%1", _wholeMagazines];
	}
	else
	{
		_roundCountText = format ["%1 + %2", _wholeMagazines, _looseRounds];
	};

	_roundCountText
*/

	str _rounds
};

JBA_UpdateRoundCount =
{
	private _control = _this select 0;
	private _index = _this select 1;
	private _text = _this select 2;

	((findDisplay TRANSFER_DIALOG) displayCtrl _control) lnbSetText [[_index, 2], _text];
};

JBA_TransferUnload =
{
	private _dialog = _this select 0;
	private _exitCode = _this select 1;

	if (not isNull JBA_FromUnit) then
	{
		if (JBA_FromUnit != player) then
		{
			JBA_FromUnit setVariable ["JBA_C_TransportStores", nil];
		};
		[objNull] call JBA_SetFromUnit;
	};
	if (not isNull JBA_ToUnit) then
	{
		if (JBA_ToUnit != player) then
		{
			JBA_ToUnit setVariable ["JBA_C_TransportStores", nil];
		};
		[objNull] call JBA_SetToUnit;
	};
};

JBA_TransferDoneAction =
{
	private _display = _this select 0;

	closeDialog IDC_OK;
};

JBA_TransferKeyDown =
{
	private _control = _this select 0;
	private _keyCode = _this select 1;
	private _shiftKey = _this select 2;
	private _controlKey = _this select 3;
	private _altKey = _this select 4;

	switch (_keyCode) do
	{
		default
		{
		};
	};
};

JBA_RequestTransfer =
{
	private _control = _this select 0;
	private _fromUnit = _this select 1;
	private _toUnit = _this select 2;

	if (isNull _fromUnit || isNull _toUnit) exitWith {};

	if (!JBA_WaitingForTransfer) then
	{
		private _fromIndex = lbCurSel _control;
		if (_fromIndex >= 0) then
		{
			private _fromStores = _fromUnit getVariable ["JBA_C_TransportStores", []];

			private _fromStore = _fromStores select _fromIndex;
			private _magazineType = _fromStore select 0;
			private _availableRounds = _fromStore select 1;

			if ([_magazineType] call JBA_KnownMagazineType) then
			{
				private _roundsPerMagazine = [_magazineType] call JBA_RoundsPerMagazine;

				// Transfer 1 round if a magazine holds less than 50 rounds.  For others, try to
				// fill out a partial magazine.  If no partial exists, attempt to load a whole.
				private _rounds = 1;
				if (_roundsPerMagazine >= 50) then
				{
					_rounds = _roundsPerMagazine min _availableRounds;

					private _toStores = _toUnit getVariable ["JBA_C_TransportStores", []];
					private _toIndex = [_toStores, _magazineType] call JBA_GetStoreIndex;

					if (_toIndex >= 0) then
					{
						private _toStore = _toStores select _toIndex;
						private _availableSpace = _roundsPerMagazine - ((_toStore select 1) mod _roundsPerMagazine);
						if (_availableSpace > 0) then
						{
							_rounds = _rounds min _availableSpace;
						};
					};
				};

				JBA_WaitingForTransfer = true;
				[player, _fromUnit, _toUnit, _magazineType, _rounds] remoteExec ["JBA_S_TransferAmmo", 2];
			};
		};
	};
};

JBA_TransferFromKeyDown =
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
				[FROM_AMMO_LIST, JBA_FromUnit, JBA_ToUnit] call JBA_RequestTransfer;
			};
		};

		default
		{
		};
	};
};

JBA_TransferToKeyDown =
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
				[TO_AMMO_LIST, JBA_ToUnit, JBA_FromUnit] call JBA_RequestTransfer;
			};
		};

		default
		{
		};
	};
};

#define CHANGE_SUCCESSFUL 0
#define CHANGE_PENDING 1
#define UNKNOWN_MAGAZINE_TYPE -1
#define INSUFFICIENT_ROUNDS -2
#define INSUFFICIENT_CAPACITY -3

JBA_GetStoreIndex =
{
	private _stores = _this select 0;
	private _magazineType = _this select 1;

	private _storeIndex = -1;
	{
		if (_x select 0 == _magazineType) exitWith { _storeIndex = _forEachIndex };
	} forEach _stores;

	_storeIndex;
};

JBA_S_RemoveAmmoFromStoreVirtual =
{
	private _from = _this select 0;
	private _magazineType = _this select 1;
	private _rounds = _this select 2;

	private _stores = _from getVariable ["JBA_S_TransportStores", []];
	private _storeIndex = [_stores, _magazineType] call JBA_GetStoreIndex;

	// If we don't know the magazineType, leave
	if (_storeIndex == -1) exitWith { UNKNOWN_MAGAZINE_TYPE };

	private _store = _stores select _storeIndex;

	// If there aren't enough rounds, leave
	if (_store select 1 < _rounds) exitWith { INSUFFICIENT_ROUNDS };

	if (_store select 1 == _rounds)	 then
	{
		_stores deleteAt _storeIndex;
	}
	else
	{
		_store set [1, (_store select 1) - _rounds];
	};

	_from setVariable ["JBA_S_TransportStores", _stores];

	CHANGE_SUCCESSFUL
};

JBA_AdjustTurretAmmo =
{
	private _vehicle = _this select 0;
	private _magazines = _this select 1;
	private _turret = _this select 2;
	private _magazineType = _this select 3;
	private _rounds = _this select 4;

	_vehicle removeMagazinesTurret [_magazineType, _turret];
	{
		if (_x select 0 == _magazineType && { _x select 1 isEqualTo _turret }) then
		{
			if (_rounds != 0) then
			{
				private _roundsInMagazine = _x select 2;
				if (_rounds > 0) then
				{
					private _fullMagazineRounds = [_x select 0] call JBA_RoundsPerMagazine;
					if (_roundsInMagazine < _fullMagazineRounds) then
					{
						private _addedRounds = (_fullMagazineRounds - _roundsInMagazine) min _rounds;
						_x set [2, _roundsInMagazine + _addedRounds];
						_rounds = _rounds - _addedRounds;
					};
				}
				else
				{
					if (_roundsInMagazine > 0) then
					{
						private _removedRounds = _roundsInMagazine min -_rounds;
						_x set [2, _roundsInMagazine - _removedRounds];
						_rounds = _rounds + _removedRounds;
					};
				};
			};

			_vehicle addMagazineTurret [_x select 0, _turret, _x select 2];
		};
	} forEach _magazines;

	_rounds;
};

JBA_FindTurretWithRounds =
{
	private _magazines = _this select 0;
	private _magazineType = _this select 1;
	private _rounds = _this select 2;

	private _turret = [];
	{
		if (_x select 0 == _magazineType && { _x select 2 >= _rounds } ) exitWith { _turret = _x select 1; };
	} forEach _magazines;

	_turret;
};

JBA_FindTurretWithoutRounds =
{
	private _magazines = _this select 0;
	private _magazineType = _this select 1;
	private _rounds = _this select 2;

	private _turret = [];
	{
		if (_x select 0 == _magazineType && { _x select 2 < ([_magazineType] call JBA_RoundsPerMagazine) } ) exitWith { _turret = _x select 1; };
	} forEach _magazines;

	_turret;
};

JBA_R_RemoveAmmoFromStoreWeapons =
{
	private _from = _this select 0;
	private _magazineType = _this select 1;
	private _rounds = _this select 2;

	private _magazines = magazinesAllTurrets _from;

	private _turret = [_magazines, _magazineType, _rounds] call JBA_FindTurretWithRounds;

	if (count _turret == 0) exitWith { INSUFFICIENT_CAPACITY };

	[_from, _magazines, _turret, _magazineType, -_rounds] call JBA_AdjustTurretAmmo;

	CHANGE_SUCCESSFUL
};

JBA_S_RemoveAmmoFromStoreWeaponsResponse =
{
	private _from = _this select 0;
	private _result = _this select 1;

	JBA_S_RemoveWeaponsResponse = _result;
};

JBA_S_RemoveAmmoFromStore =
{
	private _from = _this select 0;
	private _magazineType = _this select 1;
	private _rounds = _this select 2;

	if (not isNil { _from getVariable "JBA_TransportCapacity" }) exitWith { [_from, _magazineType, _rounds] call JBA_S_RemoveAmmoFromStoreVirtual };

	private _magazines = magazinesAllTurrets _from;
	private _turret = [_magazines, _magazineType, _rounds] call JBA_FindTurretWithRounds;

	if (count _turret == 0) exitWith { INSUFFICIENT_CAPACITY };

	private _turretOwner = _from;
	{
		if ((_x select 3) isEqualTo _turret && { not isNull (_x select 0) }) exitWith { _turretOwner = (_x select 0) };
	} forEach (fullCrew _from);

	private _result = [[_from, _magazineType, _rounds], "JBA_R_RemoveAmmoFromStoreWeapons", _turretOwner] call JB_fnc_remoteCall;
	if (_result select 0 == JBRC_TIMEDOUT) exitWith { INSUFFICIENT_CAPACITY };
	_result select 1;
};

JBA_S_AddAmmoToStoreVirtual =
{
	private _from = _this select 0;
	private _magazineType = _this select 1;
	private _rounds = _this select 2;

	private _stores = _to getVariable ["JBA_S_TransportStores", []];
	private _capacity = _to getVariable ["JBA_TransportCapacity", 0];

	// Any store can take one of any item, but otherwise they are limited to their stated capacity
	if (count _stores != 0 && { ([_stores] call JBA_WeightOfStores) + ([_magazineType, _rounds] call JBA_WeightOfStore) > _capacity }) exitWith { INSUFFICIENT_CAPACITY };

	// Find the store to add to
	private _storeIndex = [_stores, _magazineType] call JBA_GetStoreIndex;

	if (_storeIndex == -1) then
	{
		private _store = [_magazineType, _rounds];
		_stores pushBack _store;
	}
	else
	{
		private _store = _stores select _storeIndex;
		_store set [1, (_store select 1) + _rounds];
	};

	_to setVariable ["JBA_S_TransportStores", _stores];

	CHANGE_SUCCESSFUL
};

JBA_MagazineAvailableSpace =
{
	private _magazine = _this select 0;

	([_magazine select 0] call JBA_RoundsPerMagazine) - (_magazine select 2);
};

JBA_R_AddAmmoToStoreWeapons =
{
	private _from = _this select 0;
	private _magazineType = _this select 1;
	private _rounds = _this select 2;

	private _magazines = magazinesAllTurrets _from;

	private _turret = [];
	{
		if (_x select 0 == _magazineType && { ([_x] call JBA_MagazineAvailableSpace) >= _rounds } ) exitWith { _turret = _x select 1; };
	} forEach _magazines;

	if (count _turret == 0) exitWith { INSUFFICIENT_CAPACITY };

	[_from, _magazines, _turret, _magazineType, _rounds] call JBA_AdjustTurretAmmo;

	CHANGE_SUCCESSFUL
};

JBA_S_AddAmmoToStoreWeaponsResponse =
{
	private _from = _this select 0;
	private _result = _this select 1;

	JBA_S_AddWeaponsResponse = _result;
};

JBA_S_AddAmmoToStore =
{
	private _to = _this select 0;
	private _magazineType = _this select 1;
	private _rounds = _this select 2;

	if (not isNil { _to getVariable "JBA_TransportCapacity" }) exitWith { [_to, _magazineType, _rounds] call JBA_S_AddAmmoToStoreVirtual };

	private _magazines = magazinesAllTurrets _to;
	private _turret = [_magazines, _magazineType, _rounds] call JBA_FindTurretWithoutRounds;

	if (count _turret == 0) exitWith { INSUFFICIENT_CAPACITY };

	private _turretOwner = _to;
	{
		if ((_x select 3) isEqualTo _turret && { not isNull (_x select 0) }) exitWith { _turretOwner = (_x select 0) };
	} forEach (fullCrew _to);

	private _result = [[_to, _magazineType, _rounds], "JBA_R_AddAmmoToStoreWeapons", _turretOwner] call JB_fnc_remoteCall;
	if (_result select 0 == JBRC_TIMEDOUT) exitWith { INSUFFICIENT_CAPACITY };
	_result select 1;
};

JBA_S_TransferAmmo =
{
	private _caller = _this select 0;
	private _fromUnit = _this select 1;
	private _toUnit = _this select 2;
	private _magazineType = _this select 3;
	private _rounds = _this select 4;

	private _roundsTransferred = 0;

	JBA_S_CS_Transfer call JB_fnc_criticalSectionEnter;

	if (([_fromUnit, _magazineType, _rounds] call JBA_S_RemoveAmmoFromStore) == CHANGE_SUCCESSFUL) then
	{
		if (([_toUnit, _magazineType, _rounds] call JBA_S_AddAmmoToStore) == CHANGE_SUCCESSFUL) then
		{
			_roundsTransferred = _rounds;
		}
		else
		{
			// Transfer failed.  Put the ammo back into the original store
			[_fromUnit, _magazineType, _rounds] call JBA_S_AddAmmoToStore;
		};
	};

	JBA_S_CS_Transfer call JB_fnc_criticalSectionLeave;

	[_caller, _fromUnit, _magazineType, -_roundsTransferred] call JBA_NotifyStoreChanged;
	[_caller, _toUnit, _magazineType, _roundsTransferred] call JBA_NotifyStoreChanged;
};

JBA_NotifyStoreChanged =
{
	private _caller = _this select 0;
	private _unit = _this select 1;
	private _magazineType = _this select 2;
	private _rounds = _this select 3;

	private _monitoringClients = _unit getVariable ["JBA_MonitoringClients", []];

	{
		if (_x == _unit) then { _unitNotified = true };
		if (alive _x) then
		{
			[_caller, _unit, _magazineType, _rounds] remoteExec ["JBA_C_StoreChanged", _x];
		}
		else
		{
			[_x, _unit] call JBA_S_MonitorChangesStop;
		}
	} forEach _monitoringClients;

	// If we have a character that isn't currently monitoring its store, notify it anyway
	if ((typeOf _unit) isKindOf "Man" && { !(_unit in _monitoringClients) }) then
	{
		[_caller, _unit, _magazineType, _rounds] remoteExec ["JBA_C_StoreChanged", _unit];
	};
};

JBA_C_StoreChanged =
{
	private _caller = _this select 0;
	private _unit = _this select 1;
	private _magazineType = _this select 2;
	private _rounds = _this select 3;

	if (_caller == player) then
	{
		JBA_WaitingForTransfer = false;
	};

	disableSerialization;
	private _dialog = findDisplay TRANSFER_DIALOG;

	private _control = -1;
	if (not isNull _dialog) then
	{
		_control = if (_unit == JBA_FromUnit) then { FROM_AMMO_LIST } else { TO_AMMO_LIST };
	};

	private _stores = _unit getVariable ["JBA_C_TransportStores", []];
	private _storeIndex = [_stores, _magazineType] call JBA_GetStoreIndex;

	if (_rounds < 0 && _storeIndex == -1) exitWith { diag_log "Attempt to remove ammunition not listed in unit stores." };

	// If the magazine type is unknown, then we are adding a new type of ammo to the store
	if (_storeIndex == -1) then
	{
		_stores pushBack [_magazineType, 0];
		_storeIndex = (count _stores) - 1;

		if (_control != -1) then
		{
			[_control, _magazineType, 0] call JBA_AddAmmoLine;
		};
	};

	// Add/remove the rounds to/from the store
	private _store = _stores select _storeIndex;
	private _roundCount = (_store select 1) + _rounds;

	if (_roundCount == 0) then
	{
		_stores deleteAt _storeIndex;
		_unit setVariable ["JBA_C_TransportStores", _stores];

		if (_control != -1) then
		{
			((findDisplay TRANSFER_DIALOG) displayCtrl _control) lnbDeleteRow _storeIndex;
		};
	}
	else
	{
		_store set [1, _roundCount];
		_unit setVariable ["JBA_C_TransportStores", _stores];

		if (_control != -1) then
		{
			// Update the display with the new round count
			private _roundCountText = [_magazineType, _roundCount, [_magazineType] call JBA_RoundsPerMagazine] call JBA_FormatRoundCount;
			[_control, _storeIndex, _roundCountText] call JBA_UpdateRoundCount;
		};
	};

	if (not isNull _dialog) then
	{
		_control = if (_unit == JBA_FromUnit) then { FROM_CAPACITY } else { TO_CAPACITY };

		private _percentFilled = 0;

		private _capacity = _unit getVariable ["JBA_TransportCapacity", nil];
		if (!isNil "_capacity") then
		{
			_percentFilled = ([_stores] call JBA_WeightOfStores) / _capacity;
			_percentFilled = _percentFilled min 1;
		};

		(_dialog displayCtrl _control) progressSetPosition _percentFilled;
	};

	[_unit, _stores] call (_unit getVariable ["JBA_OnStoresChanged", {}]);
};

JBA_NotifyStoresList =
{
	private _caller = _this select 0;
	private _unit = _this select 1;

	private _monitoringClients = _unit getVariable ["JBA_MonitoringClients", []];

	private _stores = _unit getVariable ["JBA_S_TransportStores", []];
	{
		if (alive _x) then
		{
			[_unit, _stores] remoteExec ["JBA_C_ReceiveStoresList", _x];
		}
		else
		{
			[_x, _unit] call JBA_S_MonitorChangesStop;
		}
	} forEach _monitoringClients;

	if ((typeOf _unit) isKindOf "Man" && { !(_unit in _monitoringClients) }) then
	{
		[_unit, _stores] remoteExec ["JBA_C_ReceiveStoresList", _unit];
	};
};

JBA_S_DestroyStores =
{
	private _caller = _this select 0;
	private _unit = _this select 1;

	JBA_S_CS_Transfer call JB_fnc_criticalSectionEnter;

	_unit setVariable ["JBA_S_TransportStores", []];

	JBA_S_CS_Transfer call JB_fnc_criticalSectionLeave;

	[_caller, _unit] call JBA_NotifyStoresList;
};

// If the unit is directly transporting ammo
JBA_IsTransportingAmmo =
{
	private _unit = _this select 0;

	private _stores = _unit getVariable "JBA_C_TransportStores";
	not isNil "_stores" && { count _stores > 0 }
};

// If the unit has something attached to it that can transport ammo
JBA_CanTransportOtherAmmo =
{
	private _unit = _this select 0;

	private _canTransportOtherAmmo = false;
	{
		if (not isNil { _x getVariable "JBA_TransportCapacity" }) exitWith { _canTransportOtherAmmo = true };
	} forEach (attachedObjects _unit);

	_canTransportOtherAmmo;
};

if (isServer) then
{
	if (isNil "JBA_S_CS_Transfer") then
	{
		JBA_S_CS_Transfer = call JB_fnc_criticalSectionCreate;
		JBA_S_CS_Monitor = call JB_fnc_criticalSectionCreate;
	};
};

diag_log "JB_fnc_ammoPreInit end";