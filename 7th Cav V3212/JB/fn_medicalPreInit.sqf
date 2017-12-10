// Distance bodies are moved from a destroyed vehicle
#define DISTANCE_FROM_DESTROYED_VEHICLE 10
// Frequency of medic monitor basic updates (seconds)
#define MONITOR_POLL_INTERVAL 0.5
// Frequency of medic monitor full updates (seconds)
#define MONITOR_FULL_INTERVAL 3.0
// Distance monitor will detect medics (meters)
#define MONITOR_RANGE 500
// Number of medics monitor will list (count) - must be matched against UI design
#define MONITOR_NUMBER_MEDICS 5
// Maximum time to bleedout after being incapacitated (seconds)
#define MAX_BLEEDOUT_TIME 600
// Frequency of updates to the player's damage-based bleedout time (seconds)
#define BLEEDOUT_UPDATE_INTERVAL 3.0
// Distance at which medical assistance can be performed
#define MEDICAL_ACTION_DISTANCE_SQR 4
// The bleedout pace of an unstabilized wound
#define UNSTABILIZED_BLEEDOUT_PACE 1
// The bleedout pace of a stabilized wound
#define STABILIZED_BLEEDOUT_PACE 0.01
// The minimum time that an ambulance revive can take
#define MINIMUM_AMBULANCE_REVIVE_TIME 4
// The time it takes for an ambulance to stabilize a patient
#define AMBULANCE_STABILIZE_TIME 3

// Acts_CivilInjured* is a great series of downed animations specific to body parts
// Acts_Injured*Rifle01
// Acts_TreatingWounded*

JBM_R_ShowFriendlyFireWarning =
{
	titleText ["FRIENDLY FIRE", "BLACK IN", 3];
};

JBM_AmmoMagazineWeapon =
{
	private _ammo = _this select 0;
	private _weapons = _this select 1;

	private _weaponName = "";
	private _magazineName = "";

	scopeName "function";
	{
		_weapon = _x;
		{
			if (getText (configFile >> "CfgMagazines" >> _x >> "ammo") == _ammo) then
			{
				_magazineName = getText (configFile >> "CfgMagazines" >> _x >> "displayName");
				_weaponName = getText (configFile >> "CfgWeapons" >> _weapon >> "displayName");
				breakTo "function";
			};
		} forEach getArray (configFile >> "CfgWeapons" >> _x >> "magazines");
	} forEach _weapons;

	[_magazineName, _weaponName]
};

JBM_WeaponDescription =
{
	private _vehicle = _this select 0;
	private _gunner = _this select 1;
	private _ammo = _this select 2;

	private _magazineWeapon = ["", ""];

	if (_vehicle isKindOf "Man") then
	{
		_magazineWeapon = [_ammo, weapons _vehicle] call JBM_AmmoMagazineWeapon;
	}
	else
	{
		private _gunnerCrew = (fullCrew _vehicle) select { (_x select 0) == _gunner };
		if (count _gunnerCrew == 0) then
		{
			_magazineWeapon = [_ammo, weapons _vehicle] call JBM_AmmoMagazineWeapon;
		}
		else
		{
			// If _gunnerCrew select 0 select 4 is true, then it's a person shooting from a vehicle
			if (_gunnerCrew select 0 select 1 == "Turret" && (_gunnerCrew select 0 select 4)) then
			{
				_magazineWeapon = [_ammo, weapons (_gunnerCrew select 0 select 0)] call JBM_AmmoMagazineWeapon;
			}
			else
			{
				private _turret = _gunnerCrew select 0 select 3;
				_magazineWeapon = [_ammo, _vehicle weaponsTurret _turret] call JBM_AmmoMagazineWeapon;
			};
		};
	};

	(_magazineWeapon select 1) + " (loaded with " + (_magazineWeapon select 0) + ")";
};

JBM_SelectionDescription =
{
	private _selection = _this select 0;

	private _description = "";
	{
		if (getText (_x >> "name") == _selection) exitWith
		{
			_description = toLower ((configName _x) select [3]);
		};
	} forEach ("true" configClasses (configFile >> "CfgVehicles" >> "SoldierWB" >> "HitPoints"));

	_description;
};

JBM_DirectionDescription =
{
	private _wounded = _this select 0;
	private _source = _this select 1;

	private _direction = (_wounded getRelDir _source) / 45.0;

	["the front", "the right", "the right", "behind", "behind", "the left", "the left", "the front"] select (floor _direction);
};

JBM_ShooterDescription =
{
	private _source = _this select 0;
	private _instigator = _this select 1;

	private _description = "";

	if (isNull _instigator) then
	{
		// Indirect damage
		if (isPlayer _source) then
		{
			_description = name _source;
		}
		else
		{
			if (side _source == west) then
			{
				private _unitType = getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName");
				_description = "a friendly " + _unitType;
			}
			else
			{
				private _unitType = getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName");
				_description = "an enemy " + _unitType;
			};
		}
	}
	else
	{
		// Direct damage
		if (isPlayer _instigator) then
		{
			if (_source isKindOf "Man") then
			{
				_description = name _instigator;
			}
			else
			{
				private _vehicleType = getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName");
				_description = name _instigator + " using a " + _vehicleType;
			};
		}
		else
		{
			private _vehicleType = getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName");
			_description = "an enemy " + _vehicleType;
		};
	};

	_description;
};

