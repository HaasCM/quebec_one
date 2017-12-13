/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

SPM_NeighborDirections =
{
	params ["_road"];

	private _neighborDirections = [];
	{
		_neighborDirections pushBack [_road getDir _x, _x];
	} forEach roadsConnectedTo _road;

	_neighborDirections;
};

SPM_RoadFollow =
{
	params ["_road", "_position", "_direction", "_distance"];

	private _distanceSqr = _distance * _distance;

	private _neighborDirections = [_road] call SPM_NeighborDirections;

	{
		private _sweep = ([_x select 0, _direction] call SPM_Util_MinimumSweepAngle);

		_x set [2, _x select 1];
		_x set [1, _x select 0];
		_x set [0, _sweep];
	} forEach _neighborDirections;

	_neighborDirections sort true;

	if ((_neighborDirections select 0) select 0 > 60) exitWith { [objNull, 0] };

	private _run = [_road, (_neighborDirections select 0) select 2, getPos _road, 300] call SPM_Nav_RoadRun;

	private _destination = [objNull, 0];
	private _lastRoad = _road;
	{
		if (_x distanceSqr _position > _distanceSqr) exitWith { _destination = [_x, _lastRoad getDir _x] };
		_lastRoad = _x;
	} forEach _run;

	if (isNull (_destination select 0)) then
	{
		_destination = [_run select (count _run - 1), _position, (_run select (count _run - 2)) getDir (_run select (count _run - 1)), _distance] call SPM_RoadFollow;
	};

	_destination
};

SPM_ExecutePatrolWaypointStatements =
{
	params ["_leader"];

//	diag_log format ["SPM_ExecutePatrolWaypointStatements"];

	private _group = group _leader;

	private _waypointStatements = _group getVariable ["SPM_WaypointStatements", []];

//	diag_log format ["SPM_ExecutePatrolWaypointStatements: waypointStatements: %1", count _waypointStatements];

	private _executeList = [];
	for "_i" from count _waypointStatements - 1 to 0 step -1 do
	{
		private _x = _waypointStatements select _i;
		if (_x select 0 == currentWaypoint _group) then
		{
			_executeList pushBack (_x select 1);
			_waypointStatements deleteAt _i;
		};
	};

	if (count _waypointStatements == 0) then
	{
		_group setVariable ["SPM_WaypointStatements", nil];
	}
	else
	{
		_group setVariable ["SPM_WaypointStatements", _waypointStatements];
	};

//	diag_log format ["SPM_ExecutePatrolWaypointStatements: executeList: %1", count _executeList];

	{
		[_leader, units _group, _x select 1] call (_x select 0);
	} forEach _executeList;
};

SPM_AddPatrolWaypointStatements =
{
	params ["_waypoint", "_statements", "_passthrough"];

	if (isNil "_passthrough") then { _passthrough = [] };

	private _group = _waypoint select 0;
	private _waypointNumber = _waypoint select 1;

	private _waypointStatements = _group getVariable ["SPM_WaypointStatements", []];
	_waypointStatements pushBack [_waypointNumber, [_statements, _passthrough]];
	_group setVariable ["SPM_WaypointStatements", _waypointStatements];
};

SPM_AddPatrolWaypoint =
{
	params ["_group", "_position"];

	private _waypoint = _group addWaypoint [_position, 0];
	_waypoint setWaypointStatements ["true", "[this] call SPM_ExecutePatrolWaypointStatements"];

	_waypoint;
};

