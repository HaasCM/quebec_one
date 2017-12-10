private _vehicle = _this select 0;

private _return = false;

if (_vehicle isKindOf "LandVehicle" || _vehicle isKindOf "Helicopter" || _vehicle isKindOf "Ship") then
{
	if (player == (driver _vehicle) || player == (commander _vehicle) || player == (gunner _vehicle)) then
	{
		_return = true;
	};
};

_return;