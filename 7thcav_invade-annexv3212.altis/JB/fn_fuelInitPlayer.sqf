private _unit = param [0, objNull, [objNull]];

_unit addAction ["Fuel vehicle", { [_this select 0, cursorTarget] call JBF_FuelVehicle }, nil, 10, true, true, "", "[cursorTarget] call JBF_FuelVehicleCondition"];
_unit addAction ["Release fuel line", { [_this select 0] call JBF_ReleaseAllFuelLines }, nil, 9, true, true, "", "[] call JBF_ReleaseAllFuelLinesCondition"];
_unit addAction ["Stop fueling", { [cursorTarget] call JBF_StopFuelingVehicle }, nil, 10, true, true, "", "[cursorTarget] call JBF_StopFuelingVehicleCondition"];