SPM_ReinstatePatrolWaypoint =
{
	params ["_waypoint"];

	private _behaviour = waypointBehaviour _waypoint;
	private _combatMode = waypointCombatMode _waypoint;
	private _completionRadius = waypointCompletionRadius _waypoint;
	private _description = waypointDescription _waypoint;
	private _forceBehaviour = waypointForceBehaviour _waypoint;
	private _formation = waypointFormation _waypoint;
	private _housePosition = waypointHousePosition _waypoint;
	private _loiterRadius = waypointLoiterRadius _waypoint;
	private _loiterType = waypointLoiterType _waypoint;
	private _name = waypointName _waypoint;
	private _position = waypointPosition _waypoint;
	private _script = waypointScript _waypoint;
	private _speed = waypointSpeed _waypoint;
	private _statements = waypointStatements _waypoint;
	private _timeout = waypointTimeout _waypoint;
	private _type = waypointType _waypoint;
	private _visible = waypointVisible _waypoint;

	private _synchronizedWaypoints = synchronizedWaypoints _waypoint;
	private _attachedVehicle = waypointAttachedVehicle _waypoint;
	private _attachedObject = waypointAttachedVehicle _waypoint;

	private _group = _waypoint select 0;
	private _index = _waypoint select 1;

	deleteWaypoint _waypoint;

	private _newWaypoint = _group addWaypoint [_position, _completionRadius, _index];
	_newWaypoint setWaypointBehaviour _behaviour;
	_newWaypoint setWaypointCombatMode _combatMode;
	_newWaypoint setWaypointCompletionRadius _completionRadius;
	_newWaypoint setWaypointDescription _description;
	_newWaypoint setWaypointForceBehaviour _forceBehaviour;
	_newWaypoint setWaypointFormation _formation;
	_newWaypoint setWaypointHousePosition _housePosition;
	_newWaypoint setWaypointLoiterRadius _loiterRadius;
	_newWaypoint setWaypointLoiterType _loiterType;
	_newWaypoint setWaypointName _name;
	_newWaypoint setWaypointPosition _position;
	_newWaypoint setWaypointScript _script;
	_newWaypoint setWaypointSpeed _speed;
	_newWaypoint setWaypointStatements _statements;
	_newWaypoint setWaypointTimeout _timeout;
	_newWaypoint setWaypointType _type;
	_newWaypoint setWaypointVisible _visible;

	if (not isNull _attachedVehicle) then
	{
		_newWaypoint waypointAttachVehicle _attachedVehicle;
	};

	if (not isNUll _attachedObject) then
	{
		_newWaypoint waypointAttachObject _attachedObject;
	};

	if (count _synchronizedWaypoints > 0) then
	{
		_newWaypoint synchronizeWaypoint _synchronizedWaypoints;
	};
};

SPM_DeletePatrolWaypoints =
{
	params ["_group"];

	private _waypoints = waypoints _group;
	if (count _waypoints > 0) then
	{
		(_waypoints select 0) setWaypointPosition [getPos leader _group, 0];
		sleep 0.1;

		for "_i" from (count _waypoints - 1) to 0 step -1 do
		{
			deleteWaypoint (_waypoints select _i);
		};
	};

	_group setVariable ["SPM_WaypointStatements", []];
};

SPM_StopWaypointMonitor =
{
	params ["_group"];

	_group setVariable ["SPM_StopWaypointMonitor", true];
};

SPM_StartWaypointMonitor =
{
	params ["_group"];

	_group setVariable ["SPM_StopWaypointMonitor", nil];

	[_group] spawn
	{
		params ["_group"];

		private _lastLeaderPosition = getPosATL leader _group;

		sleep 5;

		private _shoveCount = 0;
		private _shoveWaypoint = -1;

		while { { alive _x } count units _group > 0 } do
		{
			private _stop = _group getVariable ["SPM_StopWaypointMonitor", false];
			if (_stop) exitWith
			{
				_group setVariable ["SPM_StopWaypointMonitor", nil];
			};

			private _leader = leader _group;

			if (alive _leader && { vehicle _leader == _leader } && { behaviour _leader in ["CARELESS", "SAFE"] }) then
			{
				private _leaderPosition = getPosATL _leader;

				if (_leaderPosition distanceSqr _lastLeaderPosition < 1.0) then
				{
					private _waypointPosition = waypointPosition [_group, currentWaypoint _group];
					if (_leaderPosition distanceSqr _waypointPosition < 4) then
					{
						_leader setPosATL _waypointPosition;
					}
					else
					{
						private _leaderDirection = direction _leader;
						_leader setPos (_leaderPosition vectorAdd [(sin _leaderDirection) * 1.0, (cos _leaderDirection) * 1.0, 0.0]);

						if (_shoveWaypoint != currentWaypoint _group) then
						{
							_shoveWaypoint = currentWaypoint _group;
							_shoveCount = 1;
						}
						else
						{
							_shoveCount = _shoveCount + 1;
							if (_shoveCount == 3) then
							{
								_leader setPosATL _waypointPosition;
							};
						};
					};
				};

				_lastLeaderPosition = _leaderPosition;
			};

			sleep 2;
		};
	};
};

