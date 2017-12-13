[_this select 0,
	{
		private _vehicle = param [0, objNull, [objNull]];

		[_vehicle, "blufor", []] call BIS_fnc_initVehicle;
		[_vehicle] call JB_fnc_downgradeATInventory;

		{
			_vehicle removeMagazinesTurret [_x, [0]];
		} forEach (_vehicle magazinesTurret [0]);

		_vehicle addMagazineTurret ["200Rnd_127x99_mag_Tracer_Red", [0], 200];
		_vehicle addMagazineTurret ["200Rnd_127x99_mag_Tracer_Red", [0], 200];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;