#include "..\spm\strongpoint.h"

OO_TRACE_DECL(SERVER_C_AnnounceCurator) =
{
	params ["_curator", "_curatorType"];

	if (player == _curator) then
	{
		CLIENT_CuratorType = _curatorType;

		if (_curatorType == "GM") then
		{
			addMissionEventHandler ["Draw3D", TRACE_DrawObjectValues];
		};
	};

	private _curatorDescription = if (_curatorType == "MP") then { "Military Police" } else { "Game Master" };

	systemchat format ["%1 has been assigned curator abilities (%2)", name _curator, _curatorDescription];
};

if (not isServer) exitWith {};

PCC_LightParaDrop =
[
	["B_supplyCrate_F", "B_Parachute_02_F", 30, "B_IRStrobe", "SmokeShellBlue"],
	["B_CargoNet_01_ammo_F", "B_Parachute_02_F", 30, "B_IRStrobe", "SmokeShellBlue"]
];

PCC_HeavyParaDrop =
[
	["B_Slingload_01_Repair_F", "B_Parachute_02_F", 40, "B_IRStrobe", "SmokeShellBlue"],
	["B_Slingload_01_Medevac_F", "B_Parachute_02_F", 40, "B_IRStrobe", "SmokeShellBlue"],
	["B_Slingload_01_Fuel_F", "B_Parachute_02_F", 40, "B_IRStrobe", "SmokeShellBlue"]
];

PCC_PodParaDrop =
[
	["Land_Pod_Heli_Transport_04_bench_F", "B_Parachute_02_F", 40, "B_IRStrobe", ""],
	["Land_Pod_Heli_Transport_04_covered_F", "B_Parachute_02_F", 40, "B_IRStrobe", ""],
	["Land_Pod_Heli_Transport_04_fuel_F", "B_Parachute_02_F", 40, "B_IRStrobe", "SmokeShellBlue"],
	["Land_Pod_Heli_Transport_04_medevac_F", "B_Parachute_02_F", 40, "B_IRStrobe", ""],
	["Land_Pod_Heli_Transport_04_repair_F", "B_Parachute_02_F", 40, "B_IRStrobe", "SmokeShellBlue"],
	["Land_Pod_Heli_Transport_04_box_F", "B_Parachute_02_F", 40, "B_IRStrobe", "SmokeShellBlue"],
	["Land_Pod_Heli_Transport_04_ammo_F", "B_Parachute_02_F", 40, "B_IRStrobe", "SmokeShellBlue"]
];

Ammo_VehicleAmmo =
[
	["2000Rnd_65x39_Belt_Tracer_Red", 2000],
	["1000Rnd_65x39_Belt_Tracer_Red", 1000],
	["500Rnd_65x39_Belt_Tracer_Red_Splash", 500],
	["500Rnd_127x99_mag_Tracer_Red", 500],
	["200Rnd_127x99_mag_Tracer_Red", 200],
	["100Rnd_127x99_mag_Tracer_Red", 100],
	["130Rnd_338_Mag", 130],
	["140Rnd_30mm_MP_shells_Tracer_Red", 140],
	["60Rnd_30mm_APFSDS_shells_Tracer_Red", 60],
	["680Rnd_35mm_AA_shells_Tracer_Red", 680],
	["60Rnd_40mm_GPR_Tracer_Red_shells", 60],
	["40Rnd_40mm_APFSDS_Tracer_Red_shells", 40],
	["200Rnd_40mm_G_belt", 200],
	["32Rnd_120mm_APFSDS_shells_Tracer_Red", 32],
	["2Rnd_GAT_missiles", 2],
	["4Rnd_Titan_long_missiles", 4],
	["Laserbatteries", 2],
	["SmokeLauncherMag", 4]
];

