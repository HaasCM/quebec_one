VC_EnableChannel =
{
	params ["_channel", "_enabled"];

	_channel enableChannel _enabled;

	//TODO: If a channel is being completely disabled, change channels to one that is enabled.
	
	// As of ARMA V1.72, using channelEnabled on a disabled channel will change channels.  the
	// problem has been reported and I'm waiting on a fix.
};

VC_MonitorChannels =
{
	while { true } do
	{
		sleep 1;

		if (not isNull player) then
		{
			[0, not isNull getAssignedCuratorLogic player] call VC_EnableChannel;

			if (vehicle player != player) then
			{
				[4, true] call VC_EnableChannel;
			}
			else
			{
				[4, false] call VC_EnableChannel;

				// ARMA doesn't move the player off a disabled channel, so do it manually
				if (currentChannel == 4) then
				{
					setCurrentChannel 3; // Switch to group
				};
			};
		};
	};

	[] spawn VC_MonitorChannels;
};

0 enableChannel false; // No global channel
1 enableChannel [true, false]; // No side voice
2 enableChannel false; // No command channel

setCurrentChannel 3; // Switch to group

[] spawn VC_MonitorChannels;
