while { true } do
{
	waitUntil { sleep 1; not isNull (findDisplay 312) };

	(findDisplay 312) displayAddEventHandler ["KeyDown",
		{
			private _key = _this select 1;
			private _isShift = _this select 2;
			private _isControl = _this select 3;
			private _isAlt = _this select 4;

			private _override = false;

			if (_key == 38 && _isShift && _isControl) then
			{
				_override = true;

				[] call SPM_CuratorLight;
			};

			_override;
		}];

	waitUntil { sleep 1; isNull (findDisplay 312) };
};