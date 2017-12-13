[_this select 0,
	{
		(_this select 0) enableCopilot true;
		(_this select 0) removeWeaponTurret ["LMG_Minigun_Transport", [1]];
		(_this select 0) removeWeaponTurret ["LMG_Minigun_Transport2", [2]];
		[_this select 0, PCC_LightParaDrop] call JB_fnc_paradropSlungCargo;
		[_this select 0] remoteExec ["Parachute_SetupClient", 0, true]; // JIP
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 2];
		[_this select 0] spawn SERVER_Ghosthawk_DoorManager;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;