Ammo_AircraftAmmo =
[
	["2000Rnd_65x39_Belt_Tracer_Red", 2000],
	["1000Rnd_20mm_shells", 1000],
	["1000Rnd_Gatling_30mm_Plane_CAS_01_F", 1000],
	["500Rnd_Cannon_30mm_Plane_CAS_02_F", 500],
	["24Rnd_missiles", 24],
	["24Rnd_PG_missiles", 24],
	["2Rnd_GBU12_LGB", 2],
	["2Rnd_Missile_AA_03_F", 2],
	["4Rnd_AAA_missiles", 4],
	["4Rnd_Bomb_04_F", 4],
	["4Rnd_GAA_missiles", 4],
	["6Rnd_LG_scalpel", 6],
	["6Rnd_Missile_AGM_02_F", 6],
	["7Rnd_Rocket_04_AP_F", 7],
	["7Rnd_Rocket_04_HE_F", 7],
	["240Rnd_CMFlare_Chaff_Magazine", 240],
	["168Rnd_CMFlare_Chaff_Magazine", 168],
	["120Rnd_CMFlare_Chaff_Magazine", 120],
	["200Rnd_40mm_G_belt", 200],
	["SmokeLauncherMag", 2],
	["Laserbatteries", 2],
	["SmokeLauncherMag_boat", 2]
];

SERVER_CuratorMaster = objNull;
SERVER_GameMasters = [];
SERVER_MilitaryPolice = [];

OO_TRACE_DECL(SERVER_DeleteWeaponHolders) =
{
	private _center = _this select 0;
	private _a = _this select 1;
	private _b = _this select 2;
	private _angle = _this select 3;
	private _isRectangle = _this select 4;
	private _c = _this select 5;

	{
		deleteVehicle _x;
	} forEach (nearestObjects [_center, ["WeaponHolder"], _a max _b]) inAreaArray [_center, _a, _b, _angle, _isRectangle, _c];
};

OO_TRACE_DECL(SERVER_CurateEditableObjects) =
{
	private _objects = _this select 0;

	SERVER_CuratorMaster addCuratorEditableObjects [_objects, false];
	{
		_x addCuratorEditableObjects [_objects, false];
	} forEach SERVER_GameMasters;
};

OO_TRACE_DECL(SERVER_RemoteExecCurators) =
{
	params ["_parameters", "_command", ["_curatorType", "ALL", [""]]];

	private _remoteExec =
	{
		params ["_parameters", "_command", "_curators"];

		{
			private _unit = getAssignedCuratorUnit _x;
			if (not isNull _unit) then
			{
				_parameters remoteExec [_command, _unit];
			};
		} forEach _curators;
	};

	if (_curatorType in ["ALL", "GM"]) then
	{
		[_parameters, _command, SERVER_GameMasters] call _remoteExec;
	};

	if (_curatorType in ["ALL", "MP"]) then
	{
		[_parameters, _command, SERVER_MilitaryPolice] call _remoteExec;
	};
};

OO_TRACE_DECL(SERVER_CuratorAssign) =
{
	private _player = _this select 0;

	private _curatorType = [getPlayerUID _player] call compile preprocessFile "scripts\curatorType.sqf";

	if (_curatorType in ["GM", "MP"] && { isNull getAssignedCuratorLogic _player }) then
	{
		private _curator = objNull;
		{
			if (isNull getAssignedCuratorUnit _x && _x != SERVER_CuratorMaster) exitWith
			{
				_curator = _x;
			};
		} forEach allCurators;

		if (not isNull _curator) then
		{
			removeAllCuratorAddons _curator;

			private _description = "";
			if (_curatorType == "MP") then
			{
				_curator addCuratorEditableObjects [allPlayers, false];

				SERVER_MilitaryPolice pushBackUnique _curator;
			}
			else
			{
				_curator addCuratorAddons activatedAddons;
				_curator addCuratorEditableObjects [curatorEditableObjects SERVER_CuratorMaster, false];

				SERVER_GameMasters pushBackUnique _curator;
			};

			_curator setVariable ["showNotification", false];
			_curator setVariable ["bird", objNull];

			_player assignCurator _curator;

			[[_player, _curatorType], "SERVER_C_AnnounceCurator"] call SERVER_RemoteExecCurators;
		};
	};
};

