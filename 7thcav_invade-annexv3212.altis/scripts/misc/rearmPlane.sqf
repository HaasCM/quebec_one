private _plane = _this select 0;

if (not (_plane isKindOf "Plane")) exitWith { };

[_plane, [["repair", 60, 0.0], ["refuel", 60, 1.0], ["rearm", 60, magazinesAllTurrets _plane]]] call JB_fnc_serviceVehicle;