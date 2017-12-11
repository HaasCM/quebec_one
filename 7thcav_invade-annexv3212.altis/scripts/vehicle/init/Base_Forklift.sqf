TROLLEY_RestrictToLogisticsArea =
{
	private _trolley = _this select 0;

	if (!isServer) exitWith {};

	while { true } do
	{
		if (not ([TRIGGER_Logistics, _trolley] call BIS_fnc_inTrigger)) then
		{
			[_trolley] call JB_fnc_respawnVehicleReturn;
		};

		sleep 3;
	};
};

[_this select 0] call JB_fnc_ammoInitTrolley;

[_this select 0] call JB_fnc_respawnVehicleInitialize;
[_this select 0] spawn TROLLEY_RestrictToLogisticsArea;