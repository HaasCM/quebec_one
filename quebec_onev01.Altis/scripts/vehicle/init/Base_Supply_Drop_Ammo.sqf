if (not isServer) exitWith {};

Base_Supply_Drop_Ammo_StockContainer =
{
	params ["_container"];

	private _capacity = getNumber (configFile >> "CfgVehicles" >> typeOf _container >> "maximumLoad");
	[_container, _capacity, true] call SERVER_Supply_StockAmmunitionContainer;
};

Base_Supply_Drop_Ammo_C_SetupActions =
{
	params ["_container"];

	_container addAction ["Restock ammunition from VAS", { [_this select 0] remoteExec ["Base_Supply_Drop_Ammo_StockContainer", 2] }, nil, 5, false, true, '', '[_target, "vas", 10] call CLIENT_Supply_RestockFromSupplyCondition', 2];
	_container addAction ["Restock ammunition from Arsenal", { [_this select 0] remoteExec ["Base_Supply_Drop_Ammo_StockContainer", 2] }, nil, 5, false, true, '', '[_target, "arsenal", 10] call CLIENT_Supply_RestockFromSupplyCondition', 2];
};

[_this select 0,
	{
		params ["_container"];

		[_container] call Base_Supply_Drop_Ammo_StockContainer;
		[[_container], Base_Supply_Drop_Ammo_C_SetupActions] remoteExec ["call", 0, true]; // JIP
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;