JBM_HandleDamage =
{
	private _wounded = param [0, objNull, [objNull]];
	private _selection = param [1, "", [""]];
	private _damage = param [2, 0, [0]];
	private _source = param [3, objNull, [objNull]];
	private _projectile = param [4, "", [""]];
	private _partIndex = param [5, 0, [0]];
	private _instigator = param [6, objNull, [objNull]];
	
	player setVariable ["JBM_Stabilized", nil, true];
	player setVariable ["JBM_Rewounded", true];

	private _friendlyFire = (side _source == side _wounded) && { isPlayer _source } && { _source != _wounded } && { lifeState _wounded != "DEAD-RESPAWN" };

	if (_friendlyFire) then
	{
		[] remoteExec ["JBM_R_ShowFriendlyFireWarning", _instigator];
	};

	if (_wounded getVariable ["JBM_Incapacitated", false]) then
	{
		_damage = _damage min 0.9;
	}
	else
	{
		private _incapacitate = false;

		if (_partIndex == -1) then
		{
			_incapacitate = (_damage > 0.9);
			_damage = _damage min 0.9;
		}
		else
		{
			if (_damage > 0.9) then
			{
				_damage = 0.9;
				if (!(_selection in ["arms", "legs", "hands"])) then
				{
					_incapacitate = true;
				};
			};
		};

		if (_incapacitate) then
		{
			_wounded setVariable ["JBM_Incapacitated", true];

			[_wounded, _selection, _source, _projectile, _instigator] spawn
			{
				private _wounded = _this select 0;
				private _selection = _this select 1;
				private _source = _this select 2;
				private _projectile = _this select 3;
				private _instigator = _this select 4;

				if (isNull _source) then
				{
					systemchat format ["You were incapacitated by a series of unfortunate events"];
				}
				else
				{
					private _locationDescription = if (_selection == "") then { " by a hit" } else { " by a hit to the " + ([_selection] call JBM_SelectionDescription) };
					private _directionDescription = " from " + ([_wounded, _source] call JBM_DirectionDescription);
					private _shooterDescription = " by " + ([_source, _instigator] call JBM_ShooterDescription);

					private _sourceDescription = "";
					if (_projectile != "") then
					{
						_shooterDescription = _shooterDescription + "'s " + ([_source, _instigator, _projectile] call JBM_WeaponDescription);
					};

					systemchat format ["You were incapacitated%1%2%3", _locationDescription, _directionDescription, _shooterDescription];
				};
			};

			private _friendlyFireMessage = if (not _friendlyFire) then { "" } else { format [" (friendly fire from %1)", [_source, _instigator] call JBM_ShooterDescription] };
			(format ["%1 is down and needs a medic%2", name _wounded, _friendlyFireMessage]) remoteExec ["systemChat", 0];
			
			private _woundedVehicle = vehicle _wounded;
			if (_woundedVehicle == _wounded) then
			{
				[_wounded] call JBM_Incapacitate; // On foot
			}
			else
			{
				if (not alive _woundedVehicle || typeOf _woundedVehicle isKindOf "StaticWeapon") then
				{
					moveOut _wounded; // In destroyed vehicle or static weapon

					[_wounded] call JBM_Incapacitate;

					if (not (typeOf _woundedVehicle isKindOf "StaticWeapon")) then
					{
						private _away = (getPos _wounded) vectorDiff (getPos _woundedVehicle);
						private _distanceAway = vectorMagnitude _away;
						if (_distanceAway < DISTANCE_FROM_DESTROYED_VEHICLE) then
						{
							_away = _away vectorMultiply (DISTANCE_FROM_DESTROYED_VEHICLE / _distanceAway);
							_wounded setPos ((getPos _wounded) vectorAdd _away);
						};
					};
				}
				else
				{
					[_wounded] call JBM_Incapacitate; // In intact vehicle
					[_wounded, "unconscious"] remoteExec ["playMoveNow"];
				};
			};
		};
	};

	_damage;
};

JBM_IncapacitateDriver =
{
	private _wounded = _this select 0;

	private _vehicle = vehicle _wounded;

	moveOut _wounded;
	sleep 0.2;

	{
		if (isNull (_x select 0) && (_x select 1) != "driver") exitWith
		{
			switch (_x select 1) do
			{
				case "gunner":
				{
					_wounded moveInGunner _vehicle;
				};
				case "commander":
				{
					_wounded moveInCommander _vehicle;
				};
				case "Turret":
				{
					_wounded moveInTurret [_vehicle, _x select 3];
				};
				case "cargo":
				{
					_wounded moveInCargo _vehicle;
				};
			}
		};
	} forEach fullCrew [_vehicle, "", true];

	_wounded setUnconscious true;
	_wounded setCaptive true;

	[] spawn JBM_MedicMonitor;
};

JBM_Incapacitate =
{
	private _wounded = _this select 0;

	private _vehicle = vehicle _wounded;
	if (_wounded == driver _vehicle && _vehicle != _wounded) then
	{
		[_wounded] spawn JBM_IncapacitateDriver;
	}
	else
	{
		_wounded setUnconscious true;
		_wounded setCaptive true;

		[] spawn JBM_MedicMonitor;
	};
};

JBM_NearbyMedics =
{
	private _wounded = _this select 0;
	private _range = _this select 1;

	private _medics = [];
	{
		{
			if (_x != _wounded && { _x getUnitTrait "medic" } && { isPlayer _x }) then { _medics pushBack _x };
		} forEach crew _x;
	} forEach (nearestObjects [_wounded, ["AllVehicles"], _range, false]);

	_medics;
};

JBM_HideMedicMonitor =
{
	"JBM_MedicMonitorLayer" cutText ["", "PLAIN"];

	player setUserActionText [JBM_MedicMonitorAction, "Show medic list"];

	JBM_MedicMonitorFields = [];
};

JBM_ShowMedicMonitor =
{
	"JBM_MedicMonitorLayer" cutRsc ["JBM_MedicMonitor", "PLAIN"];
	disableSerialization;

	private _medicMonitor = uiNamespace getVariable "JBM_MedicMonitor";

	_medicList = _medicMonitor displayCtrl 1200;
	_additionalInformation = _medicMonitor displayCtrl 1300;
	_bleedoutDisplay = _medicMonitor displayCtrl 1400;

	player setUserActionText [JBM_MedicMonitorAction, "Hide medic list"];

	JBM_MedicMonitorFields = [_medicList, _additionalInformation, _bleedoutDisplay];

	[0] call JBM_UpdateMedicMonitor;
};

JBM_ToggleMedicMonitor =
{
	if (count JBM_MedicMonitorFields > 0) then
	{
		[] call JBM_HideMedicMonitor;
	}
	else
	{
		[] call JBM_ShowMedicMonitor;
	};
};

