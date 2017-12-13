private _type = _this select 0;
private _message = _this select 1;
private _location = _this select 2;
private _range = _this select 3;

if (player distance _location < _range) then
{
	[_type, [_message]] call BIS_fnc_showNotification;
};