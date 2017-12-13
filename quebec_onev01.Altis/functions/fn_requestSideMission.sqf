#include "..\SPM\strongpoint.h";

private _message = "";

if (SM_MissionRequested) then
{
	_message = "Working on it...";
	[_message, getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsSideChat", 0, false];
}
else
{
	if (SM_MissionActive) then
	{
		_message = "Operation already assigned.  Reference map.";
		if (SM_MissionSucceeded) then
		{
			_message = "Still reviewing data from previous mission...";
		};
		[_message, getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsSideChat", 0, false];
	}
	else
	{
		if (SPM_SpecialOperationsEnabled) then
		{
			private _player = objNull;
			{ if (owner _x == remoteExecutedOwner) exitWith { _player = _x } } forEach allPlayers;

			[_player] call OO_METHOD(SPM_SpecialOperationsCommand,SpecialOperationsCommand,RequestMission);
		}
		else
		{
			[] spawn
			{
				sleep 2;

				_message = "Copy.  Mission request acknowledged.  Wait one.";
				[_message, getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsSideChat", 0, false];

				sleep 10 + random 10;

				_message = "MissionObjective identified, stand by for orders.";
				[_message, getPos SMmission, 60] remoteExec ["AW_fnc_specialOperationsSideChat", 0, false];

				SM_MissionRequested = true; publicVariable "SM_MissionRequested";
			};
		};
	};
};