JBM_UpdateMedicMonitor =
{
	private _bleedoutTime = _this select 0;

	private _medicList = JBM_MedicMonitorFields select 0;
	private _additionalInformation = JBM_MedicMonitorFields select 1;
	private _bleedoutDisplay = JBM_MedicMonitorFields select 2;

	_bleedoutDisplay ctrlSetText str round (_bleedoutTime max 0);

	if ((round _bleedoutTime) mod MONITOR_FULL_INTERVAL == 0) then
	{
		private _medics = [player, MONITOR_RANGE] call JBM_NearbyMedics;

		lbClear _medicList;

		private _numberMedics = 0;
		{
			if (lifeState _x != "DEAD" && { _x != player }) then
			{
				_numberMedics = _numberMedics + 1;

				if (_forEachIndex < MONITOR_NUMBER_MEDICS) then
				{
					_medicList lnbAddRow [name _x, format ["%1m", round (player distance _x)], format ["%1", lifeState _x]];
				};
			};
		} forEach _medics;

		private _message = "";

		if (_numberMedics == 0) then
		{
			_message = format ["No medics within %1 meters", MONITOR_RANGE];
		}
		else
		{
			private _extraMedics = _numberMedics - MONITOR_NUMBER_MEDICS;
			if (_extraMedics > 0) then
			{
				_message = format ["%1 other medics not listed", _extraMedics];
			};
		};

		_additionalInformation ctrlSetText _message;
	};
};

JBM_ComputeBleedoutTime =
{
	private _selections = (getAllHitPointsDamage player) select 2;
	private _timePerSelection = MAX_BLEEDOUT_TIME / (count _selections);
	private _bleedoutTime = 0;
	{
		_bleedoutTime = _bleedoutTime + ((1.0 - _x) * _timePerSelection);
	} forEach _selections;

	_bleedoutTime;
};

JBM_MedicMonitor =
{
	private _bleedoutTime = [] call JBM_ComputeBleedoutTime;
	private _bleedoutCountdown = _bleedoutTime;

	JBM_MedicMonitorFields = [];
	if (not isNil "JBM_MedicMonitorAction") then { diag_log "JBM_MedicMonitor: a non-nil JBM_MedicMonitorAction value is being overwritten." };
	JBM_MedicMonitorAction = player addAction ["Toggle medic list", { [] call JBM_ToggleMedicMonitor; }, nil, 0, false, true, "", "", -1, true];
	private _respawnAction = player addAction ["Respawn", { player setDamage 1 }, nil, 0, false, true, "", "", -1, true];

	[] call JBM_ShowMedicMonitor;

	while { lifeState player == "INCAPACITATED" } do
	{
		// Negative bleedout countdown possible when already waiting for a time, then taking more damage
		if (round _bleedoutCountdown <= 0) then
		{
			player setDamage 1;
		};

		if (count JBM_MedicMonitorFields > 0) then
		{
			[_bleedoutCountdown] call JBM_UpdateMedicMonitor;
		};

		sleep MONITOR_POLL_INTERVAL;

		// If the player has taken more damage, shorten the bleedout time appropriately and destabilize the patient
		if (player getVariable ["JBM_Rewounded", false]) then
		{
			private _bleedoutTimeUpdated = [] call JBM_ComputeBleedoutTime;
			_bleedoutCountdown = _bleedoutCountdown - (_bleedoutTime - _bleedoutTimeUpdated);
			_bleedoutTime = _bleedoutTimeUpdated;

			player setVariable ["JBM_Rewounded", nil];
		};

		private _pace = if (player getVariable ["JBM_Stabilized", false]) then { STABILIZED_BLEEDOUT_PACE } else { UNSTABILIZED_BLEEDOUT_PACE };
		_bleedoutCountdown = _bleedoutCountdown - MONITOR_POLL_INTERVAL * _pace;

		player setVariable ["JBM_BleedoutCountdown", _bleedoutCountdown];
	};

	player removeAction JBM_MedicMonitorAction;
	player removeAction _respawnAction;

	[] call JBM_HideMedicMonitor;

	JBM_MedicMonitorFields = nil;
	JBM_MedicMonitorAction = nil;
};

JBM_Respawned =
{
	player setCaptive false;

	player setVariable ["JBM_Incapacitated", nil];
	player setVariable ["JBM_Stabilized", nil, true];
	player setVariable ["JBM_Rewounded", nil];
	player setVariable ["JBM_BleedoutCountdown", nil];

	[] call JBM_SetupActions;
};

JBM_Killed =
{
	detach player;

	player setVariable ["JBM_Incapacitated", nil];
	player setVariable ["JBM_Stabilized", nil, true];
	player setVariable ["JBM_Rewounded", nil];
	player setVariable ["JBM_BleedoutCountdown", nil];
};

JBM_FirstAidKitAvailable =
{
	private _unit = _this select 0;

	if ("FirstAidKit" in backpackItems _unit) exitwith { true };
	if ("FirstAidKit" in vestItems _unit) exitwith { true };
	if ("FirstAidKit" in uniformItems _unit) exitwith { true };

	false
};

JBM_ConsumeFirstAidKit =
{
	private _unit = _this select 0;

	if ("FirstAidKit" in backpackItems _unit) exitwith { _unit removeItemFromBackpack "FirstAidKit"; true };
	if ("FirstAidKit" in vestItems _unit) exitwith { _unit removeItemFromVest "FirstAidKit"; true };
	if ("FirstAidKit" in uniformItems _unit) exitwith { _unit removeItemFromUniform "FirstAidKit"; true };

	false
};

