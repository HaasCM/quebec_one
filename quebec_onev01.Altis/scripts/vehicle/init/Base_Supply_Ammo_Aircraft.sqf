(_this select 0) setAmmoCargo 0;

private _ammo = if (not isServer) then { [] } else { Ammo_AircraftAmmo apply { [_x select 0, (_x select 1) * 18] } };
[_this select 0, 50000,	[20, AmmoFilter_TransferToTrolley], _ammo] call JB_fnc_ammoInit;