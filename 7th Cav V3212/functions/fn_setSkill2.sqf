private _aimingAdjustment = 0.005 * ((count allPlayers - 20) max 0);

{
	_x setSkill ["aimingAccuracy", 0.05 + _aimingAdjustment];
	_x setSkill ["aimingShake", 0.05 + _aimingAdjustment];
	_x setSkill ["aimingSpeed", 0.05 + _aimingAdjustment];
	_x setSkill ["spotDistance", 0.6];
	_x setSkill ["spotTime", 0.8];

	_x setSkill ["commanding", 1];
	_x setSkill ["courage", 1];
	_x setSkill ["endurance", 1];
	_x setSkill ["general", 1];
	_x setSkill ["reloadSpeed", 1];
} forEach (_this select 0);