SPM_TaskComplete =
{
	params ["_task"];

	if (_task select 1 == 0) then
	{
		_task set [1, 1];
	};

	private _taskCompletions = _task select 2;
	{
		[_task, _x select 1] call (_x select 0);
	} forEach _taskCompletions;
};

SPM_TaskOnComplete =
{
	params ["_task", "_onCompletion", "_passthrough"];

	if (isNil "_passthrough") then { _passthrough = 0 };

	private _taskCompletions = _task select 2;
	_taskCompletions pushBack [_onCompletion, _passthrough];
};

SPM_TaskStop =
{
	params ["_task"];

	_task set [1, -1];
};

SPM_TaskCreate =
{
	params ["_object"];

	[_object, 0, [], []]
};

SPM_TaskGetState =
{
	params ["_task"];

	_task select 1
};

SPM_TaskSetValue =
{
	params ["_task", "_name", "_value"];

	private _values = _task select 3;

	private _index = [_values, _name] call BIS_fnc_findInPairs;
	if (_index == -1) then
	{
		_values pushback [_name, _value];
	}
	else
	{
		_values set [_index, [_name, _value]];
	};
};

SPM_TaskGetValue =
{
	params ["_task", "_name", "_default"];

	private _values = _task select 3;

	private _index = [_values, _name] call BIS_fnc_findInPairs;
	if (_index == -1) exitWith { _default };

	(_values select _index) select 1
};

SPM_TaskGetObject =
{
	params ["_task"];

	_task select 0
};

SPM_GoToNextBuilding =
{
	params ["_leader", "_units", "_task"];

	private _patrolPositions = [_task, "PatrolPositions", []] call SPM_TaskGetValue;

	if (count _patrolPositions == 0 || { ([_task] call SPM_TaskGetState) == -1 }) exitWith
	{
		[_task] call SPM_TaskComplete;
	};

	{
		_x set [0, (_x select 1) distanceSqr (getpos _leader)];
	} forEach _patrolPositions;

	_patrolPositions sort true;

	_patrolPosition = _patrolPositions deleteAt 0;
	
	_waypoint = [_group,  _patrolPosition select 1] call SPM_AddPatrolWaypoint;
	_waypoint setWaypointType "move";
	[_waypoint, SPM_GoToNextBuilding, _task] call SPM_AddPatrolWaypointStatements;
};

SPM_PatrolBuildings =
{
	params ["_group", "_position", "_radius", "_visit", "_enter"];

	private _task = [_group] call SPM_TaskCreate;

	private _buildings = nearestObjects [_position, ["HouseBase"], _radius];

	private _patrolPositions = [];
	for "_i" from (count _buildings - 1) to 0 step -1 do
	{
		if (random 1 < _visit) then
		{
			private _building = _buildings select _i;

			private _enteredBuilding = false;
			if (random 1 < _enter && { not ([_building] call SPM_BuildingIsOccupied) }) then
			{
				private _positions = [_building] call BIS_fnc_buildingPositions;
				if (count _positions > 0) then
				{
					_enteredBuilding = true;
					_buildingPosition = _positions select (floor random (count _positions));
					_patrolPositions pushBack [0, _buildingPosition];
				};
			};

			if (not _enteredBuilding) then
			{
				private _exits = [];
				for "_e" from 0 to 20 do
				{
					private _exit = _building buildingExit _e;
					if (_exit isEqualTo [0,0,0]) exitWith {};
					_exit set [2, 1];
					_exits pushBack _exit;
				};

				if (count _exits > 0) then
				{
					_patrolPositions pushBack [0, selectRandom _exits];
				};
			};
		};
	};

	if (count _patrolPositions == 0) then
	{
		[_task] call SPM_TaskComplete;

		_task
	}
	else
	{
		[_group] call SPM_StartWaypointMonitor;
		[_task, { [[_this select 0] call SPM_TaskGetObject] call SPM_StopWaypointMonitor }] call SPM_TaskOnComplete;

		[_task, "PatrolPositions", _patrolPositions] call SPM_TaskSetValue;
		[leader _group, units _group, _task] call SPM_GoToNextBuilding;
	};

	_task
};

