waituntil {!isnull (finddisplay 46)};

(findDisplay 46) displayAddEventHandler ["KeyDown",
	{
		private _override = false;

		if (vehicle player == player && { (_this select 1) == 0x2F }) then
		{
			private _animationState = animationState player;
			if (count _animationState > 16 && { [_animationState, "mov", "erc", ["tac", "run", "eva", "spr"], ["ras", "low"]] call JB_fnc_matchAnimationState }) then
			{
				[player, "AovrPercMrunSrasWrflDf"] remoteExec ["switchMove", 0];
				_override = true;
			};
		};

		_override
	}];
