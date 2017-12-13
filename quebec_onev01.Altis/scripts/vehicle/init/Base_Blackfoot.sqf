[_this select 0,
	{
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 1];

		_setupClient =
			{
				(_this select 0) enableCopilot true;
				player action ["LockVehicleControl", (_this select 0)];
				(_this select 0) enableCopilot false;

				(_this select 0) addEventHandler ["Fired",
					{
						if (driver (_this select 0) == player && { isManualFire (_this select 0) }) then
						{
							deleteVehicle (_this select 6)
						}
					}]
			};
		[[_this select 0], _setupClient] remoteExec ["call", 0, true]; //JIP
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 450] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;