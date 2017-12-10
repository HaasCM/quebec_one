#define IDC_OK 1
#define IDC_CANCEL 2

#define REPACK_DIALOG 3000
#define PROGRESS_CONTROL 2000

#define ROUNDS_REPACKED_PER_SECOND 2

JBRM_RepackUnload =
{
	JBRM_StopRepack = true;
};

JBRM_RepackMagazinesCondition =
{
	true
};

JBRM_ComputeRepack =
{
	disableSerialization;

	private _totalRoundsToRepack = _this select 0;
	private _progressControl = _this select 1;

	private _magazines = (magazinesAmmoFull player) apply { _x + [getNumber (configFile >> "CfgMagazines" >> (_x select 0) >> "count")] };
	_magazines = _magazines select { not (_x select 4 in [primaryWeapon player, handgunWeapon player, secondaryWeapon player]) };
	_magazines sort false;

	private _roundsMoved = 0;

	for "_i" from 0 to (count _magazines - 1) do
	{
		private _to = _magazines select _i;
		private _roundsPerMagazine = _to select 5;

		if (_to select 1 > 0 && _to select 1 < _roundsPerMagazine && _roundsPerMagazine >= 2 && _roundsPerMagazine <= 50) then
		{
			private _lastOfSameType = _i;
			for "_j" from (_i + 1) to (count _magazines - 1) do
			{
				if ((_magazines select _j) select 0 != _to select 0) exitWith {};
				_lastOfSameType = _j;
			};

			for "_j" from _lastOfSameType to (_i + 1) step -1 do
			{
				private _from = _magazines select _j;
				if (_from select 0 != _to select 0) exitWith {};

				if ((_from select 1) > 0) then
				{
					private _roundsToMove = (_from select 1) min (_roundsPerMagazine - (_to select 1));

					if (_totalRoundsToRepack == 0) then
					{
						_to set [1, (_to select 1) + _roundsToMove];
						_from set [1, (_from select 1) - _roundsToMove];
						_roundsMoved = _roundsMoved + _roundsToMove;
					}
					else
					{
						for "_r" from 1 to _roundsToMove do
						{
							_to set [1, (_to select 1) + 1];
							_from set [1, (_from select 1) - 1];
							_roundsMoved = _roundsMoved + 1;
							sleep (1 / ROUNDS_REPACKED_PER_SECOND / ((1.0 - damage player) max 0.2));
							_progressControl progressSetPosition (_roundsMoved / _totalRoundsToRepack);

							if (JBRM_StopRepack || not (lifeState player in ["INJURED", "HEALTHY"])) exitWith {}
						};
					};
				};

				if (_to select 1 == _roundsPerMagazine) exitWith {};

				if (JBRM_StopRepack || not (lifeState player in ["INJURED", "HEALTHY"])) exitWith {};
			};
		};

		if (JBRM_StopRepack || not (lifeState player in ["INJURED", "HEALTHY"])) exitWith {};
	};

	if (_totalRoundsToRepack > 0) then
	{
		sleep 1;
	};

	[_magazines, _roundsMoved]
};

#define END_OF_SEQUENCE "AinvPknlMstpSnonWnonDnon_medicEnd"

JBRM_RunAnimationSequence =
{
	private _animations =
	[
		"AinvPknlMstpSnonWnonDnon_medic_1",
		"AinvPknlMstpSnonWnonDnon_medicUp1",
		"AinvPknlMstpSnonWnonDnon_medicUp3",
		"AinvPknlMstpSnonWnonDnon_medicUp5",
		"AinvPknlMstpSnonWnonDr_medicUp1",
		"AinvPknlMstpSnonWnonDr_medicUp4"
	];
	private _index = 0;
	while { count _animations > 0 } do
	{
		_index = random (count _animations);
		player playMove (_animations select _index);
		_animations deleteAt _index;
	};
	player playMove END_OF_SEQUENCE;
};

JBRM_RepackMagazines =
{
	JBRM_Vehicle = param [0, objNull, [objNull]];

	JBRM_StopRepack = false;

	private _repack = [0, controlNull] call JBRM_ComputeRepack;
	private _totalRoundsToRepack = _repack select 1;

	if (_totalRoundsToRepack == 0) exitWith {};

	private _originalAnimationState = animationState player;
	if (vehicle player == player) then
	{
		[] call JBRM_RunAnimationSequence;
		sleep 2;
	};

	createDialog "JBRM_RepackMagazines";
	waitUntil { dialog };

	disableSerialization;
	private _dialog = findDisplay REPACK_DIALOG;
	private _progressControl = _dialog displayCtrl PROGRESS_CONTROL;

	_repack = [_totalRoundsToRepack, _progressControl] call JBRM_ComputeRepack;
	private _magazines = _repack select 0;

	private _backpackItems = backpackItems player;
	private _vestItems = vestItems player;
	private _uniformItems = uniformItems player;

	{
		player removeMagazines (_x select 0);
	} forEach _magazines;

	{
		if (_x select 1 > 0) then
		{
			private _item = _x select 0;

			if (_item in _uniformItems) then
			{
				uniformContainer player addMagazineAmmoCargo [_item, 1, _x select 1];
				{
					if (_x == _item) exitWith { _uniformItems deleteAt _forEachIndex };
				} forEach _uniformItems;
				_x set [1, 0];
			};
		};
	} forEach _magazines;

	{
		if (_x select 1 > 0) then
		{
			private _item = _x select 0;

			if (_item in _vestItems) then
			{
				vestContainer player addMagazineAmmoCargo [_item, 1, _x select 1];
				{
					if (_x == _item) exitWith { _vestItems deleteAt _forEachIndex };
				} forEach _vestItems;
				_x set [1, 0];
			};
		};
	} forEach _magazines;

	{
		if (_x select 1 > 0) then
		{
			private _item = _x select 0;

			if (_item in _backpackItems) then
			{
				backpackContainer player addMagazineAmmoCargo [_item, 1, _x select 1];
				{
					if (_x == _item) exitWith { _backpackItems deleteAt _forEachIndex };
				} forEach _backpackItems;
				_x set [1, 0];
			};
		};
	} forEach _magazines;

	reload player;

	closeDialog IDC_OK;
	
	JBRM_StopRepack = nil;

	if (vehicle player == player) then
	{
		player playMoveNow _originalAnimationState;
	};
};

JBRM_SetupActions =
{
	player addAction ["Repack magazines", { [] spawn JBRM_RepackMagazines; }, [], 0, false, true, "", "[] call JBRM_RepackMagazinesCondition;"];
};

[] call JBRM_SetupActions;
player addEventHandler ["Respawn", { [] call JBRM_SetupActions }];