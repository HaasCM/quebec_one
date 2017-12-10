[
	_this select 0,
	{
		(_this select 0) setFuelCargo 0;
		[(_this select 0), [[0.449,-5.052,-0.317], [-0.449,-5.052,-0.317]], 9464, 60] call JB_fnc_fuelInitSupply;

		[_this select 0] call JB_fnc_downgradeATInventory;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1500] call JB_fnc_respawnVehicleWhenAbandoned;