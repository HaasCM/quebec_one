#define THERMAL_OPTICS_MSG "Thermal optics restriction in place.  %1 removed."
#define MARKSMAN_WEAPONS_MSG "Only marksmen may use this weapon system. %1 removed."
#define GROUND_COMBATANT_WEAPONS_MSG "You may not use a rifle. %1 removed."
#define SNIPER_WEAPONS_MSG "Only snipers may use this weapon system. %1 removed."
#define SNIPER_OPTICS_MSG "Only sniper team members may use this item. %1 removed."
#define LASER_DESIGNATOR_MSG "Only JTAC and Recon Team Leaders may use this item. %1 removed."
#define AUTOMATIC_WEAPONS_MSG "Only autoriflemen may use this weapon system. %1 removed."
#define RPG_WEAPONS_MSG "Only anti-tank soldiers may use this weapon system. %1 removed."
#define GRENADIER_WEAPONS_MSG "Only grenadiers may use this weapon system. %1 removed."
#define UAV_RESTRICTION_MSG "Only UAV operators may use this item.  %1 removed."
#define EOD_GEAR_MSG "Only EOD team members may use this item.  %1 removed."
#define UNAVAILABLE_ITEMS_MSG "Item is not available.  %1 removed."

GR_Name_Matches_Pattern =
{
	params ["_name", "_pattern"];

	private _matchesPattern = false;

	private _wildcard = _pattern find "*";
	if (_wildcard == -1) then
	{
		_matchesPattern = (_name == _pattern);
	}
	else
	{
		if (count _name >= _wildcard) then
		{
			_matchesPattern = (_name select [0, _wildcard]) == (_pattern select [0, _wildcard]);
		}
	};

	_matchesPattern;
};

GR_RPGWeaponsRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _weapons = weapons player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [RPG_WEAPONS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeWeapon _x;
			}
		} foreach _weapons;
	} foreach GR_RPGOperatorRestrictions;

	_violations;
};

GR_SniperWeaponsRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _weapons = weapons player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [SNIPER_WEAPONS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeWeapon _x;
			}
		} foreach _weapons;
	} foreach GR_SniperWeaponOperatorRestrictions;

	_violations;
};

GR_AutomaticWeaponsRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _weapons = weapons player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [AUTOMATIC_WEAPONS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeWeapon _x;
			}
		} foreach _weapons;
	} foreach GR_AROperatorRestrictions;

	_violations;
};

GR_MarksmanWeaponsRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _weapons = weapons player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [MARKSMAN_WEAPONS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeWeapon _x;
			}
		} foreach _weapons;
	} foreach GR_MarksmanOperatorRestrictions;

	_violations;
};

GR_GroundCombatantWeaponsRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _weapons = weapons player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [GROUND_COMBATANT_WEAPONS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeWeapon _x;
			}
		} foreach _weapons;
	} foreach GR_GroundCombatantOperatorRestrictions;

	_violations;
};

GR_GrenadierWeaponsRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _weapons = weapons player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [GRENADIER_WEAPONS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeWeapon _x;
			}
		} foreach _weapons;
	} foreach GR_GrenadierOperatorRestrictions;

	_violations;
};

GR_LaserDesignatorRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _weapons = weapons player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [LASER_DESIGNATOR_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeWeapon _x;
			}
		} foreach _weapons;
	} foreach GR_LaserDesignatorOperatorRestrictions;

	_violations;
};

GR_UAVRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _gear = assignedItems player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [UAV_RESTRICTION_MSG, [_x, "CfgVehicles"] call JB_fnc_displayName]);
				player unassignItem _x;
				player removeItem _x;
			}
		} foreach _gear;
	} foreach GR_UAVOperatorRestrictions;

	_violations;
};

GR_ThermalOpticsRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _weaponOptics = primaryWeaponItems player;
	private _weapon = primaryWeapon player;
	private _headgear = headgear player;

	{
		_p = _x;

		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [THERMAL_OPTICS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removePrimaryWeaponItem  _x;
			}
		} foreach _weaponOptics;

		if ([_weapon, _p] call GR_Name_Matches_Pattern) then
		{
			_violations pushBack (format [THERMAL_OPTICS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
			player removeWeapon _weapon;
		};

		if ([_headgear, _p] call GR_Name_Matches_Pattern) then
		{
			_violations pushBack (format [THERMAL_OPTICS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
			removeHeadgear player;
		};

	} foreach GR_ThermalOpticsOperatorRestrictions;

	_violations;
};

GR_SniperOpticsRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _weaponOptics = primaryWeaponItems player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [SNIPER_OPTICS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removePrimaryWeaponItem  _x;
			}
		} foreach _weaponOptics;
	} foreach GR_SniperOpticsOperatorRestrictions;

	_violations;
};

