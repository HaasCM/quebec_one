[_this select 0,
	{
		private _vehicle = param [0, objNull, [objNull]];

		_vehicle setObjectTextureGlobal [0, "a3\armor_f_beta\apc_tracked_01\data\apc_tracked_01_body_crv_co.paa"];
		_vehicle setObjectTextureGlobal [1, "a3\armor_f_beta\apc_tracked_01\data\mbt_01_body_co.paa"];
		_vehicle setObjectTextureGlobal [2, "a3\armor_f_gamma\apc_wheeled_03\data\rcws30_co.paa"];

		{
			_vehicle removeMagazinesTurret [_x, [0]];
		} forEach (_vehicle magazinesTurret [0]);

		_vehicle addMagazineTurret ["140Rnd_30mm_MP_shells_Tracer_Red", [0], 140];
		_vehicle addMagazineTurret ["60Rnd_30mm_APFSDS_shells_Tracer_Red", [0], 60];
		_vehicle addMagazineTurret ["1000Rnd_65x39_Belt_Tracer_Red", [0], 1000];
		_vehicle addMagazineTurret ["2Rnd_GAT_missiles", [0], 2];

		[_vehicle] call JB_fnc_downgradeATInventory;
		_vehicle addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 3];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 450] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;