OO_TRACE_DECL(SERVER_CuratorUnassign) =
{
	private _player = _this select 0;

	if (not isServer) exitWith {};

	private _curator = getAssignedCuratorLogic _player;
	if (not isNull _curator) then
	{
		SERVER_MilitaryPolice = SERVER_MilitaryPolice - [_curator];
		SERVER_GameMasters = SERVER_GameMasters - [_curator];

		_curator removeCuratorEditableObjects [curatorEditableObjects _curator, false];
		unassignCurator _curator;
	};
};

OO_TRACE_DECL(SERVER_CuratePlayer) =
{
	private _player = param [0, objNull, [objNull]];

	[[_player]] call SERVER_CurateEditableObjects;

	{
		_x addCuratorEditableObjects [[_player], false];
	} forEach SERVER_MilitaryPolice;

	[_player] call SERVER_CuratorAssign;
};

OO_TRACE_DECL(SERVER_RegisterDeaths_Killed) =
{
	if (isNil "SERVER_DeadBodies") then
	{
		SERVER_DeadBodies = [];

		[] spawn
		{
			while { true } do
			{
				private _currentTime = diag_tickTime;
				while { count SERVER_DeadBodies > 0 && { (SERVER_DeadBodies select 0) select 1 < _currentTime }} do
				{
					deleteVehicle ((SERVER_DeadBodies deleteAt 0) select 0);
				};

				if (count SERVER_DeadBodies == 0) then
				{
					sleep 180;
				}
				else
				{
					sleep (((SERVER_DeadBodies select 0) select 1) - _currentTime);
				};
			};
		};
	};

	SERVER_DeadBodies pushBack [_this select 0, diag_tickTime + 180];
};

OO_TRACE_DECL(SERVER_RegisterDeaths) =
{
	private _group = _this select 0;

	{
		_x addEventHandler ["Killed", SERVER_RegisterDeaths_Killed];
	} forEach units _group;
};

OO_TRACE_DECL(SERVER_GetPlayerByUID) =
{
	private _player = objNull;
	{
		if (getPlayerUID _x == _uid) exitWith { _player = _x };
	} forEach allPlayers;

	_player;
};

OO_TRACE_DECL(SERVER_PlayerConnected) =
{
	private _uid = _this select 1;

	[_uid] spawn
	{
		private _uid = _this select 0;

		private _player = objNull;
		[{ _player = [_uid] call SERVER_GetPlayerByUID; not isNull _player }, 30, 1] call JB_fnc_timeoutWaitUntil;

		_player addMPEventHandler ["MPKilled", { if (isServer) then { [_this select 0] call SERVER_CuratorUnassign } }];
	};
};

OO_TRACE_DECL(SERVER_PlayerDisconnected) =
{
	private _uid = _this select 1;

	private _player = [_uid] call SERVER_GetPlayerByUID;

	if (isNull _player) then
	{
		diag_log format ["SERVER_PlayerDisconnected: could not locate player by UID %1", _uid];
	}
	else
	{
		_player spawn
		{
			private _player = _this;

			[_player] remoteExec ["CLIENT_PlayerDisconnected", 0];

			sleep 3;

			// If the disconnecting unit is in a vehicle, get it out
			if (vehicle _player != _player) then
			{
				[vehicle _player] call JB_fnc_ejectDeadBodies;
			};

			// Delete the disconnecting unit
			deleteVehicle _player;
		};
	};
};

