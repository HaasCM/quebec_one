if (!isServer) exitWith {};

private _vehicle = (_this select 0);
private _grpSize = (_this select 1);
private _grp = (_this select 2);
private _faction = (_this select 3);
private _cargoType = (_this select 4);
private _debug = false;

private _cargoPool = [_faction,_cargoType] call eos_fnc_getunitpool;

// FILL EMPTY SEATS
private _emptySeats=_vehicle emptyPositions "cargo";

if (_debug) then {hint format ["%1", _emptySeats];};

//GET MIN MAX GROUP
private _grpMin = _grpSize select 0;
private _grpMax = _grpSize select 1;
private _d = _grpMax-_grpMin;				
private _r = floor(random _d);
_grpSize = _r + _grpMin;

// IF VEHICLE HAS SEATS
if (_emptySeats > 0) then
{
	// LIMIT SEATS TO FILL TO GROUP SIZE		
	if 	(_grpSize > _emptySeats) then {_grpSize = _emptySeats};					
	if (_debug) then {hint format ["Seats Filled : %1",_grpSize];};	

	for "_x" from 1 to _grpSize do
	{
		_unit=_cargoPool select (floor(random(count _cargoPool)));
		_unit=_unit createUnit [GETPOS _vehicle, _grp];
	};							

	{_x moveincargo _vehicle} foreach units _grp;

	[units _grp] call SERVER_CurateEditableObjects;
};						