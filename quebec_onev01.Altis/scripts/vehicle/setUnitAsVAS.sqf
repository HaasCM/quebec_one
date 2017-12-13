private _unit = _this select 0;

_unit setVariable ["SupplyType", "vas", true];

_unit addAction ["VAS", "VAS\open.sqf", [], 10, true, true, "", "(vehicle _this == _this)", 4];