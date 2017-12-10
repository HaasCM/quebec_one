HALO_AddParachute =
{
	private _unit = _this select 0;

	_unit setVariable ["HALO_Backpack", [backpack _unit, backpackItems _unit]];

	removeBackpack _unit;
	_unit addBackpack "B_Parachute";
};

HALO_RestoreBackpack =
{
	private _unit = _this select 0;

	private _backpack = _unit getVariable ["HALO_Backpack", []];
	_unit setVariable ["HALO_Backpack", nil];

	if (count _backpack > 0) then
	{
		removeBackpack _unit;
		if (_backpack select 0 != "") then
		{
			_unit addBackpack (_backpack select 0);
			clearAllItemsFromBackpack _unit;
			{
				_unit addItemToBackpack _x;
			} foreach (_backpack select 1);
		};
	};
};

HALO_ShowStatusMessage =
{
	private _remainingDelay = _this select 0;
	private _target = _this select 1;

	private _minutes = floor (_remainingDelay / 60);

	private _seconds = (round _remainingDelay) mod 60;
	private _leadingZero = "";
	if (_seconds < 10) then { _leadingZero = "0" };

	titleText [format ["HALO jump over %1 in %2:%3%4...", _target, _minutes, _leadingZero, _seconds], "PLAIN", 0.2];
};

HALO_CurrentTime =
{
	daytime * 3600; // 24 hour clock will produce problems when spanning midnight
};

HALO_ReadyForJump =
{
	private _player = _this select 0;
	private _vehicle = _this select 1;

	if (not (lifeState _player in ["HEALTHY", "INJURED"])) exitWith { false };
	if (not (vehicle _player == _vehicle)) exitWith { false };
	if (not (alive _vehicle)) exitWith { false };

	true;
};

HALO_GroupStartName =
{
	"HALO_Group " + str (group player);
};

HALO_GetOutHandler =
{
	private _vehicle = _this select 0;

	private _groupMembersInVehicle = false;
	private _playerGroup = group player;
	{
		if (group _x == _playerGroup) then
		{
			_groupMembersInVehicle = true;
		}
	} foreach crew _vehicle;

	if (not _groupMembersInVehicle) then
	{
		_vehicle setVariable [[] call HALO_GroupStartName, nil, true]; // public
	};
};