OO_TRACE_DECL(SERVER_Supply_StockAmmunitionContainer) =
{
	private _container = _this select 0;
	private _capacity = _this select 1;
	private _clear = _this select 2;

	if (_clear) then
	{
		[_container] call JB_fnc_clearVehicleInventory;
	};

	private _magazineTypes = [] call compile preprocessFile "scripts\whitelistMagazines.sqf";

	private _allocations = count _magazineTypes + 5;
	private _capacityPerType = _capacity / _allocations;

	private _itemMass = 0;
	{
		_itemMass = getNumber (configFile >> "CfgMagazines" >> _x >> "mass");
		_container addMagazineCargoGlobal [_x, floor (_capacityPerType / _itemMass)];
	} forEach _magazineTypes;

	private _items = ["FirstAidKit"];
	{
		_itemMass = getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass");
		_container addItemCargoGlobal [_x, floor ((_capacityPerType / (count _items)) / _itemMass)];
	} forEach _items;

	private _items = ["DemoCharge_Remote_Mag"];
	{
		_itemMass = getNumber (configFile >> "CfgMagazines" >> _x >> "mass");
		_container addMagazineCargoGlobal [_x, floor ((_capacityPerType / (count _items)) / _itemMass)];
	} forEach _items;

	private _grenades = ["HandGrenade", "MiniGrenade", "1Rnd_HE_Grenade_shell", "3Rnd_HE_Grenade_shell"];
	{
		_itemMass = getNumber (configFile >> "CfgMagazines" >> _x >> "mass");
		_container addMagazineCargoGlobal [_x, floor ((_capacityPerType * 2 / (count _grenades)) / _itemMass)];
	} forEach _grenades;

	private _grenades = ["SmokeShell", "1Rnd_Smoke_Grenade_shell", "3Rnd_Smoke_Grenade_shell"];
	{
		_itemMass = getNumber (configFile >> "CfgMagazines" >> _x >> "mass");
		_container addMagazineCargoGlobal [_x, floor ((_capacityPerType / (count _grenades)) / _itemMass)];
	} forEach _grenades;
};

OO_TRACE_DECL(SERVER_Supply_StockExplosivesContainer) =
{
	private _container = _this select 0;
	private _capacity = _this select 1;
	private _clear = _this select 2;

	if (_clear) then
	{
		[_container] call JB_fnc_clearVehicleInventory;
	};

	private _type = "";
	private _explosiveTypes = [];
	{
		_type = getText (_x >> "type");
		if (_type find "2*" == 0 && { (_type splitString toString [32,9,13,10] joinString "") == "2*256" }) then
		{
			private _name = configName _x;
			if (_name find "Rnd_" == -1 && _name find "RPG" != 0 && _name find "CA" != 0) then
			{
				_explosiveTypes pushBack _name;
			};
		};
	} forEach ("true" configClasses (configFile >> "CfgMagazines"));
	
	private _allocations = count _explosiveTypes;
	private _capacityPerType = _capacity / _allocations;

	private _itemMass = 0;
	{
		_itemMass = getNumber (configFile >> "CfgMagazines" >> _x >> "mass");
		_container addMagazineCargoGlobal [_x, floor (_capacityPerType / _itemMass)];
	} forEach _explosiveTypes;
};

OO_TRACE_DECL(SERVER_Supply_StockWeaponsContainer) =
{
	private _container = _this select 0;
	private _capacity = _this select 1;
	private _clear = _this select 2;

	if (_clear) then
	{
		[_container] call JB_fnc_clearVehicleInventory;
	};

	private _weaponTypes = ([] call compile preprocessFile "scripts\whitelistGear.sqf") select 0;

	private _basicTypes = [];
	{
		private _weaponType = _x;
		{
			if (_weaponType != _x && _weaponType isKindOf [_x, configFile >> "CfgWeapons"]) exitWith { _weaponType = "" };
		} forEach _weaponTypes;
		if (_weaponType != "") then
		{
			_basicTypes pushBack _weaponType;
		};
	} forEach _weaponTypes;

	private _irrelevantParents = ["Rifle_Base_F", "Rifle", "RifleCore", "Launcher_Base_F", "Launcher", "LauncherCore", "Pistol_Base_F", "Pistol", "PistolCore", "Default"];
	_basicTypes = _basicTypes apply
		{
			private _parents = ([configfile >> "CfgWeapons" >> _x, true] call BIS_fnc_returnParents) - _irrelevantParents;
			[_parents deleteAt 0, _parents]
		};

	for "_i" from count _basicTypes - 1 to 0 step -1 do
	{
		private _parentsI = (_basicTypes select _i) select 1;
		if (count _parentsI > 0) then
		{
			for "_j" from 0 to _i - 1 do
			{
				private _parentsJ = (_basicTypes select _j) select 1;
				private _uniqueParents = _parentsI - _parentsJ;
				if (count _uniqueParents == 0) exitWith
				{
					_basicTypes set [_i, []];
				};
			};
		};
	};

	private _weaponMass = 0;

	_basicTypes = _basicTypes apply
	{
		_weaponMass = getNumber (configFile >> "CfgWeapons" >> (_x select 0) >> "WeaponSlotsInfo" >> "mass");
		if (isNil "_weaponMass" || { _weaponMass == 0 }) then { [] } else { [_x select 0, _weaponMass] }
	};

	_basicTypes = _basicTypes select { count _x > 0 };

	private _allocations = count _basicTypes;
	private _capacityPerType = _capacity / _allocations;

	{
		_container addWeaponCargoGlobal [_x select 0, (floor (_capacityPerType / (_x select 1))) max 1];
	} forEach _basicTypes;
};