JBM_ConsumeAmbulanceFirstAidKit =
{
	private _ambulance = _this select 0;

	private _itemCargo = getItemCargo _ambulance;
	private _itemNames = _itemCargo select 0;
	private _itemCounts = _itemCargo select 1;

	private _firstAidKitIndex = _itemNames find "FirstAidKit";

	if (_firstAidKitIndex == -1) exitWith { false };

	private _firstAidKitCount = _itemCounts select _firstAidKitIndex;
	_itemCounts set [_firstAidKitIndex, _firstAidKitCount - 1];

	clearItemCargoGlobal _ambulance;
	for "_i" from 0 to (count _itemNames) - 1 do
	{
		_ambulance addItemCargoGlobal [_itemNames select _i, _itemCounts select _i];
	};

	true
};

JBM_AmbulanceRevive =
{
	private _ambulance = _this select 0;
	private _wounded = _this select 1;

	private _usedAmbulanceFirstAidKit = false;

	private _reviveTime = _ambulance getVariable "JBM_AmbulanceReviveTime";
	if (isNil "_reviveTime") exitWith {};

	private _bleedoutCountdown = _wounded getVariable "JBM_BleedoutCountdown";
	if (isNil "_bleedoutCountdown") exitWith {};

	_reviveTime = (_reviveTime * (1 - (_bleedoutCountdown / MAX_BLEEDOUT_TIME))) max MINIMUM_AMBULANCE_REVIVE_TIME;

	if (_bleedoutCountdown < AMBULANCE_STABILIZE_TIME min _reviveTime) exitWith
	{
		"Your condition is too critical.  There's nothing that can be done." remoteExec ["systemchat", _wounded];
	};

	if (AMBULANCE_STABILIZE_TIME < _reviveTime && _bleedoutCountdown < _reviveTime && not (player getVariable ["JBM_Stabilized", false])) then
	{
		_usedAmbulanceFirstAidKit = [_ambulance] call JBM_ConsumeAmbulanceFirstAidKit;
		if (not _usedAmbulanceFirstAidKit && not ([player] call JBM_FirstAidKitAvailable)) exitWith
		{
			"You cannot be stabilized because neither you nor the vehicle has a first aid kit." remoteExec ["systemchat", _wounded];
		};

		"Stabilizing critically-wounded patient..." remoteExec ["systemchat", _wounded];
		sleep AMBULANCE_STABILIZE_TIME;
		if (alive _ambulance && vehicle _wounded == _ambulance && lifeState _wounded == "INCAPACITATED") then
		{
			[_ambulance, _usedAmbulanceFirstAidKit] remoteExec ["JBM_R_HaveBeenStabilized", _wounded];
		};
	};

	if (not alive _ambulance || vehicle _wounded != _ambulance || lifeState _wounded != "INCAPACITATED") exitWith {};

	_usedAmbulanceFirstAidKit = [_ambulance] call JBM_ConsumeAmbulanceFirstAidKit;
	if (not _usedAmbulanceFirstAidKit && not ([player] call JBM_FirstAidKitAvailable)) exitWith
	{
		"You cannot be revived because neither you nor the vehicle has a first aid kit." remoteExec ["systemchat", _wounded];
	};

	"Reviving wounded patient..." remoteExec ["systemchat", _wounded];

	sleep _reviveTime;

	if (not alive _ambulance || lifeState _wounded != "INCAPACITATED" || vehicle _wounded != _ambulance) exitWith {};

	[_ambulance, _usedAmbulanceFirstAidKit] remoteExec ["JBM_R_HaveBeenRevived", _wounded];
};

JBM_C_AmbulanceSetupClient =
{
	private _ambulance = _this select 0;
	private _reviveTime = _this select 1;

	_ambulance setVariable ["JBM_AmbulanceReviveTime", _reviveTime];

	_ambulance addEventHandler ["GetIn",
		{
			private _ambulance = _this select 0;
			private _position = _this select 1;
			private _wounded = _this select 2;

			if (_position != "cargo") exitWith {};

			if (lifeState _wounded != "INCAPACITATED") exitWith {};

			[_ambulance, _wounded] spawn JBM_AmbulanceRevive;
		}];
};

JBM_R_HaveBeenRevived =
{
	_this spawn
	{
		private _medic = _this select 0;
		private _usedMedicFirstAidKit = _this select 1;

		if (lifeState player != "INCAPACITATED") exitWith { };

		player setDamage 0;
		player setUnconscious false;
		player setCaptive false;
		detach player;
		player setVariable ["JBM_Incapacitated", nil];
		player setVariable ["JBM_Stabilized", nil, true];
		player setVariable ["JBM_Rewounded", nil];
		player setVariable ["JBM_BleedoutCountdown", nil];
		waitUntil { lifeState player != "INCAPACITATED" };

		if (not _usedMedicFirstAidKit) then
		{
			[player] call JBM_ConsumeFirstAidKit;
		};

		player playMoveNow "AmovPpneMstpSnonWnonDnon"; // Roll prone
	};
};

JBM_ReviveWoundedCondition =
{
	private _wounded = _this select 0;

	if (lifeState _wounded != "INCAPACITATED") exitWith { false };

	if (vehicle player != player) exitWith { false };

	if (not isPlayer _wounded) exitWith { false };

	if (player distanceSqr _wounded > MEDICAL_ACTION_DISTANCE_SQR) exitWith { false };

	if (not isNull attachedTo _wounded) exitWith { false };

	if ([animationState player, ["cin", "inv"]] call JB_fnc_matchAnimationState) exitWith { false };

	true
};

JBM_ReviveWounded =
{
	private _wounded = param [0, objNull, [objNull]];

	_wounded setVariable ["JBM_ManuallyLoadedIntoVehicle", nil, true];

	if (not ([player] call JBM_FirstAidKitAvailable) && { not ([_wounded] call JBM_FirstAidKitAvailable) }) exitWith { titleText ["A first aid kit is required to revive wounded soldiers", "BLACK IN", 3]; };

	private _entryAnimation = animationState player;

	player playAction "medicother";

	[{ not (lifeState player in ["INJURED", "HEALTHY"]) || lifeState _wounded != "INCAPACITATED" }, 7.533] call JB_fnc_timeoutWaitUntil;

	[player, [player] call JBM_ConsumeFirstAidKit] remoteExec ["JBM_R_HaveBeenRevived", _wounded, false];

	player playMoveNow _entryAnimation;
};

