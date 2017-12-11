waituntil { not isNull (findDisplay 46) };
	
(findDisplay 46) displayAddEventHandler ["KeyDown",
	{
		private _override = false;

		private _display = _this select 0;
		private _encodedValue = _this select 1;

		private _isShift = _this select 2;
		private _isCtrl  = _this select 3;
		private _isAlt   = _this select 4;

		if (isNull getAssignedCuratorLogic player && { (inputAction "curatorinterface") > 0 }) then
		{
			titleText ["Zeus pinging is disabled.  Use chat to contact any available game masters or military police.", "BLACK IN", 3];
			_override = true;
		};

		_override
	}];
