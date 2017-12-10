private _vehicle = _this select 0;

private _magazineCargo = getMagazineCargo _vehicle;

private _magazineTypes = _magazineCargo select 0;
private _magazineCounts = _magazineCargo select 1;

clearMagazineCargoGlobal _vehicle;

{
	switch (_x) do
	{
		case "Titan_AT":
		{
			_vehicle addMagazineCargoGlobal ["RPG32_F", _magazineCounts select _forEachIndex];
		};
	
		case "Titan_AP":
		{
			_vehicle addMagazineCargoGlobal ["RPG32_HE_F", _magazineCounts select _forEachIndex];
		};
	
		case "Titan_AA":
		{
		};
	
		case "NLAW_F";
		case "RPG32_F";
		case "RPG32_HE_F":
		{
			_vehicle addMagazineCargoGlobal ["RPG7_F", _magazineCounts select _forEachIndex];
		};

		default
		{
			_vehicle addMagazineCargoGlobal [_x, _magazineCounts select _forEachIndex];
		};	
	};
} forEach _magazineTypes;

private _weaponCargo = getWeaponCargo _vehicle;

private _weaponTypes = _weaponCargo select 0;
private _weaponCounts = _weaponCargo select 1;

clearWeaponCargoGlobal _vehicle;

{
	if (_x find "Titan" != -1) then
	{
		_vehicle addWeaponCargoGlobal ["launch_RPG32_F", _weaponCounts select _forEachIndex];
	}
	else
	{
		if (_x find "NLAW" != -1 || _x find "RPG32" != -1) then
		{
			_vehicle addWeaponCargoGlobal ["launch_RPG7_F", _weaponCounts select _forEachIndex];
		}
	};
} forEach _weaponTypes;