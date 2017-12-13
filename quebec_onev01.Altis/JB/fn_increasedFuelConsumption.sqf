#define POLL_INTERVAL 0.2

// Liters per second per RPM
JBIFC_FuelConsumptionRate =
{
	private _vehicle = _this select 0;

	private _vehicleArmored = (getText (configFile >> "CfgVehicles" >> (typeOf vehicle player) >> "vehicleClass") == "Armored");

	private _vehicleTracked = (getNumber (configFile >> "CfgVehicles" >> (typeOf vehicle player) >> "tracksSpeed") != 0);

	private _vehicleMass = getMass _vehicle;

	private _vehicleSize = sizeOf (typeOf _vehicle) / 2;

	private _vehicleDensity = _vehicleMass / (4.18 * _vehicleSize * _vehicleSize * _vehicleSize);

	private _fuelConsumption = _vehicleDensity;

	if (_vehicleArmored) then { _fuelConsumption = _fuelConsumption * 2 };
	if (_vehicleTracked) then { _fuelConsumption = _fuelConsumption * 2 };

	_fuelConsumption = _fuelConsumption * 4e-9;

	_fuelConsumption min 1.7e-7
};

JBIFC_Start =
{
	private _vehicle = _this select 0;

	private _fuelConsumption = [_vehicle] call JBIFC_FuelConsumptionRate;

	private _rpm = 0;
	while { (vehicle player) == _vehicle && { player == driver _vehicle } } do
	{
		_rpm = _vehicle getSoundController "rpm";
		_vehicle setFuel (fuel _vehicle) - _rpm * _fuelConsumption * POLL_INTERVAL;
		sleep POLL_INTERVAL;
	};
};

player addEventHandler ["GetInMan", { if (player == driver (vehicle player)) then { [vehicle player] spawn JBIFC_Start } }];
player addEventHandler ["SeatSwitchedMan", { if (player == driver (vehicle player)) then { [vehicle player] spawn JBIFC_Start } }];