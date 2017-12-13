private _message = _this select 0;
private _location = _this select 1;
private _range = _this select 2;

if (player distance _location < _range) then
{
	[WEST, "HQ"] sideChat _message;
};