private _rewards =
[
	[
		25, ["an AH-9 Pawnee", "B_Heli_Light_01_armed_F",
				{
					private _reward = _this select 0;
					_reward setObjectTexture[0, "A3\Air_F\Heli_Light_01\Data\skins\heli_light_01_ext_digital_co.paa"];
				}
			]
	],

	[
		40, ["an Offroad (Armed HMG)", "B_G_Offroad_01_armed_F",
				{
					private _reward = _this select 0;
					_reward animate ["hideDoor1", 1];
					_reward animate ["hideDoor2", 1];
					_reward animate ["hideDoor3", 1];
					_reward animate ["hideBackpacks", 1];
					_reward animate ["hideBumper1", 1];
					_reward animate ["hideBumper2", 1];
					_reward animate ["hideConstruction", 0];
					[_reward] call JB_fnc_downgradeATInventory;
				}
			]
	],

	[
		40, ["an Offroad (Armed Mortar)", "B_G_Offroad_01_F",
				{
					private _reward = _this select 0;
					_reward animate ["hideDoor1", 1];
					_reward animate ["hideDoor2", 1];
					_reward animate ["hideDoor3", 1];
					_reward animate ["hideBackpacks", 0];
					_reward animate ["hideBumper1", 1];
					_reward animate ["hideBumper2", 1];
					_reward animate ["hideConstruction", 0];
					private _mortar = "B_Mortar_01_F" createVehicle [0, 0, 1000];
					_mortar attachTo [_reward, [0,-2.5,.3]];
					[_reward] call JB_fnc_downgradeATInventory;
				}
			]
	],

	[
		40, ["an Offroad (Repair)", "B_G_Offroad_01_repair_F",
				{
					private _reward = _this select 0;
					_reward setVariable ["REPAIR_ServiceLevel", 2, true];
					_reward setRepairCargo 0;
					[_reward] call JB_fnc_downgradeATInventory;
				}
			]
	],

	[
		10, ["a Hunter GMG", "B_MRAP_01_gmg_F",
				{
					private _reward = _this select 0;
					[_reward] call JB_fnc_downgradeATInventory;
				}
			]
	],

	[
		50, ["a Hunter HMG", "B_MRAP_01_hmg_F",
				{
					private _reward = _this select 0;
					[_reward] call JB_fnc_downgradeATInventory;
				}
			]
	],

	[
		50, ["an AMV-7 Marshall", "B_APC_Wheeled_01_cannon_F",
				{
					private _reward = _this select 0;
					[_reward] call JB_fnc_downgradeATInventory;
				}
			]
	]
];

private _marker = param [0, "", [""]];

private _reward = [_rewards] call JB_fnc_randomItemFromWeightedArray;

private _vehicle = (_reward select 1) createVehicle (getMarkerPos _marker);
waitUntil {!isNull _vehicle};

_vehicle setDir (markerDir _marker);

[_vehicle] call (_reward select 2);

[_vehicle] call JB_fnc_downgradeATInventory;

[[_vehicle]] call SERVER_CurateEditableObjects;

[_vehicle, _reward select 0]