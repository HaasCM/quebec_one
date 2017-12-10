[_this select 0,
	{
		[_this select 0] remoteExec ["Parachute_SetupClient", 0, true]; // JIP
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 2];
//		(_this select 0) setVariable ["TRANSPORT_InternalStorage", [[0,4.45,-1.3]], true]; // JIP
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;