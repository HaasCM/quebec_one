waituntil {!isnull (finddisplay 46)};

#include "\a3\editor_f\Data\Scripts\dikCodes.h"
	
(findDisplay 46) displayAddEventHandler ["KeyDown",
	{
		private _display = _this select 0;
		private _encodedValue = _this select 1;

		private _isShift = _this select 2;
		private _isCtrl  = _this select 3;
		private _isAlt   = _this select 4;

		private _handled = false;

		if (_encodedValue == DIK_H) then
		{
			player action ["SwitchWeapon", player, player, -1];
			if (vehicle player != player) then
			{
				PLAYER_WeaponGetIn = "";
			};
			_handled = true;
		};

		_handled;
	}];
