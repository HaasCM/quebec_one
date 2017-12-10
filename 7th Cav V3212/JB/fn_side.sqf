private _source = _this select 0;

if (typeName _source == typeName "") exitWith
{
	private _sides =
	[
		["UNKNOWN", sideUnknown],
		["EAST", east],
		["WEST", west],
		["GUER", resistance],
		["CIV", civilian],
		["EMPTY", sideEmpty],
		["ENEMY", sideEnemy],
		["FRIENDLY", sideFriendly],
		["LOGIC", sideLogic]
	];

	_source = toUpper _source;
	{
		if (_x select 0 == _source) exitWith { _x select 1 };
	} forEach _sides;
};

if (typeName _source == typeName 0) exitWith
{
	private _sides =
	[
		[-1, sideUnknown],
		[0, east],
		[1, west],
		[2, resistance],
		[3, civilian],
		[4, sideEmpty],
		[5, sideEnemy],
		[6, sideFriendly],
		[7, sideLogic]
	];

	{
		if (_x select 0 == _source) exitWith { _x select 1 };
	} forEach _sides;
};