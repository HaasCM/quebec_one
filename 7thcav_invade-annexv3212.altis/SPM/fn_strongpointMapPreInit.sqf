/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

SPM_Map_CreateStatusGrid =
{
	private _gridCorner = _this select 0;
	private _gridSize = _this select 1;

	private _gridValues = [];

	for "_x" from (_gridCorner select 0) to (_gridCorner select 0) + (_gridSize select 0) - 1 do
	{
		private _row = [];
		for "_y" from (_gridCorner select 1) to (_gridCorner select 1) + (_gridSize select 1) - 1 do
		{
			_row pushBack [false, false, false];
		};
		_gridValues pushBack _row;
	};

	[_gridCenter, _gridCorner, _gridSize, _gridValues]
};

SPM_Map_GetStatusGridCell =
{
	private _position = _this select 0;

	private _gridCorner = SPM_StatusGrid select 1;
	private _gridSize = SPM_StatusGrid select 2;
	private _gridCells = SPM_StatusGrid select 3;

	private _playerCell = [floor ((_position select 0) / 100), floor ((_position select 1) / 100)];

	private _gridCell = [];
	if ([_playerCell select 0, _gridCorner select 0, (_gridCorner select 0) + (_gridSize select 0) - 1] call SPM_Util_InValueRange) then
	{
		if ([_playerCell select 1, _gridCorner select 1, (_gridCorner select 1) + (_gridSize select 1) - 1] call SPM_Util_InValueRange) then
		{
			private _gridX = (_playerCell select 0) - (_gridCorner select 0);
			private _gridY = (_playerCell select 1) - (_gridCorner select 1);
			_gridCell = (_gridCells select _gridX) select _gridY;
		};
	};

	_gridCell
};

SPM_Map_UpdateStatusGrid =
{
	private _center = _this select 0;
	private _size = _this select 1;

	private _gridCenter = [floor ((_center select 0) / 100), floor ((_center select 1) / 100)];

	private _gridSize = [round ((_size select 0) / 100), round ((_size select 1) / 100)];
	private _gridCorner = [(_gridCenter select 0) - round ((_gridSize select 0) / 2), (_gridCenter select 1) - round ((_gridSize select 1) / 2)];

	if (isNil "SPM_StatusGrid") then
	{
		SPM_StatusGrid = ([_gridCorner, _gridSize] call SPM_Map_CreateStatusGrid)
	};

	{
		if (lifeState _x in ["HEALTHY", "INJURED"]) then
		{
			private _gridCell = [getPos _x] call SPM_Map_GetStatusGridCell;
			if (count _gridCell > 0) then
			{
				_gridCell set [1, true];
				_gridCell set [2, true];
			};
		};
	} forEach allPlayers;
};

SPM_Map_GetStatusMarker =
{
	private _x = _this select 0;
	private _y = _this select 1;
	private _suffix = param [2, "", [""]];
	private _create = param [3, true, [true]];

	private _markerName = format ["SPM_StatusMarker%1%2-%3", _suffix, _x, _y];
	private _markerExists = (getMarkerColor _markerName != "");

	if (not _markerExists) then
	{
		if (not _create) then
		{
			_markerName = "";
		}
		else
		{
			createMarker [_markerName, _gridCellCenter];
			_markerName setMarkerShape "rectangle";
			_markerName setMarkerSize [50, 50];
			_markerName setMarkerAlpha 0.5;
		};
	};

	_markerName
};

SPM_Map_GridContainsLand =
{
	private _gridCenter = _this select 0;

	private _gridX = _gridCenter select 0;
	private _gridY = _gridCenter select 1;

	if (not surfaceIsWater [_gridX - 50, _gridY - 50, 0]) exitWith { true };
	if (not surfaceIsWater [_gridX + 50, _gridY - 50, 0]) exitWith { true };
	if (not surfaceIsWater [_gridX + 50, _gridY + 50, 0]) exitWith { true };
	if (not surfaceIsWater [_gridX - 50, _gridY + 50, 0]) exitWith { true };

	false;
};

