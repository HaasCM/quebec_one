params ["_position", "_areaPosition", "_areaWidth", "_areaHeight", "_areaAngle"];

private _distance = 0;

private _relative = _position vectorDiff _areaPosition;

private _x = (_relative select 0) * cos _areaAngle - (_relative select 1) * sin _areaAngle;
private _y = (_relative select 0) * sin _areaAngle + (_relative select 1) * cos _areaAngle;

_x = abs _x;
_y = abs _y;

if (_x <= _areaWidth) exitWith
{
	(_y - _areaHeight) max 0
};

if (_y <= _areaHeight) exitWith
{
	(_x - _areaWidth) max 0;
};

[_x, _y, 0] distance2D [_areaWidth, _areaHeight, 0]