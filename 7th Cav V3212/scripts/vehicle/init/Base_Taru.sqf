[_this select 0,
	{
		[_this select 0, "black", nil, false] call BIS_fnc_initVehicle;
		(_this select 0) enableCopilot false;
		[_this select 0, PCC_PodParaDrop] call JB_fnc_taruPodInit;
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 2];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;