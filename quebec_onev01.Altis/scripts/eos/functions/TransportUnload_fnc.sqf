private _targetPosition = _this select 0;
private _veh = _this select 1;
private _counter = _this select 2;
private _marker = _this select 3;

private _vehicle = _veh select 0;
private _group = _veh select 2;					
private _cargoGroup= _veh select 3;

private _startPosition = getPos _vehicle;

{_x allowFleeing 0} forEach units _group;		
{_x allowFleeing 0} forEach units _cargoGroup;

if (false) then
{
	private _landingPad = createVehicle ["Land_HelipadEmpty_F", _targetPosition, [], 0, "NONE"]; 

	private _landingWaypoint = _group addWaypoint [_targetPosition, 0];  
	_landingWaypoint setWaypointSpeed "FULL";  
	_landingWaypoint setWaypointType "UNLOAD";
	_landingWaypoint setWaypointStatements ["true", "(vehicle this) land 'GET IN';"]; 

	// Wait until the helicopter is near the landing pad

	waituntil
	{
		sleep 0.1;
		_vehicle distance _landingPad < 30
	};

	_cargoGroup leaveVehicle _vehicle;	
		
	// Wait until the soldiers dismount

	waitUntil
	{
		sleep 0.2;
		{
			_x in _vehicle
		} count units _cargoGroup == 0
	};				

	deletevehicle _landingPad;
}
else
{
	private _direction = _startPosition vectorFromTo _targetPosition;

	private _landingWaypoint = _group addWaypoint [_targetPosition vectorAdd (_direction vectorMultiply 300), 0];
	_landingWaypoint setWaypointSpeed "FULL";  
	_landingWaypoint setWaypointType "MOVE";

	waituntil
	{
		sleep 0.1;
		_vehicle distance _targetPosition < 300
	};

	{
		unassignVehicle _x;
		[_x, true] call JB_fnc_halo;
		sleep 0.5;
	} forEach units _cargoGroup;
};

[_cargoGroup, _marker] call eos_fnc_taskpatrol;

private _departureWaypoint = _group addWaypoint [_startPosition, 0];
_departureWaypoint setWaypointSpeed "FULL";
_departureWaypoint setWaypointType "MOVE";
_departureWaypoint setWaypointStatements ["true", "{deleteVehicle _x} forEach crew (vehicle this) + [vehicle this];"];