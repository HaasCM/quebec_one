private _uid = _this select 0;

private _uidGameMasters =
[
	"76561198263111962", // SirBaconPoop
	"76561198221093644", // Big Red
	"76561197988600770", // Grimes
	"76561198174640679"  // Bowman
];

if (_uid in _uidGameMasters) exitWith { "GM" };

private _uidMilitaryPolice =
[
	"76561198263111962", // SirBaconPoop
	"76561198221093644", // Big Red
	"76561197988600770", // Grimes
	"76561198174640679"  // Bowman
];

if (_uid in _uidMilitaryPolice) exitWith { "MP" };

""