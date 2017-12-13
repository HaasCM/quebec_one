// Override original ARMA sling loading with advanced sling loading script behavior

waituntil {!isnull (finddisplay 46)};
	
(findDisplay 46) displayAddEventHandler ["KeyDown",
	{
		private _override = false;

		private _display = _this select 0;
		private _encodedValue = _this select 1;

		private _isShift = _this select 2;
		private _isCtrl  = _this select 3;
		private _isAlt   = _this select 4;

		if (typeOf (vehicle player) isKindOf "Air" && { (inputAction "helislingloadmanager") == 0 } && { (inputAction "heliropeaction") > 0 }) then
		{
			_override = true;
				
			if ([] call ASL_Release_Cargo_Action_Check) then
			{
				[] call ASL_Release_Cargo_Action;
			}
			else
			{
				if ([] call ASL_Deploy_Ropes_Action_Check) then
				{
					[] call ASL_Deploy_Ropes_Action;
				};
			};
		};
		_override;
	}];
