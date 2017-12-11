/*
Author: Quiksilver
Script Name: Soldier Tracker
Contact: camball@gmail.com || 
Created: 8/08/2014
Version: v1.0.1
Last modified: 13/10/2014 ArmA 1.30 by Quiksilver
*/

QS_fnc_iconColor =
{
	private _u = _this select 0;
	private _a = 0.5;

	if ((group _u) == (group player)) then { _a = 0.9 };

	if (lifeState _u == "INCAPACITATED") exitWith { [1.0, 0.4, 0, _a] };
	
	if (side _u == east) exitWith { [0.5, 0, 0, _a] };
	if (side _u == west) exitWith { [0, 0.3, 0.6, _a] };
	if (side _u == independent) exitWith { [0, 0.5, 0, _a] };
	if (side _u == civilian) exitWith { [0.4, 0, 0.5, _a] };

	[0.7, 0.6, 0, _a]
};

QS_fnc_iconType =
{
	private _vehicle = _this select 0;

	private _iconType = _vehicle getVariable "MAP_IconType";
	if (isNil "_iconType") then
	{
		_iconType = getText (configFile >> "CfgVehicles" >> typeOf _vehicle >> "icon");
		_vehicle setVariable ["MAP_IconType", _iconType];
	};

	_iconType;
};

QS_fnc_iconSize =
{
	private _vehicle = _this select 0;

	if (_vehicle isKindOf "Man") exitWith { 22 };
	if (_vehicle isKindOf "Ship") exitWith { 26 };

	28
};

QS_fnc_iconText =
{
	private _unit = _this select 0;

	private _text = "";

	if ((typeof _unit) isKindOf "Man") then
	{
		_text = name _unit;
	}
	else
	{
		if (unitIsUAV _unit) then
		{
			if (isUavConnected _unit) then
			{
				_text = name ((UAVControl _unit) select 0);
			};
		}
		else
		{
			private _crew = (crew _unit) select { isPlayer _x };

			private _representative = _crew select 0;
			private _additionsText = if (count _crew > 1) then { format [" + %1", (count _crew) - 1] } else { "" };

			_text = format ["%1%2", name _representative, _additionsText];
		};
	};

	private _unitType = _unit getVariable "MAP_UnitType";
	if (isNil "_unitType") then
	{
		if (isPlayer _unit && { (typeOf _unit) isKindOf "Man" }) then
		{
			_unitType = roleDescription _unit;

			private _paren = _unitType find "(";
			if (_paren >= 0) then
			{
				_unitType = _unitType select [0, _paren];
				_unitType = [_unitType, "end"] call JB_fnc_trimWhitespace;
			};
		}
		else
		{
			_unitType = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName");
		};
		_unit setVariable ["MAP_UnitType", _unitType];
	};

	format ["[%1] %2", _unitType, _text]
};

//======================== DRAW MAP

QS_fnc_iconDrawMap =
{
	private _control = _this select 0;

	private ["_v","_iconType","_color","_pos","_iconSize","_dir","_text","_shadow","_textSize","_textFont","_textOffset","_units"];
	_shadow = 1;
	_textSize = 0.05;
	_textFont = "puristaMedium";
	_textOffset = "right";

	{
		_v = vehicle _x;

		if ((side _v == playerSide) || { captive _x }) then
		{
			_iconType = [_v] call QS_fnc_iconType;
			_color = [_x] call QS_fnc_iconColor;
			_pos = getPosASL _v;
			_iconSize = [_v] call QS_fnc_iconSize;
			_dir = getDir _v;
			_text = [_v] call QS_fnc_iconText;
					
			if (_x == crew _v select 0 || { _x in allUnitsUav }) then
			{	
				_this select 0 drawIcon [
					_iconType,
					_color,
					_pos,
					_iconSize,
					_iconSize,
					_dir,
					_text,
					_shadow,
					_textSize,
					_textFont,
					_textOffset
				]
			};
		};
	} count (playableUnits + switchableUnits + allUnitsUav);
};

//======================== DRAW GPS

QS_fnc_iconDrawGPS =
{
	private _control = _this select 0;

	private ["_v","_iconType","_color","_pos","_iconSize","_dir","_text","_shadow","_textSize","_textFont","_textOffset"];
	_text = "";
	_shadow = 1;
	_textSize = 0.05;
	_textFont = "puristaMedium";
	_textOffset = "right";

	{
		_v = vehicle _x;
		if ((side _v == playerSide) || {(captive _x)}) then
		{
			if ((_x distanceSqr player) < 300 * 300) then
			{
				_iconType = [_v] call QS_fnc_iconType;
				_color = [_x] call QS_fnc_iconColor;
				_pos = getPosASL _v;
				_iconSize = [_v] call QS_fnc_iconSize;
				_dir = getDir _x;
					
				if (_x == driver _v || { _x in allUnitsUav }) then
				{	
					_this select 0 drawIcon [
						_iconType,
						_color,
						_pos,
						_iconSize,
						_iconSize,
						_dir,
						_text,
						_shadow,
						_textSize,
						_textFont,
						_textOffset
					]
				};
			};
		};
	} count (playableUnits + switchableUnits + allUnitsUav);
};

//=============================================================== INITIALIZATION

[] spawn {
	sleep 0.1;
	
	//===== INIT MAP
	
	waitUntil {sleep 0.1; !(isNull (findDisplay 12))};
	clientEhDrawMap = ((findDisplay 12) displayCtrl 51) ctrlAddEventHandler ["Draw", QS_fnc_iconDrawMap];
	
	//===== INIT GPS (waits for GPS to open)
	
	disableSerialization;
	_gps = controlNull;
	while {isNull _gps} do
	{
		{
			if !(isNil {_x displayctrl 101}) then {
				_gps = _x displayctrl 101
			};
		} count (uiNamespace getVariable "IGUI_Displays");
		sleep 1;
	};
	clientEhDrawGps = _gps ctrlAddEventHandler ["Draw", QS_fnc_iconDrawGPS];
	
	//===== INIT RESPAWN MENU MAP - UNSUPPORTED v1.0.0
	//===== INIT ZEUS MAP - UNSUPPORTED v1.0.0
	//===== INIT ARTILLERY COMPUTER - UNSUPPORTED v1.0.0
	//===== INIT UAV TERMINAL MAP - UNSUPPORTED v1.0.0
};
