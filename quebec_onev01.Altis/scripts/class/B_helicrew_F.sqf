private _state = param [0, "", [""]];

if (_state == "init") then
{
	private _restrictions = [];

	_restrictions = [];
	_restrictions pushBack [{ _this call Restriction_MayNotPilotAircraft; }, TAR_AircraftTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotPilotAircraft; }, AAR_AircraftTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotCrewVehicle; }, AVR_VehicleTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotCrewVehicle; }, MortarVehicleTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotDriveVehicle; }, MedicalVehicleTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotDriveVehicle; }, LogisticsVehicleTypeFilter];
	[_restrictions] execVM "scripts\vehicleCrewRestrictionsInit.sqf";

	_restrictions = [];
	_restrictions pushBack { [] call GR_RPGWeaponsRestriction; };
	_restrictions pushBack { [] call GR_SniperWeaponsRestriction; };
	_restrictions pushBack { [] call GR_UAVRestriction; };
	_restrictions pushBack { [] call GR_SniperOpticsRestriction; };
	_restrictions pushBack { [] call GR_AutomaticWeaponsRestriction; };
	_restrictions pushBack { [] call GR_MarksmanWeaponsRestriction; };
	_restrictions pushBack { [] call GR_GrenadierWeaponsRestriction; };
	_restrictions pushBack { [] call GR_LaserDesignatorRestriction; };
	_restrictions pushBack { [] call GR_EODGearRestriction; };
	[_restrictions] execVM "scripts\gearRestrictionsInit.sqf";

	B_helicrew_F_GetRepairProfile =
	{
		private _engineer = param [0, objNull, [objNull]];
		private _vehicle = param [1, objNull, [objNull]];
		private _systemName = param [2, "", [""]];

		private _vehicleType = typeOf _vehicle;

		if (not ([_engineer, _vehicle] call B_helicrew_F_CanRepairVehicle)) exitWith { [false, 0, 0, ""] };

		if (not ((toLower _systemName) find "wheel" >= 0) && { (getText (configFile >> "CfgVehicles" >> _vehicleType >> "vehicleClass") == "Armored") }) exitWith { [false, 0, 0, ""] };

		if (not ((toLower _systemName) find "wheel" >= 0) && { (not ("ToolKit" in (backpackItems player))) }) exitWith
		{
			[false, 0, 0, format ["%1 repairs require a Toolkit", _systemName]];
		};

		private _repairPPS = 1.0;
		private _targetPC = 0.4;
		private _message = "";

		if (_vehicleType isKindOf "Air") then
		{
			_repairPPS = 1.2;
		};

		{
			switch (_x getVariable ["REPAIR_ServiceLevel", 0]) do
			{
				case 2:
				{
					if (_targetPC > 0.0) then
					{
						_targetPC = 0.0;
						_message = format ["Using repair facilities of %1", [typeOf _x, "CfgVehicles"] call JB_fnc_displayName];
					};
				};
			};
		} forEach (nearestObjects [_engineer, ["All"], 10]);

		[true, _repairPPS, _targetPC, _message, true]
	};

	B_helicrew_F_CanRepairVehicle =
	{
		private _engineer = param [0, objNull, [objNull]];
		private _vehicle = param [1, objNull, [objNull]];

		private _vehicleType = typeOf _vehicle;

		(_vehicleType isKindOf "Air") || { ((_vehicleType isKindOf "Car") && not (getText (configFile >> "CfgVehicles" >> _vehicleType >> "vehicleClass") == "Armored")) }
	};

	[player, [B_helicrew_F_GetRepairProfile, B_helicrew_F_CanRepairVehicle]] call JB_fnc_repairInit;
};

player setUnitRecoilCoefficient 1.0;
[1.0] call JB_fnc_weaponSwayInit;

player enableFatigue false;