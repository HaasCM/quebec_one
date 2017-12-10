[_this select 0,
	{
		(_this select 0) setObjectTexture [0, "a3\boat_f_gamma\boat_civil_01\data\boat_civil_01_ext_co.paa"];
		[_this select 0] call JB_fnc_clearVehicleInventory;
		(_this select 0) addItemCargoGlobal ["FirstAidKit", 50];
		(_this select 0) addItemCargoGlobal ["Medikit", 5];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;