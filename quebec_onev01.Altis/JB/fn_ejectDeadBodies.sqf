/*
	Eject dead bodies from a vehicle, regardless of their origin (AI, disconnected player, etc)

	[vehicle] call JB_fnc_ejectDeadBodies

	vehicle - the vehicle from which any bodies should be ejected

	In order to call this function, the mission must have a character called "Ejector".  The character
	should have all "Special States" unchecked and may be placed anywhere on the map.  Ideally, that
	location should be well out of the way of the mission (inside an indestructible building, at the
	map origin, etc.)

	Note that AI bodies will appear on the ground next to the vehicle while disconnected player bodies
	and other such cases will simply vanish.
*/

if (!canSuspend) then
{
	_this spawn JB_fnc_ejectDeadBodies;
}
else
{
	private _vehicle = param [0, objNull, [objNull]];

	private _position = getPos Ejector;

	private _movingIn = true;

	{
		if (!(alive (_x select 0))) then
		{
			_movingIn = true;
			switch (_x select 1) do
			{
				case "driver":
				{
					Ejector moveInDriver _vehicle;
				};
				case "gunner":
				{
					Ejector moveInGunner _vehicle;
				};
				case "commander":
				{
					Ejector moveInCommander _vehicle;
				};
				case "cargo":
				{
					Ejector moveInCargo [_vehicle, _x select 2];
				};
				case "Turret":
				{
					Ejector moveInTurret [_vehicle, _x select 3];
				};
				default
				{
					_movingIn = false; // Don't hang if there are any surprises
				};
			};

			if (_movingIn) then
			{
				waitUntil { vehicle Ejector == _vehicle };
				Ejector action ["eject", _vehicle];
				waitUntil { vehicle Ejector != _vehicle };
			};
		};
	} forEach fullCrew _vehicle;

	Ejector setPos _position;
};