GR_EODGearRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _backpackItems = backpackItems player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [EOD_GEAR_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeItemFromBackpack _x;
			}
		} foreach _backpackItems;
	} foreach GR_EODOperatorRestrictions;

	_violations;
};

GR_ProhibitedItemsRestriction =
{
	if (isNil "GR_WhitelistItems") then
	{
		GR_WhitelistItems = [] call compile preprocessFile "scripts\whitelistGear.sqf";

		private _whitelistWeapons = GR_WhitelistItems select 0;
		private _whitelistBackpacks = GR_WhitelistItems select 1;
		private _whitelistItems = GR_WhitelistItems select 2;
	};

	private _violations = [];

	private _whitelistWeapons = GR_WhitelistItems select 0;
	private _whitelistBackpacks = GR_WhitelistItems select 1;
	private _whitelistItems = GR_WhitelistItems select 2;

	{
		if (_x != "" && not (_x in _whitelistWeapons)) then
		{
			_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
			player removeWeapon _x;
		}
	} foreach [primaryWeapon player, secondaryWeapon player, handgunWeapon player];

	private _backpack = backpack player;
	if (_backpack != "" && not (_backpack in _whitelistBackpacks)) then
	{
		_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_backpack, "CfgVehicles"] call JB_fnc_displayName]);
		removeBackpack player;
	};

	private _headgear = headgear player;
	if (_headgear != "" && not (_headgear in _whitelistItems)) then
	{
		_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_headgear, "CfgWeapons"] call JB_fnc_displayName]);
		removeHeadgear player;
	};

	private _vest = vest player;
	if (_vest != "" && not (_vest in _whitelistItems)) then
	{
		_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_vest, "CfgWeapons"] call JB_fnc_displayName]);
		removeVest player;
	};

	private _uniform = uniform player;
	if (_uniform != "" && not (_uniform in _whitelistItems)) then
	{
		_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_uniform, "CfgWeapons"] call JB_fnc_displayName]);
		removeUniform player;
	};

	{
		if (not (_x in _whitelistItems) && { not (_x in _whitelistWeapons) } && { not isClass (configFile >> "CfgMagazines" >> _x) }) then
		{
			_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_x] call JB_fnc_displayName]);
			player removeItemFromBackpack _x;
		};
	} foreach backpackItems player;

	{
		if (not (_x in _whitelistItems) && { not (_x in _whitelistWeapons) } && { not isClass (configFile >> "CfgMagazines" >> _x) }) then
		{
			_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_x] call JB_fnc_displayName]);
			player removeItemFromVest _x;
		}
	} foreach vestItems player;

	{
		if (not (_x in _whitelistItems) && { not (_x in _whitelistWeapons) } && { not isClass (configFile >> "CfgMagazines" >> _x) }) then
		{
			_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_x] call JB_fnc_displayName]);
			player removeItemFromUniform _x;
		}
	} foreach uniformItems player;

	_violations;
};

GR_Restrictions = _this select 0;
GR_Restrictions pushBack { [] call GR_ProhibitedItemsRestriction };

private _violations = [];
private _violationCounter = 60;

while {true} do
{
	{
		_violations = _violations + ([] call _x);
	} foreach GR_Restrictions;

	if (count _violations > 0) then
	{
		private _message = _violations select 0;
		for "_i" from 1 to (count _violations) - 1 do
		{
			_message = _message + "\n" + (_violations select _i);
		};

		titleText [_message, "BLACK"];
		sleep (1 + (count _violations));
		titleFadeOut 1;

		_violations = [];
		_violationCounter = 30; // 30 seconds of active checking of gear if the player has violated a restriction
	};

	if (_violationCounter == 0) then
	{
		sleep 10;
	}
	else
	{
		sleep 1;
		_violationCounter = _violationCounter - 1;
	};
};
