JBLS_RestrictVehicleSpeed =
{
	private _vehicle = _this select 0;
	private _targetSpeed = _this select 1;

	private _targetSpeed = _targetSpeed * 0.2778; // km/h to m/s
	private _targetSpeedSqr = _targetSpeed * _targetSpeed;

	private _currentVelocity = velocityModelSpace _vehicle;
	private _currentSpeedSqr = vectorMagnitudeSqr _currentVelocity;

	if (_currentSpeedSqr > _targetSpeedSqr) then
	{
		private _currentSpeed = sqrt _currentSpeedSqr;
		if (_currentSpeed < 0.001) then
		{
			_vehicle setVelocityModelSpace [0, _targetSpeed, 0];
		}
		else
		{
			_vehicle setVelocityModelSpace (_currentVelocity vectorMultiply (_targetSpeed / _currentSpeed));
		};
	};
};

JBLS_Governor =
{
	private _i = 0;
	private _vehicle = objNull;

	while { true } do
	{
		JBLS_CS call JB_fnc_criticalSectionEnter;

		if (isNil "JBLS_GovernedVehicles") exitWith { JBLS_CS call JB_fnc_criticalSectionLeave };

		for "_i" from (count JBLS_GovernedVehicles - 1) to 0 step -1 do
		{
			_vehicle = JBLS_GovernedVehicles select _i;
			if (not alive _vehicle) then
			{
				JBLS_GovernedVehicles deleteAt _i;
			}
			else
			{
				_targetSpeed = _vehicle getVariable ["JBLS_GovernedSpeed", -1];
				if (_targetSpeed >= 0) then
				{
					[_vehicle, _targetSpeed] call JBLS_RestrictVehicleSpeed;
				};
			};
		};

		JBLS_CS call JB_fnc_criticalSectionLeave;

		sleep 0.2;
	};
};

private _vehicle = _this select 0;
private _targetSpeed = _this select 1;

if (isNil "JBLS_CS") then
{
	JBLS_CS = call JB_fnc_criticalSectionCreate;
};

JBLS_CS call JB_fnc_criticalSectionEnter;

if (_targetSpeed < 0) then
{
	if (not isNil "JBLS_GovernedVehicles") then
	{
		private _index = JBLS_GovernedVehicles find _vehicle;
		if (_index >= 0) then
		{
			JBLS_GovernedVehicles deleteAt _index;
			_vehicle setVariable ["JBLS_GovernedSpeed", nil];

			if (count JBLS_GovernedVehicles == 0) then
			{
				JBLS_GovernedVehicles = nil;
			};
		};

	};
}
else
{
	_vehicle setVariable ["JBLS_GovernedSpeed", _targetSpeed];

	if (isNil "JBLS_GovernedVehicles") then
	{
		JBLS_GovernedVehicles = [];
	};

	private _index = JBLS_GovernedVehicles find _vehicle;
	if (_index == -1) then
	{
		JBLS_GovernedVehicles pushBack _vehicle;
		if (count JBLS_GovernedVehicles == 1) then
		{
			[] spawn JBLS_Governor;
		};
	};
};

JBLS_CS call JB_fnc_criticalSectionLeave;