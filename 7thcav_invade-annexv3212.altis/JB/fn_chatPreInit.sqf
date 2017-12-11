JB_CHAT_MonitorChat =
{
	private _chatDisplay = 0;
	private _chatControl = 0;

	disableSerialization;

	while { not isNil "JB_CHAT_Handlers" } do
	{
		JB_CHAT_Message = [];

		waitUntil { _chatDisplay = findDisplay 24; not isNull _chatDisplay };

		_chatControl = _chatDisplay displayCtrl 101;
		_chatControl ctrlAddEventHandler ["KeyUp", { JB_CHAT_Message = [ctrlText ((findDisplay 63) displayCtrl 101), ctrlText (_this select 0)]; }];

		waitUntil { isNull _chatControl };

		if (count JB_CHAT_Message > 0) then
		{
			{
				JB_CHAT_Message call _x;
			} forEach JB_CHAT_Handlers;
		};

		sleep 0.1;
	};
};