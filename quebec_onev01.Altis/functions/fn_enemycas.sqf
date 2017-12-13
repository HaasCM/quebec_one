/*
@filename: aoReinforcementJet.sqf
Author:

	Quiksilver
	
Last modified:

	26/10/2014 ArmA 1.32 by Quiksilver
	
Description:

	Spawn an enemy CAS jet
______________________________________________________*/

private _casArray = ["O_Plane_CAS_02_F", "I_Plane_Fighter_03_AA_F", "O_Plane_Fighter_02_Stealth_F", "I_Plane_Fighter_04_F"];

private _jetLimit = 2;

if ((count enemyCasArray) < _jetLimit) then
{
	private _spawnPos = [(markerPos currentAO), 5000, random 360] call BIS_fnc_relPos;
	_spawnPos set [2, 3000];

	private _spawnDir = _spawnPos getDir (markerPos currentAO);

	if (isNull enemyCASGroup) then { enemyCASGroup = createGroup east; };

	private _spawn = [_spawnPos, _spawnDir, _casArray call BIS_fnc_selectRandom, enemyCASGroup] call BIS_fnc_spawnVehicle;

	_jet = _spawn select 0;
	_pilot = driver _jet;

	_jet engineOn true;
	_jet allowCrewInImmobile true;
	_jet flyInHeight 1000;
	_jet lock 2;

	enemyCASGroup setCombatMode "RED";
	enemyCASGroup setBehaviour "COMBAT";
	enemyCASGroup setSpeedMode "FULL";

	[(units enemyCASGroup)] call QS_fnc_setSkill2;
	
	[enemyCASGroup, getMarkerPos currentAO] call BIS_fnc_taskAttack;
	
	[[_pilot, _jet]] call SERVER_CurateEditableObjects;
	
	enemyCasArray pushBack _jet;
	
	[_jet,_pilot] spawn
	{
		private _jet = _this select 0;
		private _pilot = _this select 1;

		private _group = group _pilot;

		while { alive _jet } do
		{
			_jet flyInHeight (200 + (random 850));

			{
				_group reveal [_x, 4];
			} forEach (_jet nearEntities [["Air"], 7500]);

			sleep 60;
		};

		enemyCasArray = enemyCasArray - [_jet];

		sleep 30;

		if (!isNull _jet) then { deleteVehicle _jet; };
		if (!isNull _pilot) then { deleteVehicle _pilot; };
	};
};