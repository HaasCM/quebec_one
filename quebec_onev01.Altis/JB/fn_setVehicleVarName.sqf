private _vehicle = _this select 0;
private _vehicleName = _this select 1;

//diag_log "JB_fnc_setVehicleVarName";
//diag_log str _vehicle;
//diag_log format ["Vehicle name: %1", _vehicleName];
if (_vehicleName != "") then
{
	// Set up the variable locally.  Note that setVehicleVarName locally doesn't do what we need.

	missionNamespace setVariable [_vehicleName, _vehicle];

	// Tell all clients to set the vehicle's variable name.  They are told to locate the vehicle in
	// their object list via its netID.

	// The format is creating an array of one parameter to feed to BIS_fnc_spawn.  If the array is provided directly on the remoteExec line,
	// it will be interpreted as multiple parameters to remoteExec.
	private _command = format["[ { (objectFromNetID '%1') setVehicleVarName '%2'; } ]", netID _vehicle, _vehicleName];
	(call compile _command) remoteExec ["BIS_fnc_spawn"];
};