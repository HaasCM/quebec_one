private _chatHandler = param [0, {}, [{}]];

if (isNil "JB_CHAT_Handlers") then
{
	JB_CHAT_Handlers = [];

	JB_CHAT_Monitor = [] spawn JB_CHAT_MonitorChat;
};

JB_CHAT_Handlers pushBack _chatHandler;