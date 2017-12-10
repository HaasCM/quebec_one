[_this select 0,
	{
		[_this select 0] call JB_fnc_downgradeATInventory;
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 3];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 450] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;