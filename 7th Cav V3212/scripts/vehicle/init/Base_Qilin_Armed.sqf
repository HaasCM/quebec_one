[_this select 0,
	{
		private _vehicle = param [0, objNull, [objNull]];

		[_vehicle, "black", []] call BIS_fnc_initVehicle;
		[_vehicle] call JB_fnc_downgradeATInventory;

		{
			_vehicle removeMagazinesTurret [_x, [0]];
		} forEach (_vehicle magazinesTurret [0]);

		_vehicle addMagazineTurret ["500Rnd_65x39_Belt_Tracer_Red_Splash", [0], 500];
		_vehicle addMagazineTurret ["500Rnd_65x39_Belt_Tracer_Red_Splash", [0], 500];
		_vehicle addMagazineTurret ["500Rnd_65x39_Belt_Tracer_Red_Splash", [0], 500];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;