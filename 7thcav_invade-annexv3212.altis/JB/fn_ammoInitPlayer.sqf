/*

Initialize a player for use with the ammo transfer system.  This function builds on
JB_fnc_ammoInit, causing the player to show an ammo box when transporting vehicle
ammo.  The player can jog with lighter loads and walks with heavier ones.

[] call JB_fnc_ammoInitPlayer;

	no arguments

See also JB_fnc_ammoInit and JB_fnc_ammoInitTrolley

*/
// The weight capacity of an ammo box (kg)
#define AMMO_BOX_CAPACITY 75

// The point at which the weight of the ammo box forces the player walk with it (kg)
#define AMMO_BOX_JOG_LIMIT 40

JBAP_AmmoBoxCarrySpeed =
{
	private _stores = player getVariable ["JBA_C_TransportStores", []];
	private _ammoBoxWeight = [_stores] call JBA_WeightOfStores;
	if (_ammoBoxWeight > AMMO_BOX_JOG_LIMIT) exitWith { "walk" };

	"jog"
};

JBAP_PositionForCarry =
{
	private _ammoBox = _this select 0;

	_ammoBox attachTo [player, [-0.05, 0.5, 0], "pelvis"];
	_ammoBox setDir 90;
};

// state = [ammo-box, speed, original-animation, discard-action]

JBAP_Start =
{
	private _state = [];

	_state set [2, animationState player];
	player action ["SwitchWeapon", player, player, -1];

	private _ammoBox = createSimpleObject ["Box_NATO_Ammo_F", [random -10000, random -10000, 1000 + random 10000]];
	_state set [0, _ammoBox];

	_state set [1, ""];

	private _discardAction = player addAction ["Discard ammo case", { [player, player] remoteExec ["JBA_S_DestroyStores", 2] }];
	_state set [3, _discardAction];

	_state;
};

JBAP_Stop =
{
	private _state = _this select 1;

	private _ammoBox = _state select 0;
	if (not isNull _ammoBox) then
	{
		deleteVehicle _ammoBox;
		_state set [0, objNull];
	};

	_state set [1, ""];

	private _originalAnimation = _state select 2;
	if (_originalAnimation != "") then
	{
		player playMove _originalAnimation;
		if (not ([player] call JBA_CanTransportOtherAmmo)) then
		{
			player allowSprint true;
			player forceWalk false;
		};
		_state set [2, ""];
	};

	private _discardAction = _state select 3;
	if (_discardAction != -1) then
	{
		player removeAction _discardAction;
		_state set [3, -1];
	};
};

JBAP_StoresChanged =
{
	private _unit = _this select 0;
	private _stores = _this select 1;

	if (_unit != player) then { diag_log format ["JBAP_StoresChanged called on player %1, but message was intended for %2", player, _unit] };

	private _state = player getVariable ["JBAP_State", nil];

	if (count _stores == 0) then
	{
		if (!isNil "_state") then
		{
			[player, _state] call JBAP_Stop;
			player setVariable ["JBAP_State", nil];
		};
	}
	else
	{
		if (isNil "_state") then
		{
			_state = [player] call JBAP_Start;
			player setVariable ["JBAP_State", _state];
		};

		private _newSpeed = [player] call JBAP_AmmoBoxCarrySpeed;

		private _ammoBox = _state select 0;
		private _speed = _state select 1;
		if (_newSpeed != _speed) then
		{
			[_ammoBox] call JBAP_PositionForCarry;

			_state set [1, _newSpeed];

			if (_newSpeed == "walk") then
			{
				player forceWalk true;
			}
			else
			{
				player forceWalk false;
				player allowSprint false;
			};
		};
	};
};

JBAP_Killed =
{
	private _player = _this select 0;

	[_player, _player] remoteExec ["JBA_S_DestroyStores", 2];
};

JBAP_GetInMan =
{
	private _player = _this select 0;

	private _state = player getVariable ["JBAP_State", nil];
	if (not isNil "_state") then
	{
		private _ammoBox = _state select 0;
		[_ammoBox, true] remoteExec ["hideObjectGlobal", 2, true];
	};
};

JBAP_GetOutMan =
{
	private _player = _this select 0;

	private _state = player getVariable ["JBAP_State", nil];
	if (not isNil "_state") then
	{
		private _ammoBox = _state select 0;
		[_ammoBox, false] remoteExec ["hideObjectGlobal", 2, true];
	};
};

// If first init, set up an event handler for player deaths
private _firstInit = player getVariable "JBAP_FirstInit";
if (isNil "_firstInit") then
{
	player setVariable ["JBAP_FirstInit", true];
	player addEventHandler ["Killed", JBAP_Killed];
	player addEventHandler ["GetInMan", JBAP_GetInMan];
	player addEventHandler ["GetOutMan", JBAP_GetOutMan];
};

// A callback from the server when the player's stores are changed
player setVariable ["JBA_OnStoresChanged", JBAP_StoresChanged];

player addAction ["Transfer ammo", { [cursorTarget] call JBA_ShowAmmoList }, nil, 0, false, true, "", "[cursorTarget] call JBA_ShowAmmoListCondition"];

[player, AMMO_BOX_CAPACITY] call JB_fnc_ammoInit;

