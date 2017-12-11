JB_DATE_ReplaceEquipment =
{
	private _soldier = _this select 0;

	if (getText (configfile >> "CfgVehicles" >> typeOf _soldier >> "role") == "MissileSpecialist") then
	{
		private _secondaryWeapon = secondaryWeapon _soldier;
		if (_secondaryWeapon find "Titan" >= 0) then
		{
			_soldier removeMagazines "Titan_AT";
			_soldier removeWeapon _secondaryWeapon;
			_soldier addMagazine "RPG32_F";
			_soldier addMagazine "RPG32_F";
			_soldier addMagazine "RPG32_HE_F";
			_soldier addMagazine "RPG32_HE_F";
			_soldier addWeapon "launch_RPG32_F";
		}
		else
		{
			if (_secondaryWeapon find "NLAW" >= 0) then
			{
				_soldier removeMagazines "NLAW_F";
				_soldier removeWeapon _secondaryWeapon;
				_soldier addMagazine "RPG7_F";
				_soldier addMagazine "RPG7_F";
				_soldier addMagazine "RPG7_F";
				_soldier addWeapon "launch_RPG7_F";
			}
			else
			{
				if (_secondaryWeapon find "RPG32" >= 0) then
				{
					_soldier removeMagazines "RPG32_F";
					_soldier removeMagazines "RPG32_HE_F";
					_soldier removeWeapon _secondaryWeapon;
					_soldier addMagazine "RPG7_F";
					_soldier addMagazine "RPG7_F";
					_soldier addMagazine "RPG7_F";
					_soldier addMagazine "RPG7_F";
					_soldier addWeapon "launch_RPG7_F";
				};
			};
		};
	};
};

private _unit = param [0, 0, [objNull, grpNull]];

switch (typeName _unit) do
{
	case typeName objNull:
	{
		[_unit] call JB_DATE_ReplaceEquipment;
	};

	case typeName grpNull:
	{
		{
			[_x] call JB_DATE_ReplaceEquipment;
		} forEach units _unit;
	};
};