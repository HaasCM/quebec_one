private _condition = _this select 0;
private _timeout = param [1, 10, [0]];
private _interval = param [2, 0.1, [0]];

private _timeoutTime = diag_tickTime + _timeout;

waitUntil { sleep _interval; diag_tickTime > _timeoutTime || { call _condition }};

call _condition