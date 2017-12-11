private ["_obj"];

private _vehicles = [];
{
	sleep 0.3;

    if (typeName _x == "Group") then
	{
		_vehicles = [];

		// We want to delete vehicles first, then group members, then group
        {
			_vehicle = vehicle _x;
            if (_vehicle != _x && { not (_vehicle in _vehicles) }) then
			{
                _vehicles pushBack (vehicle _x);
            };
        } forEach (units _x);

		// When deleting a vehicle, delete its crew first
		{
			{deleteVehicle _x} forEach crew _x;
			deleteVehicle _x;
		} forEach _vehicles;
		_vehicles = [];

		// Delete the group units
		{deleteVehicle _x} foreach units _x;

		// Delete the group
		deleteGroup _x;
    }
	else
	{
        if !(_x isKindOf "Man") then
		{
            {
                deleteVehicle _x;
            } forEach (crew _x);
        };
        deleteVehicle _x;
    };
} forEach (_this select 0);