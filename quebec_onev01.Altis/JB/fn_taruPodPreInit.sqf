// Derived from XENO's Taru pod handling script

#define DISTANCE_FROM_POD 5

JBTPI_HasParentClass =
{
	private _unit = _this select 0;
	private _parentClasses = _this select 1;

	private _hasParentClass = false;
	{
		if (_x in _parentClasses) exitwith { _hasParentClass = true };
	} foreach ([(configfile >> "CfgVehicles" >> typeof _unit), true] call BIS_fnc_returnParents);

	_hasParentClass;
};

JBTPI_PositionedPod =
{
	private _taru = _this select 0;

	private _pod = objNull;
	{
		if (_x != _taru && { [_x, ["Pod_Heli_Transport_04_base_F", "Pod_Heli_Transport_04_crewed_base_F"]] call JBTPI_HasParentClass }) then
		{
			private _relativeDirection = ([_x, _taru] call BIS_fnc_relativeDirTo);
			if (_relativeDirection > 330 || _relativeDirection < 30) then { _pod = _x };
		};
		if (not isNull _pod) exitWith {};
	} forEach nearestObjects [_taru, ["All"], 5];

	_pod;
};

JBTPI_AttachPodCondition =
{
	private _taru = _this select 0;
	private _pilot = _this select 1;

	if (vehicle _pilot != _taru) exitWith { false };

	if (not isNull ([_taru] call JBTPI_AttachedPod)) exitWith { false };

	not isNull ([_taru] call JBTPI_PositionedPod)
};

JBTPI_AttachPod =
{
	private _taru = _this select 0;
	private _pilot = _this select 1;

	private _taruMass = getMass _taru;

	private _pod = ([_taru] call JBTPI_PositionedPod);
	private _podMass = getMass _pod;

	if (_pod isKindOf "Land_Pod_Heli_Transport_04_bench_F") exitwith
	{
		_pod attachTo [_taru, [0, 0, -1.38]];
		_taru setCustomWeightRTD 680;
		_taru setmass _taruMass + _podMass;
	};

	if (_pod isKindOf "Land_Pod_Heli_Transport_04_covered_F") exitwith
	{
		_pod attachTo [_taru, [0, -1.05, -0.95]];
		_taru setCustomWeightRTD 1413;
		_taru setmass _taruMass + _podMass;
	};

	if (_pod isKindOf "Land_Pod_Heli_Transport_04_fuel_F") exitwith
	{
		_pod attachTo [_taru, [0, -0.4, -1.32]];
		_taru setCustomWeightRTD 13311;
		_taru setmass _taruMass + _podMass;
	};

	if (_pod isKindOf "Land_Pod_Heli_Transport_04_medevac_F") exitwith
	{
		_pod attachTo [_taru, [0, -1.05, -1.05]];
		_taru setCustomWeightRTD 1321;
		_taru setmass _taruMass + _podMass;
	};

	// "Land_Pod_Heli_Transport_04_repair_F", "Land_Pod_Heli_Transport_04_box_F", "Land_Pod_Heli_Transport_04_ammo_F"

	_pod attachTo [_taru, [0, -1.12, -1.22]];
	[_pod, owner _taru] remoteExec ["setOwner", 2];
	_taru setCustomWeightRTD 1270;
	_taru setmass _taruMass + _podMass;
};

JBTPI_AttachedPod =
{
	private _taru = _this select 0;

	private _pod = objNull;
	{
		if ([_x, ["Pod_Heli_Transport_04_base_F", "Pod_Heli_Transport_04_crewed_base_F"]] call JBTPI_HasParentClass) exitWith { _pod = _x };
	} forEach attachedObjects _taru;

	_pod
};

JBTPI_ReleasePodCondition =
{
	private _taru = _this select 0;
	private _pilot = _this select 1;

	if (vehicle _pilot != _taru) exitWith { false };

	not isNull ([_taru] call JBTPI_AttachedPod);
};

JBTPI_ReleasePod =
{
	private _taru = _this select 0;
	private _pilot = _this select 1;

	private _pod = [_taru] call JBTPI_AttachedPod;

	_taru allowDamage false;
	_pod allowDamage false;

	detach _pod;

	_taru setCustomWeightRTD 0;
	_taru setmass (getMass _taru) - (getMass _pod);

	[_taru, _pod] call JB_fnc_popCargoChute;

	// Introduce a delay before allowing damage so the pod can get clear of the Taru's cargo hook.  Without
	// such a delay, the two objects intersect, producing explosions, ejections, and other mayhem.

	[_taru, _pod] spawn
	{
		private _taru = _this select 0;
		private _pod = _this select 1;

		sleep 2;

		_pod allowDamage true;
		_taru allowDamage true;
	};
};

JBTPI_SetupClient =
{
	private _taru = _this select 0;
	private _cargoTypes = _this select 1;

	if (not alive _taru) exitWith {};

	_taru setVariable ["JBPCC_CargoData", _cargoTypes];

	if (not hasInterface) exitWith {};

	_taru addAction ["Attach Pod", { _this call JBTPI_AttachPod }, nil, 0, false, true, "", "[_target, _this] call JBTPI_AttachPodCondition"];
	_taru addAction ["Release Pod", { _this call JBTPI_ReleasePod }, nil, 0, false, true, "", "[_target, _this] call JBTPI_ReleasePodCondition"];
};