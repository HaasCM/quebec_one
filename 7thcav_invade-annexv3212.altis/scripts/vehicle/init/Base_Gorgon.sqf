[_this select 0,
	{
		private _vehicle = param [0, objNull, [objNull]];

		_vehicle setObjectTextureGlobal [0, "A3\Armor_F_Gamma\APC_Wheeled_03\Data\apc_wheeled_03_ext_co.paa"]; 
		_vehicle setObjectTextureGlobal [1, "A3\Armor_F_Gamma\APC_Wheeled_03\Data\apc_wheeled_03_ext2_co.paa"]; 
		_vehicle setObjectTextureGlobal [2, "A3\Armor_F_Gamma\APC_Wheeled_03\Data\rcws30_co.paa"]; 
		_vehicle setObjectTextureGlobal [3, "A3\Armor_F_Gamma\APC_Wheeled_03\Data\apc_wheeled_03_ext_alpha_co.paa"];

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