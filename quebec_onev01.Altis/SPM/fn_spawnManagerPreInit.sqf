/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

#define SPAWN_CONFLICT_RANGE 20
#define NO_SCRIPT 0

SPM_SpawnManager_Update =
{
	params ["_manager"];

	private _queues = OO_GET(_manager,SpawnManager,Queues);

	for "_i" from count _queues - 1 to 0 step -1 do
	{
		private _queue = _queues select _i;
		private _requests = _queue select 0;
		private _pendingScript = _queue select 1;

		if (typeName _pendingScript == typeName NO_SCRIPT) then
		{
			if (count _requests == 0) then
			{
				_queues deleteAt _i;
			}
			else
			{
				private _request = _requests select 0;
				_pendingScript = ([_request select 0, _request select 1] + (_request select 3)) spawn (_request select 2);
				_queue set [1, _pendingScript];
			};
		}
		else
		{
			if (scriptDone _pendingScript) then
			{
				_queue set [1, NO_SCRIPT];
				_requests deleteAt 0;
			};
		};
	};
};

SPM_SpawnManager_ScheduleSpawn =
{
	params ["_manager", "_position", "_direction", "_code", "_parameters"];

	private _request = [_position, _direction, _code, _parameters];

	private _queues = OO_GET(_manager,SpawnManager,Queues);

	scopeName "function";
	private _matchedQueue = [];
	{
		private _requests = _x select 0;
		if (count _requests > 0) then
		{
			private _lastRequest = _requests select (count _requests - 1);
			if ((_lastRequest select 0) distance _position < SPAWN_CONFLICT_RANGE) then { _matchedQueue = _x; breakTo "function" };
		};
	} forEach _queues;

	if (count _matchedQueue > 0) then
	{
		private _requests = _matchedQueue select 0;
		_requests pushBack _request;
	}
	else
	{
		_queues pushBack [[_request], NO_SCRIPT];
	};
};

SPM_SpawnManager_Delete =
{
	params ["_manager"];

	private _queues = OO_GET(_manager,SpawnManager,Queues);

	private _pendingScripts = OO_GET(_manager,SpawnManager,PendingScripts);
	{
		private _pendingScript = _x select 1;
		if (typeName _pendingScript != typeName NO_SCRIPT) then { terminate _pendingScript };
	} forEach _queues;

	OO_SET(_manager,SpawnManager,Queues,[]);
};

OO_BEGIN_CLASS(SpawnManager);
	OO_OVERRIDE_METHOD(SpawnManager,Root,Delete,SPM_SpawnManager_Delete);
	OO_DEFINE_METHOD(SpawnManager,Update,SPM_SpawnManager_Update);
	OO_DEFINE_METHOD(SpawnManager,ScheduleSpawn,SPM_SpawnManager_ScheduleSpawn);
	OO_DEFINE_PROPERTY(SpawnManager,Queues,"ARRAY",[]); // [requests, active-script]
OO_END_CLASS(SpawnManager);

