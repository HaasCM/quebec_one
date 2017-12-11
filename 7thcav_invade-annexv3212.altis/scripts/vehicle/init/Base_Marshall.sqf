[_this select 0,
	{
		[_this select 0] call JB_fnc_downgradeATInventory;
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 3];

		(_this select 0) removeMagazinesTurret ["2000Rnd_65x39_Belt", [0]];
		(_this select 0) addMagazineTurret ["2000Rnd_65x39_Belt_Tracer_Red", [0], 2000];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 450] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;