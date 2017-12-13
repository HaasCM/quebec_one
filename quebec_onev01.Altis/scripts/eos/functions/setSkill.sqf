_grp=(_this select 0);
_skillArray=(_this select 1);					
					
_skillset = server getvariable _skillArray;
{
	_unit = _x;
	{
		_skillvalue = (_skillset select _forEachIndex) * (0.8 + random 0.4);
		_unit setSkill [_x,_skillvalue];
	} forEach ['aimingAccuracy','aimingShake','aimingSpeed','spotDistance','spotTime','courage','reloadSpeed','commanding','general'];

	private _aimingAdjustment = 0.005 * ((count allPlayers - 20) max 0);
	_unit setSkill ["aimingAccuracy", (_unit skill "aimingAccuracy") + _aimingAdjustment];
	_unit setSkill ["aimingShake", (_unit skill "aimingShake") + _aimingAdjustment];
	_unit setSkill ["aimingSpeed", (_unit skill "aimingSpeed") + _aimingAdjustment];

	if (EOS_DAMAGE_MULTIPLIER != 1) then {_unit removeAllEventHandlers "HandleDamage";_unit addEventHandler ["HandleDamage",{_damage = (_this select 2)*EOS_DAMAGE_MULTIPLIER;_damage}];};
	if (EOS_KILLCOUNTER) then {_unit addEventHandler ["killed", "null=[] execVM ""scripts\eos\functions\EOS_KillCounter.sqf"""]};
	// ADD CUSTOM SCRIPTS TO UNIT HERE
} forEach (units _grp); 