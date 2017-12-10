/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

TRACE_ObjectStrings = [];
TRACE_ObjectPositions = [];

TRACE_C_SetObjectValue =
{
	params ["_keyObject", "_keyName", "_keyValue", "_valueType"];

	private _list = if (_valueType == "string") then { TRACE_ObjectStrings } else { TRACE_ObjectPositions };

	private _index = -1;
	{
		private _object = _x select 0;
		if (_object == _keyObject) exitWith { _index = _forEachIndex };
	} forEach _list;

	if (_index == -1) then
	{
		if (not isNil "_keyValue") then
		{
			_list pushBack [_keyObject, [[_keyName, _keyValue]]];
		};
	}
	else
	{
		private _namedValues = _list select _index select 1;
		private _keyNameIndex = [_namedValues, _keyName] call BIS_fnc_findInPairs;
		if (_keyNameIndex == -1) then
		{
			if (not isNil "_keyValue") then
			{
				_namedValues pushBack [_keyName, _keyValue];
			};
		}
		else
		{
			if (not isNil "_keyValue") then
			{
				(_namedValues select _keyNameIndex) set [1, _keyValue];
			}
			else
			{
				_namedValues deleteAt _keyNameIndex;
			};
		};
	};
};

TRACE_DrawObjectValues =
{
	if (CLIENT_CuratorType != "GM" || { (getPos curatorCamera) select 0 == 0 }) exitWith {}; // Only for gamemaster curators when in Zeus

	private _objectString = [];
	private _position = [];
	private _fullLine = "";

	for "_i" from (count TRACE_ObjectStrings - 1) to 0 step -1 do
	{
		_objectString = TRACE_ObjectStrings select _i;

		if (isNull (_objectString select 0)) then
		{
			TRACE_ObjectStrings deleteAt _i;
		}
		else
		{
			_position = getPosVisual (_objectString select 0);
			_position set [2, getPosATL (_objectString select 0) select 2];
			_fullLine = ((_objectString select 1) apply { _x select 1 }) joinString ", ";
			drawIcon3D ["", [1,1,1,1], _position, 0, 0, 0, _fullLine, 1, 0.04, "PuristaMedium"];
		};
	};

	private _objectPosition = [];

	for "_i" from (count TRACE_ObjectPositions - 1) to 0 step -1 do
	{
		_objectPosition = TRACE_ObjectPositions select _i;

		if (isNull (_objectPosition select 0)) then
		{
			TRACE_ObjectPositions deleteAt _i;
		}
		else
		{
			_position = getPosATL (_objectPosition select 0) vectorAdd [0, 0, 5];

			{
				drawLine3D [_position, _x, [1,1,1,1]];
			} forEach (_x select 1);
		};
	};
};

if (not isServer) exitWith {};

TRACE_SetObjectString =
{
	params ["_keyObject", "_keyName", "_keyValue"];

	[[_keyObject, _keyName, if (isNil "_keyValue") then { nil } else { _keyValue }, "string"], "TRACE_C_SetObjectValue", "GM"] call SERVER_RemoteExecCurators;
};

TRACE_SetObjectPosition =
{
	params ["_keyObject", "_keyName", "_keyValue"];

	[[_keyObject, _keyName, if (isNil "_keyValue") then { nil } else { _keyValue }, "position"], "TRACE_C_SetObjectValue", "GM"] call SERVER_RemoteExecCurators;
};