OO_TRACE_DECL(SERVER_Supply_StockStaticWeaponsContainer) =
{
	private _container = _this select 0;
	private _capacity = _this select 1;
	private _clear = _this select 2;

	if (_clear) then
	{
		[_container] call JB_fnc_clearVehicleInventory;
	};

	private _backpackTypes = ([] call compile preprocessFile "scripts\whitelistGear.sqf") select 1;
	
	private _weaponTypes = _backpackTypes select { getText (configFile >> "CfgVehicles" >> _x >> "assembleInfo" >> "assembleTo") != "" && { toLower (getText (configFile >> "CfgVehicles" >> _x >> "displayName")) find "mortar" == -1 } };

	private _assembledTypes = _weaponTypes apply { getText (configFile >> "CfgVehicles" >> _x >> "assembleInfo" >> "assembleTo") };
	private _componentTypes = _assembledTypes apply { getArray (configFile >> "CfgVehicles" >> _x >> "assembleInfo" >> "dissasembleTo") };

	private _staticTypes = [];
	{
		{
			_staticTypes pushBackUnique _x;
		} forEach _x;
	} forEach _componentTypes;

	private _allocations = count _staticTypes;
	private _capacityPerType = _capacity / _allocations;

	{
		_backpackMass = getNumber (configFile >> "CfgVehicles" >> _x >> "mass");
		_container addBackpackCargoGlobal [_x, (floor (_capacityPerType / _backpackMass)) max 1];
	} forEach _staticTypes;
};

OO_TRACE_DECL(SERVER_Supply_StockMortarsContainer) =
{
	private _container = _this select 0;
	private _capacity = _this select 1;
	private _clear = _this select 2;

	if (_clear) then
	{
		[_container] call JB_fnc_clearVehicleInventory;
	};

	private _backpackTypes = ([] call compile preprocessFile "scripts\whitelistGear.sqf") select 1;
	
	private _mortarTypes = _backpackTypes select { toLower (getText (configFile >> "CfgVehicles" >> _x >> "displayName")) find "mortar" >= 0 };

	_mortarTypes = _mortarTypes apply { [_x, getNumber (configFile >> "CfgVehicles" >> _x >> "mass")] };

	private _index = 0;
	while { _capacity > 0 } do
	{
		_container addBackpackCargoGlobal [_mortarTypes select _index select 0, 1];
		_capacity = _capacity - (_mortarTypes select _index select 1);
		_index = (_index + 1) mod (count _mortarTypes);
	};
};

