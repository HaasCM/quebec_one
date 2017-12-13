private _hint = _this select 0;
private _location = _this select 1;
private _range = _this select 2;

if (player distance _location < _range) then
{
	hint parseText _hint;
};