HALO_Start =
{
	private _vehicle = _this select 0;

	private _haloVehicles = player getVariable ["HALO_Vehicles", []];

	//TODO: Drop vehicles from list when they go objNull (have been deleted)
	private _match = [];
	{
		if (_vehicle in (_x select 0)) exitWith { _match = _x };
	} forEach _haloVehicles;

	if (count _match == 0) exitWith {};

	[_vehicle, _match select 1] spawn
	{
		private _vehicle = _this select 0;
		private _jumpCode = _this select 1;

		// The time that the player started waiting is either his own time of getting into the HALO vehicle
		// or the time of the earliest squad member who got in.  This allows groups to jump together.

		private _groupStartName = [] call HALO_GroupStartName;
		private _groupStart = _vehicle getVariable [_groupStartName, -1];
		private _waitStart = [] call HALO_CurrentTime;

		if (_groupStart == -1) then
		{
			_vehicle setVariable [_groupStartName, _waitStart, true]; // public
		}
		else
		{
			_waitStart = _groupStart;
		};

		private _targetData = [_vehicle] call _jumpCode;
		private _targetDrop = _targetData select 0;
		private _targetPosition = _targetData select 1;
		private _targetDelay = _targetData select 2;

		private _jumpTime = _waitStart + round _targetDelay;
		private _remainingDelay = _jumpTime - ([] call HALO_CurrentTime);
		_remainingDelay = _remainingDelay max 7; // Ensure that we at least get the countdown

		if (_targetDrop != "" && _remainingDelay < 10) then
		{
			[_remainingDelay, _targetDrop] call HALO_ShowStatusMessage;
		};

		// If the player gets out of the vehicle and he's the last member of his group to get out, clear the group
		// start time variable.
		private _getOutHandler = _vehicle addEventHandler ["GetOut", HALO_GetOutHandler];

		// So long as the player is alive and in an intact HALO vehicle, keep the process going
		while { ([player, _vehicle] call HALO_ReadyForJump) } do
		{
			_targetData = [_vehicle] call _jumpCode;
			_targetDrop = _targetData select 0;
			private _currentDrop = _targetData select 0;

			while { ([player, _vehicle] call HALO_ReadyForJump) && _remainingDelay > 0 && { _targetDrop == _currentDrop } && { _targetDrop != "" } } do
			{
				if (_remainingDelay < 6) then
				{
					[format ["<t align='center' size='2'>%1</t>", round _remainingDelay], -1, -1, 0.2, 0.2] call BIS_fnc_dynamicText;
				}
				else
				{
					if (_remainingDelay mod 5 < 1) then
					{
						[_remainingDelay, _targetDrop] call HALO_ShowStatusMessage;
					};

					sleep 1;
				};

				_remainingDelay = _remainingDelay - 1;

				_targetData = [_vehicle] call _jumpCode;
				_currentDrop = _targetData select 0;
			};

			if (not ([player, _vehicle] call HALO_ReadyForJump)) exitWith { };

			if (_targetDrop == "" || _targetDrop != _currentDrop) then
			{
				if (_currentDrop == "") then
				{
					titleText ["Waiting for new operation", "BLACK IN", 5];

					while { ([player, _vehicle] call HALO_ReadyForJump) && _currentDrop == "" } do
					{
						sleep 5;

						_targetData = [_vehicle] call _jumpCode;
						_currentDrop = _targetData select 0;
					};
				};

				if ([player, _vehicle] call HALO_ReadyForJump) then
				{
					titleText [format ["Combat operations have moved to %1.", _currentDrop], "BLACK IN", 5];
					sleep 5;

					_targetDrop = _currentDrop;

					_remainingDelay = (_targetData select 2) - (([] call HALO_CurrentTime) - _waitStart);
					_remainingDelay = round(_remainingDelay) max 7; // Give him time to get out if he doesn't want new drop target
				};
			}
			else // Timer expired and player should make HALO jump
			{
				// Clear the group wait start time so that anyone who gets into the HALO vehicle after
				// the current jump has to wait the full delay.
				_vehicle setVariable [_groupStartName, nil, true]; // public

				["<t align='center' size='2'>GREEN LIGHT</t>", -1, -1, 0.2, 0.2] call BIS_fnc_dynamicText;

				// Position is horizontally randomized +/- 5 meters
				private _dropPosition = _targetData select 1;
				_dropPosition = [(_dropPosition select 0) + (random 10) - 5, (_dropPosition select 1) + (random 10) - 5, (_dropPosition select 2)];
				private _dropDirection = (getPos _vehicle) getDir (_targetData select 1);

				[player, false, _dropPosition, _dropDirection] call JB_fnc_halo;
				waitUntil { vehicle player == player };
			};
		};

		_vehicle removeEventHandler ["GetOut", _getOutHandler];

		// When the player exits the vehicle, don't leave a message sitting on the screen
		titleText ["", "PLAIN", 0.1];
	};
};

HALO_SetupClient =
{
	private _vehicles = param [0, [], [[]]];
	private _jumpCode = param [1, {}, [{}]];

	private _haloVehicles = player getVariable ["HALO_Vehicles", []];
	_haloVehicles pushback [_vehicles, _jumpCode];
	player setVariable ["HALO_Vehicles", _haloVehicles];

	if (count _haloVehicles == 1) then
	{
		player addEventHandler ["GetInMan", { if ((_this select 1) == "cargo") then { [_this select 2] call HALO_Start; } }];
	};
};

HALO_InstallPlayerReserveParachute =
{
	player setVariable ["JB_HALO_Reserve", true];
	_handler = (findDisplay 46) displayAddEventHandler ["KeyDown",
		{
			private _override = false;

			if ((_this select 1) == 0x2F) then
			{
				private _animationState = animationState player;
				if (animationState player == "para_pilot") then
				{
					private _parachute = vehicle player;
					moveOut player;
					[_parachute] spawn
					{
						sleep 3;
						deleteVehicle (_this select 0);
					};

					if (player getVariable["JB_HALO_Reserve", false]) then
					{
						player addBackpack "B_Parachute";
						player setVariable ["JB_HALO_Reserve", nil];
					}
					else
					{
						[player] call HALO_RestoreBackpack;
					};
					_override = true;
				};
			};

			_override;
		}];
	player setVariable ["JB_HALO_ReserveHandler", _handler];
};

HALO_UninstallPlayerReserveParachute =
{
	(findDisplay 46) displayRemoveEventHandler ["KeyDown", player getVariable "JB_HALO_ReserveHandler"];
	player setVariable ["JB_HALO_ReserveHandler", nil];
};