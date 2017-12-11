[
	_this select 0,
	{
		(_this select 0) setVariable ["REPAIR_ServiceLevel", 2, true];
		(_this select 0) setRepairCargo 0;

		[_this select 0] call JB_fnc_downgradeATInventory;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1500] call JB_fnc_respawnVehicleWhenAbandoned;