AmmoFilter_TransferToTrolley =
{
	private _candidate = _this select 1;

	// Look for either a player or the khaki and yellow trolleys
	if (not isPlayer _candidate && ((typeOf _candidate) find "Land_PalletTrolley_01_") != 0) exitWith { false };

	// That are in the loading bay area
	if (not (_candidate inArea Base_Supply_Loading_Bay)) exitWith { false };

	true;
};

AmmoFilter_TransferToAny =
{
	private _unit = _this select 0;
	private _candidate = _this select 1;

	true;
};