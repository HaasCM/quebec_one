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
	_restrictions pushBack [{ _this call Restriction_MayNotOperateGunTurrets; }, [["B_CTRG_Heli_Transport_01_tropic_F", false]] + AircraftTypeFilter];
	[_restrictions] execVM "scripts\vehicleCrewRestrictionsInit.sqf";

	_restrictions = [];
	_restrictions pushBack { [] call GR_RPGWeaponsRestriction; };
	_restrictions pushBack { [] call GR_SniperWeaponsRestriction; };
	_restrictions pushBack { [] call GR_UAVRestriction; };
	_restrictions pushBack { [] call GR_SniperOpticsRestriction; };
	_restrictions pushBack { [] call GR_MarksmanWeaponsRestriction; };
	_restrictions pushBack { [] call GR_EODGearRestriction; };
	[_restrictions] execVM "scripts\gearRestrictionsInit.sqf";

	[player, Repair_DefaultProfile] call JB_fnc_repairInit;
};

player setUnitRecoilCoefficient 0.5;
[0.3] call JB_fnc_weaponSwayInit;

player setStamina 120;