FOB_INIT_OffroadRepair =
{
	private _reward = _this select 0;
	_reward setRepairCargo 0;
	_reward setVariable ["REPAIR_ServiceLevel", 2, true];
	[_reward] call JB_fnc_downgradeATInventory;
};

FOB_INIT_MedevacContainer =
{
};

FOB_INIT_AmmoContainer =
{
	private _reward = _this select 0;
	_reward setAmmoCargo 0;

	private _ammo = Ammo_VehicleAmmo apply { [_x select 0, (_x select 1) * 2] };

	[_reward, 9780, [5, AmmoFilter_TransferToAny], _ammo] call JB_fnc_ammoInit;

	[_reward] call JB_fnc_downgradeATInventory;
};

FOB_INIT_RepairContainer =
{
	private _reward = _this select 0;
	_reward setRepairCargo 0;
	_reward setVariable ["REPAIR_ServiceLevel", 2, true];
};

FOB_INIT_FuelContainer =
{
	private _reward = _this select 0;
	_reward setFuelCargo 0;
	[_reward, [[0.535,3.072,-1.010], [-0.535,3.072,-1.010]], 9464, 60] call JB_fnc_fuelInitSupply;
};

FOB_ContinueSupplyMissions = true;

params ["_fobMarker", "_vehicle1Marker", "_vehicle2Marker", "_helipadMarker", "_repairMaker", "_medicalMarker", "_fuelMarker", "_ammoMarker", "_rewardMarker", "_suppliesMarker"];

private _supplyTypes =
[
	"basic",
	"medical",
	"ammo",
	"parts",
	"fuel"
];

"FOB_Marker" setMarkerPos (getMarkerPos _fobMarker);

private _lightvic1 = "B_MRAP_01_F" createVehicle (getMarkerPos _vehicle1Marker);
_lightvic1 setDir (markerDir _vehicle1Marker);
[_lightvic1] call JB_fnc_downgradeATInventory;

private _lightvic2 = "B_MRAP_01_F" createVehicle (getMarkerPos _vehicle2Marker);
_lightvic2 setDir (markerDir _vehicle2Marker);
[_lightvic2] call JB_fnc_downgradeATInventory;

[[_lightvic1, _lightvic2]] call SERVER_CurateEditableObjects;

"Land_HelipadSquare_F" createVehicle (getMarkerPos _helipadMarker);

_hint = "<t align='center'><t size='2.2'>Forward Operating Base</t><br/><t size='1.5' color='#00B2EE'></t><br/>____________________<br/>We have created Forward Operating Base (FOB) Vigilance in support of combat operations. Missions to supply it will be assigned soon.</t>";
[_hint] remoteExec ["AW_fnc_globalHint",0,false];

if (isDedicated) then
{
	sleep 60;
};

private _mission = nil;

while { FOB_ContinueSupplyMissions && count _supplyTypes > 0 } do
{
	private _supply = _supplyTypes select (floor (random (count _supplyTypes)));
	_supplyTypes = _supplyTypes - [_supply];

	switch (_supply) do
	{
		case "basic"	: { _mission = ["B_Truck_01_box_F", "Basic Supplies", "B_G_Offroad_01_repair_F", FOB_INIT_OffroadRepair, _suppliesMarker, _rewardMarker] execVM "mission\fob\mission.sqf" };
		case "medical"	: { _mission = ["B_Truck_01_medical_F", "Medical Supplies", "B_Slingload_01_Medevac_F", FOB_INIT_MedevacContainer, _medicalMarker, _rewardMarker] execVM "mission\fob\mission.sqf" };
		case "ammo"		: { _mission = ["B_Truck_01_ammo_F", "Munitions", "B_Slingload_01_Ammo_F", FOB_INIT_AmmoContainer, _ammoMarker, _rewardMarker] execVM "mission\fob\mission.sqf" };
		case "parts"	: { _mission = ["B_Truck_01_Repair_F", "Spare Parts", "B_Slingload_01_Repair_F", FOB_INIT_RepairContainer, _repairMaker, _rewardMarker] execVM "mission\fob\mission.sqf" };
		case "fuel"		: { _mission = ["B_Truck_01_fuel_F", "Fuel", "B_Slingload_01_Fuel_F", FOB_INIT_FuelContainer, _fuelMarker, _rewardMarker] execVM "mission\fob\mission.sqf" };
		default { };
	};

	waitUntil { sleep 5; scriptDone _mission };

	if (isDedicated) then
	{
		private _endSleepTime = diag_tickTime + (120 + (random 600));
		waitUntil { sleep 1; not FOB_ContinueSupplyMissions || diag_tickTime > _endSleepTime };
	};
};

if (FOB_ContinueSupplyMissions && count _supplyTypes == 0) then
{
	FOB_ContinueSupplyMissions = false;

	_hint = "<t align='center'><t size='2.2'>FOB Supply Complete</t><br/><t size='1.5' color='#00B2EE'></t><br/>____________________<br/>All available supply convoys have been sent to the Forward Operating Base.  No more supplies will be made available until Vigilance is moved.</t>";
	[_hint] remoteExec ["AW_fnc_globalHint", 0, false];
};

"FOB_Marker" setMarkerPos [-10000,-10000,-10000];