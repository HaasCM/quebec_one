/*
Author:

	Quiksilver

Last modified:

	12/05/2014

Description:

	Main AO mission control

______________________________________________*/

currentAO = "";
publicVariable "currentAO";

defendAO = "";
publicVariable "defendAO";

while { true } do
{
	private _currentMission = execVM format ["mission\main\attackDefend.sqf"];

	while { not scriptDone _currentMission } do
	{
		sleep 5;
	};

	sleep (15 + random 10);
};
