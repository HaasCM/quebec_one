[_this select 0,
	{
		[_this select 0, "black", nil, false] call BIS_fnc_initVehicle;
		[_this select 0, 20] call JB_fnc_medicalInitAmbulance;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 120] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;