if (not hasInterface) exitWith {};

AircraftTypeFilter =
[
	["Air", true],
	["All", false]
];

// Transport aircraft
TAR_AircraftTypeFilter =
[
	["ParachuteBase", false],
	["Heli_Transport_01_base_F", true],
	["Heli_Transport_03_base_F", true],
	["Heli_Light_01_unarmed_base_F", true],
	["Heli_Transport_04_base_F", true],
	["VTOL_01_unarmed_base_F", true],
	["All", false]
];

// Special operations aircraft
SOAR_AircraftTypeFilter =
[
	["B_CTRG_Heli_Transport_01_tropic_F", true],
	["All", false]
];

// Attack aircraft
AAR_AircraftTypeFilter =
[
	["Heli_Attack_01_base_F", true],
	["Heli_Light_01_armed_base_F", true],
	["Plane_CAS_01_base_F", true],
	["Plane_Fighter_01_base_F", true],
	["VTOL_01_armed_base_F", true],
	["Heli_Attack_02_base_F", true],
	["O_Heli_Light_02_F", true],
	["O_Heli_Light_02_dynamicLoadout_F", true],
	["VTOL_02_base_F", true],
	["Plane_CAS_02_base_F", true],
	["Plane_Fighter_02_Base_F", true],
	["I_Heli_light_03_F", true],
	["I_Heli_light_03_dynamicLoadout_F", true],
	["Plane_Fighter_03_base_F", true],
	["Plane_Fighter_04_base_F", true],

	["All", false]
];

AVR_VehicleTypeFilter =
[
	["B_APC_Tracked_01_CRV_F", false],
	["B_T_APC_Tracked_01_AA_F", false],
	["Wheeled_APC_F", true],
	["Car", false],
	["Tank", true],
	["All", false]
];

BSVR_VehicleTypeFilter =
[
	["B_APC_Tracked_01_CRV_F", true],
	["All", false]
];

MortarVehicleTypeFilter =
[
	["StaticMortar", true],
	["All", false]
];

MedicalVehicleTypeFilter =
[
	["B_Truck_01_medical_F", true],
	["All", false]
];

LogisticsVehicleTypeFilter =
[
	["B_Truck_01_mover_F", true],
	["All", false]
];

// Gear restrictions for various classes

GR_UAVOperatorRestrictions =
[
	"B_UavTerminal",
	"O_UavTerminal",
	"I_UavTerminal"
];

GR_GuidedMissileOperatorRestrictions =
[
	"launch_NLAW_F",
	"launch_B_Titan*",
	"launch_I_Titan*",
	"launch_O_Titan*",
	"launch_Titan*"
];

GR_RPGOperatorRestrictions =
[
	"launch_RPG32*"
];

GR_SniperWeaponOperatorRestrictions =
[
	"srifle_GM6*",
	"srifle_LRR*"
];

GR_ThermalOpticsOperatorRestrictions =
[
	"optic_tws*",
	"optic_Nightstalker",
	"NVGogglesB*",
	"Rangefinder",
	"H_HelmetO_ViperSP*"
];

GR_AROperatorRestrictions =
[
	"LMG*",
	"MMG*",
	"arifle_MX_SW*",
	"LMG_03_F",
	"arifle_CTARS*",
	"arifle_SPAR_02*"
];

GR_SniperOpticsOperatorRestrictions =
[
	"optic_LRPS*",
	"optic_SOS*"
];

GR_EODOperatorRestrictions =
[
	"MineDetector"
];

GR_MarksmanOperatorRestrictions =
[
	"arifle_MXM*",
	"arifle_SPAR_03*"
];

GR_GroundCombatantOperatorRestrictions =
[
	"arifle_*",
	"srifle_*",
	"LMG_*",
	"MMG_*",
	"launch_*"
];

GR_GrenadierOperatorRestrictions =
[
	"arifle_Katiba_GL*",
	"arifle_Mk20_GL*",
	"arifle_AK12_GL*",
	"arifle_CTAR_GL_*",
	"arifle_MX_GL*",
	"arifle_TRG21_GL*",
	"arifle_SPAR_01_GL*"
];