SPM_GoToNextRoadPosition =
{
	params ["_leader", "_units", "_task"];

	private _group = group _leader;
	private _vehicle = objNull;
	{
		if (vehicle _x != _x) exitWith { _vehicle = vehicle _x };
	} forEach units _group;

	private _waypointPositions = [_task, "PatrolPositions", []] call SPM_TaskGetValue;
	if (count _waypointPositions == 0 || ([_task] call SPM_TaskGetState) == -1) exitWith
	{
		if (not isNull _vehicle) then
		{
			[_vehicle, -1] call JB_fnc_limitSpeed;
		};

		[_task] call SPM_TaskComplete;
	};

	if (not isNull _vehicle) then
	{
		[_vehicle, 15] call JB_fnc_limitSpeed;

		private _shouldBeDismounted = random 1 < 0.4;

		if (_shouldBeDismounted) then
		{
			private _dismounts = (fullCrew _vehicle) select { (_x select 1) == "cargo" || ((_x select 1) == "Turret" && (_x select 4)) };

			if (count _dismounts > 0) then
			{
				private _waypoint = [_group, getPos _vehicle] call SPM_AddPatrolWaypoint;
				_waypoint setWaypointType "unload";
			};
		}
		else
		{
			private _dismounts = units _group select { vehicle _x == _x };
			if (count _dismounts > 0) then
			{
				private _waypoint = [_group, getPos _vehicle] call SPM_AddPatrolWaypoint;
				_waypoint waypointAttachVehicle _vehicle;
				_waypoint setWaypointType "load";
			};
		};
	};

	private _waypointPosition = _waypointPositions deleteAt 0;

	private _waypoint = [_group, _waypointPosition] call SPM_AddPatrolWaypoint;
	_waypoint setWaypointType "move";
	[_waypoint, SPM_GoToNextRoadPosition, _task] call SPM_AddPatrolWaypointStatements;
};

SPM_PatrolRoads =
{
	params ["_group", "_position", "_radius"];

//	diag_log "SPM_PatrolRoads";

	private _task = [_group] call SPM_TaskCreate;

	private _vehicle = vehicle leader _group;
	private _intersections = [_position, _radius] call SPM_Nav_GetIntersections;

//	diag_log format ["SPM_PatrolRoads: intersections: %1", count _intersections];

	if (count _intersections == 0) exitWith
	{
		[_task] call SPM_TaskComplete;

		_task
	};

	private _from = [_intersections, getPos _vehicle, vectorDir _vehicle] call SPM_Nav_GetIntersectionInFront;
	private _to = [_intersections, (_intersections select _from) select 0, vectorDir _vehicle] call SPM_Nav_GetIntersectionInFront;

//	diag_log format ["SPM_WS_PatrolRoads: intersection from-to: %1-%2", _from, _to];

	private _visits = _intersections apply { 0 };

	private _waypointPositions = [];

	for "_i" from 0 to count _intersections - 1 do
	{
		private _intersection = _intersections select _to;
		private _waypointPosition = _intersection select 0;
		_waypointPosition set [2, 1];

		if (count _waypointPositions == 0 || { _waypointPosition distanceSqr (_waypointPositions select (count _waypointPositions - 1)) > (15 * 15) }) then
		{
			_waypointPositions pushBack _waypointPosition;
		};

		private _choices = [];
		{
			if (_x != _from) then { _choices pushBack _x };
		} forEach (_intersection select 1);

		_from = _to;

		private _minVisits = 1e30;
		private _minVisitsIndex = -1;
		{
			if (_visits select _x < _minVisits) then
			{
				_minVisits = _visits select _x;
				_minVisitsIndex = _x;
			};
		} forEach _choices;

		_to = _minVisitsIndex;

		_visits set [_to, (_visits select _to) + 1];
	};

	if (count _waypointPositions == 0) then
	{
		[_task] call SPM_TaskComplete;
	}
	else
	{
		[_task, "PatrolPositions", _waypointPositions] call SPM_TaskSetValue;
		[leader _group, units _group, _task] call SPM_GoToNextRoadPosition;
	};

	_task
};