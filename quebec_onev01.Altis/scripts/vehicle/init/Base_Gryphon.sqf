[_this select 0,
	{
		[_this select 0, "CamoGrey", []] call BIS_fnc_initVehicle;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 450] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;