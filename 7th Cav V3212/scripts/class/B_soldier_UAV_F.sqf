private _state = param [0, "", [""]];

if (_state == "init") then
{
	private _restrictions = [];

	_restrictions = [];
	_restrictions pushBack [{ _this call Restriction_MayNotPilotAircraft; }, TAR_AircraftTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotPilotAircraft; }, AAR_AircraftTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotCrewVehicle; }, AVR_VehicleTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotDriveVehicle; }, BSVR_VehicleTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotCrewVehicle; }, MortarVehicleTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotDriveVehicle; }, MedicalVehicleTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotDriveVehicle; }, LogisticsVehicleTypeFilter];
	_restrictions pushBack [{ _this call Restriction_MayNotOperateGunTurrets; }, AircraftTypeFilter];
	[_restrictions] execVM "scripts\vehicleCrewRestrictionsInit.sqf";

	_restrictions = [];
	_restrictions pushBack { [] call GR_RPGWeaponsRestriction; };
	_restrictions pushBack { [] call GR_SniperWeaponsRestriction; };
	_restrictions pushBack { [] call GR_SniperOpticsRestriction; };
	_restrictions pushBack { [] call GR_AutomaticWeaponsRestriction; };
	_restrictions pushBack { [] call GR_MarksmanWeaponsRestriction; };
	_restrictions pushBack { [] call GR_GrenadierWeaponsRestriction; };
	_restrictions pushBack { [] call GR_LaserDesignatorRestriction; };
	_restrictions pushBack { [] call GR_EODGearRestriction; };
	[_restrictions] execVM "scripts\gearRestrictionsInit.sqf";

	[player, Repair_DefaultProfile] call JB_fnc_repairInit;
};

if (_state == "respawn") then
{
	player setUnitRecoilCoefficient 1.0;
	[1.0] call JB_fnc_weaponSwayInit;

	player enableFatigue false;

	player addAction ["<t color='#19C647'>Load new UAV software</t>", QS_fnc_actionUAVSoftware, [], 0, true, true, '', '[] call QS_fnc_conditionUAVSoftware'];

	{
		if (_x isKindOf "B_SAM_System_01_F" || _x isKindOf "B_SAM_System_02_F" || _x isKindOf "B_AAA_System_01_F") then
		{
			player disableUAVConnectability [_x, true];
		};
	} forEach allUnitsUAV;
};