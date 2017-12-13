private _addMagazine =
{
	private _magazines = _this select 0;
	private _magazine = _this select 1;

	private _displayName = toLower getText (configFile >> "CfgMagazines" >> _magazine >> "displayName");
	if (_displayName find "green" == -1 && _displayName find "yellow" == -1) then
	{
		if (getText (configFile >> "CfgMagazines" >> _magazine >> "picture") != "") then
		{
			_magazines pushBackUnique _magazine;
		};
	};
};

private _gear = [] call compile preprocessFile "scripts\whitelistGear.sqf";

private _magazines = [];
{
	{
		[_magazines, _x] call _addMagazine;
	} forEach (getArray (configFile >> "CfgWeapons" >> _x >> "magazines"));

	if (isClass (configFile >> "CfgWeapons" >> _x >> "Secondary")) then
	{
		{
			[_magazines, _x] call _addMagazine;
		} forEach (getArray (configFile >> "CfgWeapons" >> _x >> "Secondary" >> "magazines"))
	};
} forEach (_gear select 0);

_magazines