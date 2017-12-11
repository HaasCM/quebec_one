/*
@file: fn_AOminefield.sqf
Author:

	Quiksilver (credit Rarek [ahoyworld] for initial build)
	
Description:

	Spawn a minefield around radio tower sub-objective
	
________________________________________________________________*/

#define MINE_TYPES "APERSBoundingMine", "APERSMine", "ATMine"

private _centralPos = _this select 0;
private _mineField = [];

for "_x" from 0 to 59 do
{
        _mine = createMine [[MINE_TYPES] call BIS_fnc_selectrandom, _centralPos, [], 38];
        _mineField = _mineField + [_mine];
};

private _distance = 40;
private _direction = 180;

for "_c" from 0 to 23 do {
    _pos = [_centralPos, _distance, _direction] call BIS_fnc_relPos;
    _razorwire = "Land_Razorwire_F" createVehicle _pos;
    waitUntil {alive _razorwire};

    _razorwire setDir _direction;
	_razorwire enableSimulation false;
	_razorwire allowDamage false;

    _direction = _direction + 15;
        
    _mineField = _mineField + [_razorwire];
};

_mineField