JBM_R_HaveBeenStabilized =
{
	_this spawn
	{
		private _medic = _this select 0;
		private _usedMedicFirstAidKit = _this select 1;

		if (lifeState player != "INCAPACITATED") exitWith { };

		player setVariable ["JBM_Stabilized", true, true];

		if (not _usedMedicFirstAidKit) then
		{
			[player] call JBM_ConsumeFirstAidKit;
		};
	};
};

JBM_StabilizeWoundedCondition =
{
	private _wounded = _this select 0;

	if (lifeState _wounded != "INCAPACITATED") exitWith { false };

	if ((_wounded getVariable ["JBM_Stabilized", false])) exitWith { false };

	if (vehicle player != player) exitWith { false };

	if (not isPlayer _wounded) exitWith { false };

	if (player distanceSqr _wounded > MEDICAL_ACTION_DISTANCE_SQR) exitWith { false };

	if (not isNull attachedTo _wounded) exitWith { false };

	if ([animationState player, ["cin", "inv"]] call JB_fnc_matchAnimationState) exitWith { false };

	true
};

JBM_StabilizeWounded =
{
	private _wounded = param [0, objNull, [objNull]];

	_wounded setVariable ["JBM_ManuallyLoadedIntoVehicle", nil, true];

	if (not ([player] call JBM_FirstAidKitAvailable) && { not ([_wounded] call JBM_FirstAidKitAvailable) }) exitWith { titleText ["A first aid kit is required to stabilize wounded soldiers", "BLACK IN", 3]; };

	private _entryAnimation = animationState player;

	player playAction "medicother";

	[{ not (lifeState player in ["INJURED", "HEALTHY"]) || lifeState _wounded != "INCAPACITATED" }, 7.533] call JB_fnc_timeoutWaitUntil;

	[player, [player] call JBM_ConsumeFirstAidKit] remoteExec ["JBM_R_HaveBeenStabilized", _wounded];

	player playMoveNow _entryAnimation;
};

JBM_GetMedicDragExitAnimation =
{
	private _medic = _this select 0;

	private _medicAnimation = "";
	switch ([animationState _medic, "W"] call JB_fnc_getAnimationState) do
	{
		case "rfl" : { _medicAnimation = "AmovPknlMstpSlowWrflDnon"; };
		case "pst" : { _medicAnimation = "AmovPknlMstpSlowWpstDnon"; };
		default		 { _medicAnimation = "AmovPknlMstpSnonWnonDnon"; };
	};
	_medicAnimation;
};

JBM_GetMedicCarryExitAnimation =
{
	private _medic = _this select 0;

	private _medicAnimation = "";
	switch ([animationState _medic, "W"] call JB_fnc_getAnimationState) do
	{
		case "rfl" : { _medicAnimation = "AidlPknlMstpSlowWrflDnon_AI"; };
		case "pst" : { _medicAnimation = "AidlPknlMstpSlowWpstDnon_AI"; };
		case "non" : { _medicAnimation = "AidlPknlMstpSnonWnonDnon_AI"; }; //BUG: plays move
	};

	_medicAnimation;
};

JBM_MovingIncapacitated =
{
	private _movingIncapacitated = objNull;
	{
		if (_x isKindOf "Man" && { lifeState _x == "INCAPACITATED" }) exitWith { _movingIncapacitated = _x; };
	} forEach attachedObjects player;

	_movingIncapacitated;
};

JBM_SetDownWoundedCondition =
{
	private _movingIncapacitated = ([] call JBM_MovingIncapacitated);

	// If we notice that the player is stuck in the carry animation but doesn't have anyone to carry, break out 
	if (isNull _movingIncapacitated && { [animationState player, 'cin'] call JB_fnc_matchAnimationState }) then
	{
		player switchMove "";
	};

	not isNull _movingIncapacitated;
};

JBM_SetDownWounded =
{
	private _medic = player;
	private _wounded = ([] call JBM_MovingIncapacitated);

	if ([animationState _medic, 'cin', 'knl'] call JB_fnc_matchAnimationState) then
	{
		[_medic, _wounded] remoteExec ["JBM_R_StopDrag"];
	}
	else
	{
		// Carry set down
		private _medicAnimation = [_medic] call JBM_GetMedicCarryExitAnimation;

		[_medic, _wounded, _medicAnimation] remoteExec ["JBM_R_StopCarry"];
	};
};

JBM_DragWoundedCondition =
{
	private _wounded = _this select 0;

	if ([animationState player, 'cin'] call JB_fnc_matchAnimationState) exitWith { false };

	if ((player distanceSqr _wounded) > MEDICAL_ACTION_DISTANCE_SQR) exitWith { false };

	if (vehicle player != player) exitWith { false };

	if (lifeState _wounded != 'INCAPACITATED') exitWith { false };

	if (not isNull attachedTo _wounded) exitWith { false };

	if ([animationState player, ["cin", "inv"]] call JB_fnc_matchAnimationState) exitWith { false };

	true;
};

JBM_R_StartDrag =
{
	private _medic = _this select 0;
	private _wounded = _this select 1;

	if (local _wounded) then
	{
		_wounded attachTo [_medic, [0, 1.3, 0.0]];
		_wounded setDir 180;
	};

	_medic playAction "grabdrag";
};

JBM_R_StopDrag =
{
	private _medic = _this select 0;
	private _wounded = _this select 1;

	_medic playAction "released";

	if (local _wounded) then
	{
		detach _wounded;
	};
};

