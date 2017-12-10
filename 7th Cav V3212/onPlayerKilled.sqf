private _oldPlayer = _this select 0;

RESPAWN_Loadout = getUnitLoadout _oldPlayer;

if (vehicle _oldPlayer != _oldPlayer) then
{
	[vehicle _oldPlayer] remoteExec ["JB_fnc_ejectDeadBodies", 2];
};