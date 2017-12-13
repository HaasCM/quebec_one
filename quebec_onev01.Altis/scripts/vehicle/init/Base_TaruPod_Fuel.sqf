[_this select 0,
	{
		[_this select 0, "black", nil, false] call BIS_fnc_initVehicle;
		(_this select 0) setFuelCargo 0;
		[(_this select 0), [[-1.5, 1.4, -0.323], [-1.5, 1.4, 0.190]], 3000, 60] call JB_fnc_fuelInitSupply;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 120] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1500] call JB_fnc_respawnVehicleWhenAbandoned;