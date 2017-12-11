JB_FV_Flip =
{
	private _vehicle = _this select 0;

	private _vehiclePosition = getPosATL _vehicle;
	_vehicle setPos [-10000 - random 10000, -10000 - random 10000, 1000 + random 10000];
	_vehicle setPosATL (_vehiclePosition vectorAdd [0,0,1]);
};