OO_TRACE_DECL(SERVER_Supply_StockItemsContainer) =
{
	private _container = _this select 0;
	private _capacity = _this select 1;
	private _clear = _this select 2;

	if (_clear) then
	{
		[_container] call JB_fnc_clearVehicleInventory;
	};

	private _itemTypes = ([] call compile preprocessFile "scripts\whitelistGear.sqf") select 2;

	_itemTypes = _itemTypes select { getText (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "uniformModel") == "" && { getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass") != 0 } };
	
	private _allocations = count _itemTypes;
	private _capacityPerType = _capacity / _allocations;

	{
		_itemMass = getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass");
		if (_itemMass != 0) then
		{
			_container addItemCargoGlobal [_x, (floor (_capacityPerType / _itemMass)) max 1];
		};
	} forEach _itemTypes;
};

SERVER_Tracking_AirWithinRange =
{
	params ["_unit", "_range"];

	private _aircraft = _unit nearEntities ["Air", _range];

	_aircraft = _aircraft select { alive _x && { not isPlayer driver _x } && { (getPosATL _x) select 2 > 10 } && { not (_x isKindOf "ParachuteBase") } };

	if (count _aircraft == 0) exitWith { [] };

	_aircraft = _aircraft apply { [speed _x, _x] };
	_aircraft sort true;
	_aircraft = _aircraft apply { _x select 1 };

	_aircraft
};

SERVER_Tracking_AirWithin1000 =
{
	params ["_unit"];

	([_unit, 1000] call SERVER_Tracking_AirWithinRange)
};

SERVER_Tracking_AirWithin3500 =
{
	params ["_unit"];

	([_unit, 3500] call SERVER_Tracking_AirWithinRange)
};

SERVER_Tracking_AirWithin5000 =
{
	params ["_unit"];

	([_unit, 5000] call SERVER_Tracking_AirWithinRange)
};

SERVER_SpecialOperationsRewards =
[
	[
		25, ["a Qilin (armed)", "O_LSV_02_armed_F", {}],
		15, ["an Ifrit HMG", "O_MRAP_02_hmg_F", {}],
		15, ["a Strider HMG", "I_MRAP_03_hmg_F", {}],
		 5, ["an FV-720 Mora", "I_APC_tracked_03_cannon_F", {}],
		 5, ["an MSE-3 Marid", "O_APC_Wheeled_02_rcws_F", {}]
	]
];

OO_TRACE_DECL(SERVER_InitializeObject_SpecialOperation_Civilian) =
{
	params ["_category", "_group"];
	
	_group allowFleeing 1.0;

	private _armedProbability = 0.01;

	private _area = OO_GET(_category,ForceCategory,Area);
	if (not OO_ISNULL(_area)) then
	{
		private _location = [] call OO_METHOD(_area,StrongpointArea,GetNearestLocation);
		_armedProbability = if (type _location == "NameVillage") then { 0.20 } else { 0.01 };
	};

	private _armedTypes = ["I_C_Soldier_Bandit_1_F", "I_C_Soldier_Bandit_4_F", "I_C_Soldier_Bandit_7_F", "I_C_Soldier_Bandit_8_F"];

	{
		if (random 1 < _armedProbability) then
		{
			_x setUnitLoadout (getUnitLoadout selectRandom _armedTypes);
		};
	} forEach units _group;
};

OO_TRACE_DECL(SERVER_InitializeObject_SpecialOperation_East) =
{
	params ["_category", "_group"];

	_group allowFleeing 0.0;

	{
		_x setSkill ["aimingAccuracy", 0.25];
		_x setSkill ["aimingShake", 0.65];
		_x setSkill ["aimingSpeed", 0.40];

		_x setSkill ["spotDistance", 0.75];
		_x setSkill ["spotTime", 0.60];

		[_x] call JB_fnc_downgradeATEquipment;
	} forEach units _group;
};

OO_TRACE_DECL(SERVER_InitializeObject_SpecialOperation_Syndikat) =
{
	params ["_category", "_group"];

	_group allowFleeing 0.5;

	{
		_x setSkill ["aimingAccuracy", 0.05];
		_x setSkill ["aimingShake", 0.35];
		_x setSkill ["aimingSpeed", 0.20];
		_x setSkill ["spotDistance", 0.30];
		_x setSkill ["spotTime", 0.30];

		[_x] call JB_fnc_downgradeATEquipment;
	} forEach units _group;
};

OO_TRACE_DECL(SERVER_InitializeObject_SpecialOperation) =
{
	params ["_category", "_object"];

	if (typeName _object == typeName grpNull) then
	{
		private _group = _object;

		_group setSpeedMode "limited";
		_group setBehaviour "safe";
		_group setCombatMode "white";

		{
			_x setSkill ["commanding", 1];
			_x setSkill ["courage", 0.2 + random 0.8];
			_x setSkill ["endurance", 1];
			_x setSkill ["general", 1];
			_x setSkill ["reloadSpeed", 1];
		} forEach units _group;

		switch (side _group) do
		{
			case civilian : { [_category, _group] call SERVER_InitializeObject_SpecialOperation_Civilian; };
			case independent : { [_category, _group] call SERVER_InitializeObject_SpecialOperation_Syndikat; };
			case east : { [_category, _group] call SERVER_InitializeObject_SpecialOperation_East; };
		};
	};
};

OO_TRACE_DECL(SERVER_InitializeObject_Counterattack) =
{
	params ["_category", "_object"];

	if (typeName _object == typeName grpNull) then
	{
		_object allowFleeing 0.0;
		_object setSpeedMode "normal";
		_object setBehaviour "aware";
		_object setCombatMode "yellow";

		private _aimingAdjustment = 0.005 * ((count allPlayers - 20) max 0);
		{
			_x setSkill ["aimingAccuracy", 0.05 + _aimingAdjustment];
			_x setSkill ["aimingShake", 0.05 + _aimingAdjustment];
			_x setSkill ["aimingSpeed", 0.05 + _aimingAdjustment];

			_x setSkill ["spotDistance", 0.75];
			_x setSkill ["spotTime", 0.60];

			_x setSkill ["commanding", 1];
			_x setSkill ["courage", 1];
			_x setSkill ["endurance", 1];
			_x setSkill ["general", 1];
			_x setSkill ["reloadSpeed", 1];

			[_x] call JB_fnc_downgradeATEquipment;
		} forEach units _object;
	};

	if (typeName _object == typeName objNull) then
	{
		// Prevent air crews from ejecting
		if (_object isKindOf "Air") then
		{
			_object allowCrewInImmobile true;
		};
	};
};

OO_TRACE_DECL(SERVER_InitializeObject) =
{
	params ["_category", "_object"];

	if (typeName _object == typeName objNull) then
	{
		_object lock 3;
		[_object] call JB_fnc_downgradeATInventory;
	};

	private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
	private _name = OO_GET(_strongpoint,Strongpoint,Name);

	switch (_name) do
	{
		case "MainOperation-Counterattack":
		{
			[_category, _object] call SERVER_InitializeObject_Counterattack;
		};

		case "SpecialOperation":
		{
			[_category, _object] call SERVER_InitializeObject_SpecialOperation;
		};
	}
};

OO_TRACE_DECL(SERVER_Ghosthawk_DoorManager) =
{
	params ["_vehicle"];

	private _doorsOpen = false;

	while { alive _vehicle } do
	{
		if (_doorsOpen) then
		{
			if ((getPosATL _vehicle) select 2 > 25 || speed _vehicle > 100) then
			{
				[_vehicle, ["Door_L", 0]] remoteExec ["animateDoor", 0];
				[_vehicle, ["Door_R", 0]] remoteExec ["animateDoor", 0];
				_doorsOpen = false;
			}
		}
		else
		{
			if ((getPosATL _vehicle) select 2 < 10 && speed _vehicle < 40) then
			{
				[_vehicle, ["Door_L", 1]] remoteExec ["animateDoor", 0];
				[_vehicle, ["Door_R", 1]] remoteExec ["animateDoor", 0];
				_doorsOpen = true;
			};
		};

		sleep 0.5;
	};

	if (alive _vehicle) then
	{
		[_vehicle] spawn SERVER_Ghosthawk_DoorManager;
	};
};