JBM_DragWounded =
{
	_this spawn
	{
		private _medic = player;
		private _wounded = param [0, objNull, [objNull]];

		_wounded setVariable ["JBM_ManuallyLoadedIntoVehicle", nil, true];

		[_medic, _wounded] remoteExec ["JBM_R_StartDrag"];

		// Wait until in drag animation
		waitUntil { [animationState _medic, "cin", "knl"] call JB_fnc_matchAnimationState || { !(lifeState _medic in ["HEALTHY", "INJURED"]) } };

		if ([animationState _medic, "cin", "knl"] call JB_fnc_matchAnimationState) then
		{
			waitUntil { sleep 0.2; !([animationState _medic, "cin", "knl"] call JB_fnc_matchAnimationState) || { !(lifeState _medic in ["HEALTHY", "INJURED"]) } || { lifeState _wounded != "INCAPACITATED" } };
		};

		// If we're left dragging, get out of it
		if ([animationState _medic, "cin", "knl"] call JB_fnc_matchAnimationState) then
		{
			_medic playAction "released";
			[_medic, _wounded] remoteExec ["JBM_R_StopDrag"];
		};
	};
};

JBM_FrameNumber = 0;

JBM_VehiclePointsFrameNumber = 0;
JBM_VehiclePoints = [];

JBM_PointOccupants =
{
	private _point = _this select 0;

	private _name = _point select 0;
	private _vehicle = _point select 1;

	private _occupants = [];

	switch (typeName _name) do
	{
		case "ARRAY" :
		{
			private _turretPath = _name select 1;

			private _turrets = fullCrew [_vehicle, "", true];
			{
				if ((_x select 3) isEqualTo _turretPath) then
				{
					_occupants pushBack (_x select 0);
				};
			} forEach _turrets;
		};
		case "STRING" :
		{
			switch (_name) do
			{
				case "driver" :
				{
					_occupants pushBack (driver _vehicle);
				};
				case "commander" :
				{
					_occupants pushBack (commander _vehicle);
				};
				case "gunner" :
				{
					_occupants pushBack (gunner _vehicle);
				};
				case "codriver" :
				{
					// codriver: [is-codriver-a-cargo-position, index-of-cargo-position-for-codriver]
					private _codriver = getArray (configFile >> "CfgVehicles" >> typeOf _vehicle >> "cargoIsCoDriver");
					private _cargoIndex = if (_coDriver select 0 == 1) then { _codriver select 1 } else { 0 };
					_occupants pushBack ((fullCrew [_vehicle, "cargo", true]) select _cargoIndex select 0);
				};
				case "cargo" :
				{
					private _codriver = getArray (configFile >> "CfgVehicles" >> typeOf _vehicle >> "cargoIsCoDriver");
					{
						if (_coDriver select 0 == 0 || { _coDriver select 1 != _x select 2 }) then
						{
							_occupants pushBack (_x select 0);
						};
					} forEach fullCrew [_vehicle, "cargo", true];
				};
			};
		};
	};

	_occupants;
};

JBM_PointHasVacancies =
{
	private _point = _this select 0;

	private _occupants = [_point] call JBM_PointOccupants;

	private _hasVacancies = false;

	{
		if (isNull _x) exitWith { _hasVacancies = true };
	} forEach _occupants;

	_hasVacancies;
};

JBM_PointHasIncapacitated =
{
	private _point = _this select 0;

	private _occupants = [_point] call JBM_PointOccupants;

	private _hasIncapacitated = false;

	{
		if (!(isNull _x) && { lifeState _x == "INCAPACITATED" }) exitWith { _hasIncapacitated = true };
	} forEach _occupants;

	_hasIncapacitated;
};

JBM_SetupLoadAction =
{
	private _point = _this select 0;
	private _actionIndex = _this select 1;

	private _actionTitle = "";

	if ([_point] call JBM_PointHasVacancies) then
	{
		private _name = _point select 0;

		private _description = "";
		if (typeName _name == "ARRAY") then
		{
			_description = "as " + (_name select 0);
		}
		else // STRING
		{
			if (_name == "cargo") then
			{
				_description = "in back";
			}
			else
			{
				_description = "as " + _name;
			}
		};

		_actionTitle = format ["<t color=""#ED2744"">Load wounded %1</t>", _description];
	};

	private _action = JBM_LoadActions select _actionIndex;
	player setUserActionText [_action, _actionTitle];
};

JBM_SetupUnloadAction =
{
	private _point = _this select 0;
	private _actionIndex = _this select 1;

	private _actionTitle = "";

	if ([_point] call JBM_PointHasIncapacitated) then
	{
		private _name = _point select 0;

		private _description = "";
		if (typeName _name == "ARRAY") then
		{
			_description = "from " + (_name select 0);
		}
		else // STRING
		{
			if (_name == "cargo") then
			{
				_description = "from back";
			}
			else
			{
				_description = "from " + _name;
			}
		};

		_actionTitle = format ["<t color=""#ED2744"">Unload wounded %1</t>", _description];
	};

	private _action = JBM_UnloadActions select _actionIndex;
	player setUserActionText [_action, _actionTitle];
};

JBM_LocateVehiclePoints =
{
	JBM_VehiclePoints = [];

	private _candidates = nearestObjects [player, ["LandVehicle", "Air", "Ship"], 15]; // Allow for largest distance on vehicle from center to 'get in point'.

	{
		private _vehicle = _x;
		private _size = sizeOf (typeOf _vehicle);

		if (player distanceSqr _vehicle < _size * _size) then
		{
			private _stations = ["driver", "codriver", "gunner", "cargo", "turret"];

			{
				private _name = _x select 0;
				{
					if (count _x == 0 || { player distanceSqr (_x select 0) < 2.25 }) then
					{
						JBM_VehiclePoints pushBack [_name, _vehicle];
					};
				} forEach (_x select 1);
			} forEach ([_vehicle, _stations] call JB_fnc_getInPoints);
		};
	} forEach _candidates;
};

JBM_SetupLoadUnloadActions =
{
	[] call JBM_LocateVehiclePoints;

	private _actionIndex = 0;
	{
		[_x, _actionIndex] call JBM_SetupLoadAction;
		_actionIndex = _actionIndex + 1;
		if (_actionIndex == count JBM_LoadActions) exitWith {};
	} forEach JBM_VehiclePoints;

	for "_i" from _actionIndex to (count JBM_LoadActions) - 1 do
	{
		player setUserActionText [JBM_LoadActions select _i, ""];
	};

	_actionIndex = 0;
	{
		[_x, _actionIndex] call JBM_SetupUnloadAction;
		_actionIndex = _actionIndex + 1;
		if (_actionIndex == count JBM_UnloadActions) exitWith {};
	} forEach JBM_VehiclePoints;

	for "_i" from _actionIndex to (count JBM_UnloadActions) - 1 do
	{
		player setUserActionText [JBM_UnloadActions select _i, ""];
	};
};

