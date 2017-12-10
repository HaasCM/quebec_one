[
	_this select 0,
	{
		(_this select 0) setAmmoCargo 0;

		private _ammo = [];
		if (isNull (_this select 1)) then
		{
			_ammo = Ammo_VehicleAmmo apply { [_x select 0, (_x select 1) * 2] };
		};

		[_this select 0, 9780, [5, AmmoFilter_TransferToAny], _ammo] call JB_fnc_ammoInit;

		[_this select 0] call JB_fnc_downgradeATInventory;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1500] call JB_fnc_respawnVehicleWhenAbandoned;