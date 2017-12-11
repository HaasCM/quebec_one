if (not (player getVariable ["IsAdministrator", false])) then
{
	format ["%1 was ejected after attempting to enter the server in a restricted role (%2)", name player, roleDescription player] remoteExec ["systemchat", 0];
	endMission "ReservedMP";
};