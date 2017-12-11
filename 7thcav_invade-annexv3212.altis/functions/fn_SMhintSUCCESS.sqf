SM_CreateReward =
{
	private _markerPrefix = param [0, "", [""]];
	private _numberMarkers = param [1, 1, [0]];
	private _descriptor = param [2, [], [[]]];

	private _markerNames = [];
	for "_i" from 1 to _numberMarkers do
	{
		_markerNames pushBack format ["%1%2", _markerPrefix, _i];
	};

	_reward = createVehicle [_descriptor select 1, getMarkerPos (_markerNames select 0), _markerNames, 0, "NONE"];
	[_reward] call JB_fnc_downgradeATInventory;
	_reward setDir (markerDir (_markerNames select 0));

	[_reward] call (_descriptor select 2);

	[[_reward]] call SERVER_CurateEditableObjects;
};

private _descriptor = [SERVER_SpecialOperationsRewards] call JB_fnc_randomItemFromWeightedArray;

["smReward", 27, _descriptor] call SM_CreateReward;

["CompletedSideMission", sideMarkerText, getMarkerPos "sideMarker", 1000] remoteExec ["AW_fnc_specialOperationsNotification", 0, false];

private _rewardtext = format["Your team received %1", _descriptor select 0];
["Reward", _rewardText, getMarkerPos "sideMarker", 1000] remoteExec ["AW_fnc_specialOperationsNotification", 0, false];