SPM_Map_UpdateStatusDisplay =
{
	private _center = _this select 0;
	private _size = _this select 1;

	[_center, _size] call SPM_Map_UpdateStatusGrid;

	private _gridCorner = SPM_StatusGrid select 1;
	private _gridSize = SPM_StatusGrid select 2;
	private _gridCells = SPM_StatusGrid select 3;

	private _gridCenter = [floor ((_center select 0) / 100), floor ((_center select 1) / 100), 0];

	private _x = 0;
	private _y = 0;
	private _gridRow = [];
	private _gridCellCenter = [];

	for "_gx" from 0 to (_gridSize select 0) - 1 do
	{
		_x = (_gridCorner select 0) + _gx;

		_gridRow = _gridCells select _gx;
		for "_gy" from 0 to (_gridSize select 1) - 1 do
		{
			_y = (_gridCorner select 1) + _gy;

			_gridCellCenter = [_x * 100 + 50, _y * 100 + 50, 0];
			if ([_gridCellCenter] call SPM_Map_GridContainsLand) then
			{
				private _gridCell = _gridRow select _gy;
				private _enemyFired = _gridCell select 0;
				_gridCell set [0, false];
				private _playersPresent = _gridCell select 1;
				_gridCell set [1, false];
				private _playerControlled = _gridCell select 2;

				if (_enemyFired) then
				{
					private _marker = [_x, _y, "Fired"] call SPM_Map_GetStatusMarker;
					if (markerColor _marker != "ColorEAST") then
					{
						_marker setMarkerColor "ColorEAST";
					};
				}
				else
				{
					private _marker = [_x, _y, "Fired", false] call SPM_Map_GetStatusMarker;
					if (_marker != "") then
					{
						deleteMarker _marker;
					};
				};


				private _markerColor = if (_playersPresent || _playerControlled) then	{ "ColorWEST" } else { "ColorEAST" };

				private _marker = [_x, _y] call SPM_Map_GetStatusMarker;

				if (markerColor _marker != _markerColor) then
				{
					_marker setMarkerColor _markerColor;
				};
			};
		};
	};
};

SPM_Map_DisplayGrid =
{
	private _targetPosition = getMarkerPos "TARGETAREA";
	private _targetSize = getMarkerSize "TARGETAREA";

	_targetSize = [(_targetSize select 0) * 2, (_targetSize select 1) * 2];

	if (isNil "SPM_ContinueMapUpdates" || { not SPM_ContinueMapUpdates }) then
	{
		SPM_ContinueMapUpdates = true;

		while { SPM_ContinueMapUpdates } do
		{
			[_targetPosition, _targetSize] call SPM_Map_UpdateStatusDisplay;
			[10, 0.1, { not SPM_ContinueMapUpdates }] call SPM_Util_TimeoutWait;
		};
	};
};

SPM_Map_CreatePolylineLocal =
{
	// Lifted from https://forums.bistudio.com/forums/topic/156725-script-draw-and-write-to-map/

	params ["_positions", "_width", "_color"];

	private _markers = [];

	private _markerNumber = 0;
	private ["_center", "_direction", "_length", "_marker"];

	for "_i" from 0 to count _positions - 2 do
	{
		private _center = (_positions select _i) vectorAdd (_positions select (_i + 1)) vectorMultiply 0.5;
		private _direction = (_positions select _i) getDir (_positions select (_i + 1));
		private _length = (_positions select _i) distance (_positions select (_i + 1));

		for "_n" from _markerNumber to 1e4 do
		{
			_marker = format ["SPM_Polyline_%1", _n];
			if (markerShape _marker == "") exitWith { _markerNumber = _n };
		};

		createMarkerLocal [_marker, _center];
		_marker setMarkerShapeLocal "RECTANGLE";
		_marker setMarkerBrushLocal "SolidFull";
		_marker setMarkerSizeLocal [_width / 2, _length / 2];
		_marker setMarkerDirLocal _direction;
		_marker setMarkerColorLocal _color;
		_markers set [count _markers, _marker];
	};

	{
		for "_n" from _markerNumber to 1e4 do
		{
			_marker = "SPM_Polyline_" + str _n;
			if (markerShape _marker == "") exitWith { _markerNumber = _n };
		};

		createMarkerLocal [_marker, _x];
		_marker setMarkerShapeLocal "ELLIPSE";
		_marker setMarkerBrushLocal "SolidFull";
		_marker setMarkerSizeLocal [_width / 2, _width / 2];
		_marker setMarkerColorLocal _color;
		_markers set [count _markers, _marker];
	} forEach _positions;

	_markers
};

SPM_Map_DeletePolylineLocal =
{
	params ["_polyline"];

	{
		deleteMarkerLocal _x;
	} forEach _polyline;
}