JBM_LoadWoundedCondition =
{
	private _pointIndex = param [0, 0, [0]];

	if (!([animationState player, "cin"] call JB_fnc_matchAnimationState)) exitWith { false };

	if (JBM_VehiclePointsFrameNumber < JBM_FrameNumber) then
	{
		JBM_VehiclePointsFrameNumber = JBM_FrameNumber;
		[] call JBM_SetupLoadUnloadActions;
	};

	private _params = player actionParams (JBM_LoadActions select _pointIndex);

	if ((_params select 0) == "") exitWith { false };

	not isNull ([] call JBM_MovingIncapacitated)
};

JBM_R_LoadWounded =
{
	private _point = _this select 0;
	private _wounded = _this select 1;
	private _medic = _this select 2;
	private _medicAnimation = _this select 3;

	private _name = _point select 0;
	private _vehicle = _point select 1;

	if (local _wounded) then
	{
		_wounded setVariable ["JBM_ManuallyLoadedIntoVehicle", true, true];
		switch (typeName _name) do
		{
			case "ARRAY" :
			{
				_wounded moveInTurret [_vehicle, _name select 1];
			};
			case "STRING" :
			{
				switch (_name) do
				{
					case "driver" :
					{
						_wounded moveInDriver _vehicle;
					};
					case "commander" :
					{
						_wounded moveInCommander _vehicle;
					};
					case "gunner" :
					{
						_wounded moveInGunner _vehicle;
					};
					case "codriver" :
					{
						private _codriver = getArray (configFile >> "CfgVehicles" >> typeOf _vehicle >> "cargoIsCoDriver");
						private _cargoIndex = if (_coDriver select 0 == 1) then { _codriver select 1 } else { 0 };
						_wounded moveInCargo [_vehicle, _cargoIndex];
					};
					case "cargo" :
					{
						private _codriver = getArray (configFile >> "CfgVehicles" >> typeOf _vehicle >> "cargoIsCoDriver");
						{
							if (isNull (_x select 0) && ( _coDriver select 0 == 0 || { _coDriver select 1 != _x select 2 } )) exitWith
							{
								_wounded moveInCargo [_vehicle, _x select 2];
							};
						} forEach fullCrew [_vehicle, "cargo", true];
					};
				};
			};
		};
	};

	waitUntil { vehicle _wounded == _vehicle };
	_wounded playMoveNow "unconscious";

	_medic switchMove _medicAnimation;
};

JBM_LoadWounded =
{
	private _pointIndex = param [0, 0, [0]];

	private _point = JBM_VehiclePoints select _pointIndex;

	private _wounded = ([] call JBM_MovingIncapacitated);
	detach _wounded;

	private _medicAnimation = "";
	if ([animationState player, 'cin', 'knl'] call JB_fnc_matchAnimationState) then
	{
		_medicAnimation = [player] call JBM_GetMedicDragExitAnimation;
	}
	else
	{
		_medicAnimation = [player] call JBM_GetMedicCarryExitAnimation;
	};

	[_point, _wounded, player, _medicAnimation] remoteExec ["JBM_R_LoadWounded"];
};

JBM_R_StartCarry =
{
	_this spawn
	{
		private _medic = _this select 0;
		private _wounded = _this select 1;
		private _medicAnimation = _this select 2;

		if (not local _wounded) then
		{
			waitUntil { attachedTo _wounded == _medic };

			_wounded switchMove "AinjPfalMstpSnonWrflDf_carried"; // AinjPfalMstpSnonWnonDf_wounded_dead
			_medic switchMove _medicAnimation;
		}
		else
		{
			_wounded attachTo [_medic, [-0.15, 0.1, 0.0]];
			_wounded setdir 180;

			_wounded switchMove "AinjPfalMstpSnonWrflDf_carried"; // AinjPfalMstpSnonWnonDf_wounded_dead
			_medic switchMove _medicAnimation;
		};
	};
};

JBM_R_StopCarry =
{
	_this spawn
	{
		private _medic = _this select 0;
		private _wounded = _this select 1;
		private _medicAnimation = _this select 2;

		if (local _wounded) then
		{
			detach _wounded;
			_wounded setDir ((getDir _medic) + 90);
		};

		_medic switchMove _medicAnimation;
		_wounded switchMove "unconsciousrevivedefault";
	};
};

JBM_R_CarryWoundedSwitchMove =
{
	private _medic = _this select 0;
	private _wounded = _this select 1;
	private _medicAnimation = _this select 2;

	_medic switchMove _medicAnimation;
	_wounded switchMove "AinjPfalMstpSnonWrflDf_carried";
};

JBM_R_CarryWoundedFromVehicle =
{
	private _medic = _this select 0;
	private _wounded = _this select 1;
	private _medicAnimation = _this select 2;

	private _manuallyLoaded = _wounded getVariable ["JBM_ManuallyLoadedIntoVehicle", false];

	_wounded setUnconscious false;
	moveOut _wounded;
	_wounded setUnconscious true;

	waitUntil { vehicle _wounded == _wounded };

	if (_manuallyLoaded) then
	{
		_wounded setVariable ["JBM_ManuallyLoadedIntoVehicle", nil, true]; // public

		waitUntil { [animationState _wounded, "*", "erc"] call JB_fnc_matchAnimationState };

		_wounded attachTo [_medic, [-0.15, 0.1, 0.0]];
		_wounded setdir 180;

		[_medic, _wounded, _medicAnimation] remoteExec ["JBM_R_CarryWoundedSwitchMove"];
	};
};

JBM_CarryWoundedCondition =
{
	_this call JBM_DragWoundedCondition;
};

