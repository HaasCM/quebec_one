PRIORITY_ReloadAAWeapon =
{
	private _vehicle = _this select 0;
	private _weapon = _this select 1;
	private _magazineType = _this select 5;

	if (([magazinesAmmo _vehicle, _magazineType] call BIS_fnc_findInPairs) == -1) then
	{
		if (_weapon in (_vehicle weaponsTurret [0])) then
		{
			[_vehicle, _magazineType] spawn
			{
				private _vehicle = _this select 0;
				private _magazineType = _this select 1;

				sleep (120 + random 60);

				if (alive _vehicle && alive ammoTruck) then
				{
					_vehicle removeMagazineTurret [_magazineType, [0]];
					_vehicle addMagazineTurret [_magazineType, [0]];
				};
			};
		};
	};
};

PRIORITY_ReloadArtilleryWeapon =
{
	private _vehicle = _this select 0;
	private _weapon = _this select 1;
	private _magazineType = _this select 5;

	if (([magazinesAmmo _vehicle, _magazineType] call BIS_fnc_findInPairs) == -1) then
	{
		if (_weapon in (_vehicle weaponsTurret [0])) then
		{
			[_vehicle, _magazineType] spawn
			{
				private _vehicle = _this select 0;
				private _magazineType = _this select 1;

				sleep 180;

				if (alive _vehicle && alive ammoTruck) then
				{
					_vehicle removeMagazineTurret [_magazineType, [0]];
					_vehicle addMagazineTurret [_magazineType, [0]];
				};
			};
		};
	};
};

SM_MissionActive = false; publicVariable "SM_MissionActive";
SM_MissionSucceeded = false; publicVariable "SM_MissionSucceeded";
SM_MissionRequested = false; publicVariable "SM_MissionRequested";

private _missionList =
[
	"destroyUrban",
	"HQcoast",
	"HQfia",
	"HQind",
	"HQresearch",
	"priorityAA",
	"priorityARTY",
	"secureChopper",
	"secureIntelUnit",
	"secureIntelVehicle",
	"secureRadar"
];

#define MIN_TIME_BETWEEN_PRIORITY_MISSIONS 3600

private _constantMissions = false;

private _lastPriorityMissionEnd = diag_tickTime;
private _nextMissionStart = diag_tickTime + 300 + random 600;
private _mission = "";

while { true } do
{
	private _currentTime = diag_tickTime;

	// If a mission is requested, pick one (that is not a priority mission) and start it immediately
	if (SM_MissionRequested) then
	{
		while { _mission = _missionList call BIS_fnc_selectRandom; _mission find "priority" == 0 } do
		{
		};
		_nextMissionStart = _currentTime;
	};

	if (_currentTime >= _nextMissionStart) then
	{
		if (not SM_MissionRequested) then
		{
			_mission = _missionList call BIS_fnc_selectRandom;
		};

		if (SM_MissionRequested || _constantMissions || (_mission find "priority" == 0 && _currentTime - _lastPriorityMissionEnd > MIN_TIME_BETWEEN_PRIORITY_MISSIONS && count allPlayers >= PARAMS_PlayersNeededForArmor)) then
		{
			private _currentMission = execVM format ["mission\side\missions\%1.sqf", _mission];

			SM_MissionActive = true; publicVariable "SM_MissionActive";
			SM_MissionSucceeded = false; publicVariable "SM_MissionSucceeded";
			SM_MissionRequested = false; publicVariable "SM_MissionRequested";

			waitUntil
			{
				sleep 3;
				scriptDone _currentMission
			};

			SM_MissionActive = false; publicVariable "SM_MissionActive";

			if (_mission find "priority" == 0) then { _lastPriorityMissionEnd = _currentTime };
		};

		if (not _constantMissions) then
		{
			_nextMissionStart = _currentTime + 300 + random 600;
		};
	};

	sleep 10;
};