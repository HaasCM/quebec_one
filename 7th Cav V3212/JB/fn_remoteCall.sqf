private _arguments = _this select 0;
private _function = _this select 1;
private _target = _this select 2;
private _timeout = param [3, JBRC_TIMEOUT, [0]];

JBRC_CriticalSection call JB_fnc_criticalSectionEnter;

private _callIndex = count JBRC_PendingRemoteCalls;
JBRC_PendingRemoteCalls pushBack [JBRC_PENDING];

JBRC_CriticalSection call JB_fnc_criticalSectionLeave;

private _callData = [clientOwner, _callIndex, _function];
([_callData] + [_arguments]) remoteExec ["JBRC_ClientCall", _target];

private _timeout = diag_tickTime + JBRC_TIMEOUT;
waitUntil { diag_tickTime > _timeout || ((JBRC_PendingRemoteCalls select _callIndex) select 0) == JBRC_COMPLETE };

private _callResult = JBRC_PendingRemoteCalls select _callIndex;
if (_callResult select 0 == JBRC_PENDING) then
{
	_callResult set [0, _timeout];
};

JBRC_CriticalSection call JB_fnc_criticalSectionEnter;

if (_callIndex == (count JBRC_PendingRemoteCalls) - 1) then
{
	for "_i" from (count JBRC_PendingRemoteCalls) - 1 to 0 step -1 do
	{
		if (((JBRC_PendingRemoteCalls select _i) select 0) == JBRC_PENDING) exitWith {};

		JBRC_PendingRemoteCalls deleteAt _i;
	};
};

JBRC_CriticalSection call JB_fnc_criticalSectionLeave;

_callResult;