JBM_CarryWounded =
{
	_this spawn
	{
		private _wounded = param [0, objNull, [objNull]];

		private _medic = player;

		private _medicAnimation = "";
		switch (currentWeapon _medic) do
		{
			case (primaryWeapon _medic) : { _medicAnimation = "AcinPercMstpSrasWrflDnon"; };
			case (handgunWeapon _medic) : { _medicAnimation = "AcinPercMstpSnonWpstDnon"; };
			default						  { _medicAnimation = "AcinPercMstpSnonWnonDnon"; }; //BUG: Medic slides instead of walking
		};

		if (vehicle _wounded == _wounded) then
		{
			[_medic, _wounded, _medicAnimation] remoteExec ["JBM_R_StartCarry"];
		}
		else
		{
			[_medic, _wounded, _medicAnimation] remoteExec ["JBM_R_CarryWoundedFromVehicle", _wounded];
		};

		// Wait until in carry animation
		waitUntil { [animationState _medic, "cin", "erc"] call JB_fnc_matchAnimationState || { !(lifeState _medic in ["HEALTHY", "INJURED"]) } };

		if ([animationState _medic, "cin", "erc"] call JB_fnc_matchAnimationState) then
		{
			waitUntil { sleep 0.2; !([animationState _medic, "cin", "erc"] call JB_fnc_matchAnimationState) || { !(lifeState _medic in ["HEALTHY", "INJURED"]) } || { lifeState _wounded != "INCAPACITATED" } };
		};

		// If we're left carrying, get out of it
		if ([animationState _medic, "cin", "erc"] call JB_fnc_matchAnimationState) then
		{
			private _medicAnimation = [_medic] call JBM_GetMedicCarryExitAnimation;
			[_medic, _wounded, _medicAnimation] remoteExec ["JBM_R_StopCarry"];
		};
	};
};

JBM_UnloadWoundedCondition =
{
	private _pointIndex = param [0, 0, [0]];

	if ([animationState player, ["cin", "inv"]] call JB_fnc_matchAnimationState) exitWith { false };

	if (JBM_VehiclePointsFrameNumber < JBM_FrameNumber) then
	{
		JBM_VehiclePointsFrameNumber = JBM_FrameNumber;
		[] call JBM_SetupLoadUnloadActions;
	};

	private _params = player actionParams (JBM_UnloadActions select _pointIndex);

	// If the first parameter is empty then the action is not in use
	(_params select 0) != ""
};

JBM_UnloadWounded =
{
	private _pointIndex = param [0, 0, [0]];

	private _point = JBM_VehiclePoints select _pointIndex;

	private _occupants = [_point] call JBM_PointOccupants;

	private _incapacitated = objNull;

	{
		if (!(isNull _x) && { lifeState _x == "INCAPACITATED" }) exitWith { _incapacitated = _x };
	} forEach _occupants;

	if (!isNull _incapacitated) then
	{
		[_incapacitated] call JBM_CarryWounded;
	};
};

JBM_SetupActions =
{
//TODO: Put player names on all actions.  "Drag George Bush", etc.

	player addAction ["<t color=""#ED2744"">Drag wounded</t>", { [cursorTarget] call JBM_DragWounded }, nil, 20, false, true, "", "[cursorTarget] call JBM_DragWoundedCondition"];
	player addAction ["<t color=""#ED2744"">Carry wounded</t>", { [cursorTarget] call JBM_CarryWounded }, nil, 20, false, true, "", "[cursorTarget] call JBM_CarryWoundedCondition"];
	player addAction ["<t color=""#ED2744"">Set down wounded</t>", { [] call JBM_SetDownWounded }, nil, 20, true, false, "", "[] call JBM_SetDownWoundedCondition"];
	player addAction ["<t color=""#ED2744"">Stabilize wounded</t>", { [cursorTarget] call JBM_StabilizeWounded }, nil, 20, false, true, "", "[cursortarget] call JBM_StabilizeWoundedCondition"];

	JBM_LoadActions = [];
	JBM_LoadActions pushBack (player addAction ["Load wounded 0", { [0] call JBM_LoadWounded }, nil, 20, false, true, "", "[0] call JBM_LoadWoundedCondition"]);
	JBM_LoadActions pushBack (player addAction ["Load wounded 1", { [1] call JBM_LoadWounded }, nil, 20, false, true, "", "[1] call JBM_LoadWoundedCondition"]);
	JBM_LoadActions pushBack (player addAction ["Load wounded 2", { [2] call JBM_LoadWounded }, nil, 20, false, true, "", "[2] call JBM_LoadWoundedCondition"]);
	JBM_LoadActions pushBack (player addAction ["Load wounded 3", { [3] call JBM_LoadWounded }, nil, 20, false, true, "", "[3] call JBM_LoadWoundedCondition"]);

	JBM_UnloadActions = [];
	JBM_UnloadActions pushBack (player addAction ["Unload wounded 0", { [0] call JBM_UnloadWounded }, nil, 20, false, true, "", "[0] call JBM_UnloadWoundedCondition"]);
	JBM_UnloadActions pushBack (player addAction ["Unload wounded 1", { [1] call JBM_UnloadWounded }, nil, 20, false, true, "", "[1] call JBM_UnloadWoundedCondition"]);
	JBM_UnloadActions pushBack (player addAction ["Unload wounded 2", { [2] call JBM_UnloadWounded }, nil, 20, false, true, "", "[2] call JBM_UnloadWoundedCondition"]);
	JBM_UnloadActions pushBack (player addAction ["Unload wounded 3", { [3] call JBM_UnloadWounded }, nil, 20, false, true, "", "[3] call JBM_UnloadWoundedCondition"]);

	// Determine if player's character class has advanced medical skills.

	if (player getUnitTrait "medic") then
	{
		player addAction ["<t color=""#ED2744"">Revive wounded</t>", { [cursorTarget] call JBM_ReviveWounded }, nil, 20, true, true, "", "[cursorTarget] call JBM_ReviveWoundedCondition"];
	};
};