JBRC_TIMEOUT = 2;

JBRC_PENDING = 0;
JBRC_COMPLETE = 1;
JBRC_TIMEDOUT = 2;

JBRC_CriticalSection = call JB_fnc_criticalSectionCreate;

JBRC_PendingRemoteCalls = [];

//TODO: remoteExecutedOwner says who called remotely, allowing us to get rid of (_callData select 0)
JBRC_ClientCall =
{
	private _callData = _this select 0;
	private _arguments = _this select 1;

	private _result = _arguments call compile format ["_this call %1", _callData select 2];;
	if (isNil "_result") then { _result = 0 };

	[_callData select 1, _result] remoteExec ["JBRC_RemoteCallResponse", _callData select 0];
};

JBRC_RemoteCallResponse =
{
	private _callIndex = _this select 0;
	private _result = _this select 1;

	JBRC_CriticalSection call JB_fnc_criticalSectionEnter;

	JBRC_PendingRemoteCalls set [_callIndex, [JBRC_COMPLETE, _result]];

	JBRC_CriticalSection call JB_fnc_criticalSectionLeave;
};