GR_LaserDesignatorOperatorRestrictions =
[
	"LaserDesignator*"
];

Repair_DefaultGetRepairProfile =
{
	private _engineer = param [0, objNull, [objNull]];
	private _vehicle = param [1, objNull, [objNull]];
	private _systemName = param [2, "", [""]];

	if (not ((toLower _systemName) find "wheel" >= 0)) exitWith { [false, 0, 0, "", false] };

	[true, 1.0, 0.4, "", true]
};

Repair_DefaultCanRepairVehicle =
{
	private _engineer = param [0, objNull, [objNull]];
	private _vehicle = param [1, objNull, [objNull]];

	private _vehicleType = typeOf _vehicle;

	_vehicleType isKindOf "Car"
};

Repair_DefaultProfile = [Repair_DefaultGetRepairProfile, Repair_DefaultCanRepairVehicle];

Repair_ArmorGetRepairProfile =
{
	private _engineer = param [0, objNull, [objNull]];
	private _vehicle = param [1, objNull, [objNull]];
	private _systemName = param [2, "", [""]];

	private _vehicleType = typeOf _vehicle;

	if (not ([_engineer, _vehicle] call Repair_ArmorCanRepairVehicle)) exitWith { [false, ""] };

	if (not ((toLower _systemName) find "wheel" >= 0) && { (not ("ToolKit" in (backpackItems player))) }) exitWith
	{
		[true, 0, 0, format ["%1 repairs require a Toolkit", _systemName], false];
	};

	private _repairPPS = 1.0;
	private _targetPC = 0.4;
	private _message = "";

	if (_vehicleType isKindOf "Tank") then
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

Repair_ArmorCanRepairVehicle =
{
	private _engineer = param [0, objNull, [objNull]];
	private _vehicle = param [1, objNull, [objNull]];

	((typeOf _vehicle) isKindOf "Tank") || { ((typeOf _vehicle) isKindOf "Car") }
};

Repair_ArmorProfile = [Repair_ArmorGetRepairProfile, Repair_ArmorCanRepairVehicle];

Parachute_SetupClient =
{
	private _vehicle = _this select 0;

	if (not hasInterface) exitWith {};

	_vehicle addAction ["Paradrop - HALO", { [player, false] call JB_fnc_halo }, nil, 2, false, true, "", '(getPos _target) select 2 > 250 && { speed _target < 300 } && { (assignedVehicleRole player) select 0 == "cargo" }'];
	_vehicle addAction ["Paradrop - static line", { [player, true] call JB_fnc_halo }, nil, 2, false, true, "", '(getPos _target) select 2 > 100 && { speed _target < 300 } && { (assignedVehicleRole player) select 0 == "cargo" }'];
};

BobcatService_SetupClient =
{
	private _vehicle = _this select 0;

	if (not hasInterface) exitWith {};

	_vehicle addAction ["Repair/refuel aircraft", { [vehicle (_this select 1), [["repair", 60, 0.0], ["refuel", 60, 1.0]]] call JB_fnc_serviceVehicle }, nil, 15, false, true, "", '((vehicle _this) isKindOf "Air") && { not ((vehicle _this) isKindOf "ParachuteBase") }'];
};

CLIENT_Supply_RestockFromSupplyCondition =
{
	private _container = _this select 0;
	private _supplyType = _this select 1;
	private _distance = _this select 2;

	private _supply = objNull;
	{
		if (_x getVariable "SupplyType" == _supplyType) exitWith { _supply = _x };
	} forEach (_container nearObjects _distance);

	not isNull _supply
};

Billboard_ShowMessage =
{
	private _width = _this select 0;
	private _height = _this select 1;
	private _message = _this select 2;

	disableSerialization;
	private _ctrl = findDisplay 46 createDisplay "RscDisplayEmpty" ctrlCreate ["RscStructuredText", -1];
	_ctrl ctrlSetBackgroundColor [0, 0, 0, 0.7];
	_ctrl ctrlSetPosition [(1.0 - _width) / 2, (1.0 - _height) / 2, _width, _height];
	_ctrl ctrlCommit 0;
	_ctrl ctrlSetStructuredText _message;
};

CLIENT_CuratorType = "";
