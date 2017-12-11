HALO_AO =
{
	private _vehicle = _this select 0;

	if (currentAO == "") exitWith { ["", [0,0,0], 0] };

	private _dropPosition = getMarkerPos currentAO;
	private _vehiclePosition = getPos _vehicle;

	private _distanceToAO = (_vehiclePosition distance _dropPosition) - PARAMS_AOSize;

	if (defendAO == "") then
	{
		private _vectorToAO = _vehiclePosition vectorFromTo _dropPosition;
		_dropPosition = _vehiclePosition vectorAdd (_vectorToAO vectorMultiply _distanceToAO);
	};

	_dropPosition set [2, 2000];

	// Assume a 200km/h trip
	private _nominalVehicleSpeedKMH = 200; // km/h
	private _nominalVehicleSpeedMS = _nominalVehicleSpeedKMH / 3600 * 1000; // m/s

	// Add 90 seconds for each multiple of transport seats available versus the number of players online (e.g 20 seats vs 40 players = 0.5 * 90 seconds)
	private _numberTransportSeats = 0;
	{ if (typeOf _x == "B_Helipilot_F" && vehicle _x isKindOf "Air" && _x == driver vehicle _x) then { _numberTransportSeats = _numberTransportSeats + count fullCrew [_vehicle, "cargo", true] }} forEach allPlayers;
	private _ratioTransportSeatsToPlayers = _numberTransportSeats / count allPlayers;

	
	private _delayInSeconds = (_distanceToAO / _nominalVehicleSpeedMS) + _ratioTransportSeatsToPlayers * 90;

	[currentAO, _dropPosition, _delayInSeconds]
};

[_this select 0,
	{
		[_this select 0, "green", []] call BIS_fnc_initVehicle;
		(_this select 0) lockDriver true;
		(_this select 0) lockTurret [[0], true];
		(_this select 0) animateDoor ["door_rear_source", 1];
		[[_this select 0], HALO_AO] call JB_fnc_haloInit;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;