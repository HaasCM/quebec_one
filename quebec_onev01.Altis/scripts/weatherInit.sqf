[] spawn
{
	setWind [1,1,false];

	private _firstUpdate = true;
	private _overcast = 0;
	private _nextOvercastUpdate = 0;
	private _rain = 0;
	private _nextRainUpdate = 0;
	private _time = 0;

	while { true } do
	{
		_time = diag_tickTime;

		10 setFog 0;

		if (_time >= _nextOvercastUpdate) then
		{
			_overcast = random [0, 0, 1];
			_nextOvercastUpdate = _time + 45 * 60 + random (15 * 60);

			if (_firstUpdate) then
			{
				0 setOvercast _overcast;
				forceWeatherChange;
				_firstUpdate = false;
			};
		};

		0 setOvercast (if (_overcast > overcast) then { 1 } else { 0 });
		0 setWindForce overcast;
		0 setWindStr overcast;

		if (_time >= _nextRainUpdate) then
		{
			_rain = if (random 1.0 < overcast) then { overcast } else { 0 };
			_nextRainUpdate = _time + 5 * 60 + random (5 * 60);

			10 setRain _rain;
			10 setLightnings _rain;
			10 setGusts _rain;
		};

		setTimeMultiplier (if (daytime > 19 + (40/60) || daytime < 4 + (20/60)) then { 9.0 } else { 1.0 });

		sleep 10;
	};
};