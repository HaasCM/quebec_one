private _unit = _this select 0;

_unit setVariable ["SupplyType", "arsenal", true];

["AmmoboxInit", [_unit, true]] call BIS_fnc_arsenal;

[_unit, [true], true] call BIS_fnc_removeVirtualBackpackCargo;
[_unit, [true], true] call BIS_fnc_removeVirtualItemCargo;
[_unit, [true], true] call BIS_fnc_removeVirtualWeaponCargo;

private _permittedGear = [] call compile preprocessFileLineNumbers "scripts\arsenalGear.sqf";

[_unit, _permittedGear select 0, true] call BIS_fnc_addVirtualWeaponCargo;
[_unit, _permittedGear select 1, true] call BIS_fnc_addVirtualBackpackCargo;
[_unit, (_permittedGear select 2) + (_permittedGear select 3), true] call BIS_fnc_addVirtualItemCargo;