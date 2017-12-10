/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

SPM_StrongpointArea_Create =
{
	params ["_area", "_center", "_innerRadius", "_outerRadius"];

	OO_SET(_area,StrongpointArea,Center,_center);
	OO_SET(_area,StrongpointArea,InnerRadius,_innerRadius);
	OO_SET(_area,StrongpointArea,OuterRadius,_outerRadius);
};

SPM_StrongpointArea_GetNearestLocation =
{
	params ["_area"];

	private _nearestLocation = OO_GET(_area,StrongpointArea,NearestLocation);
	if (isNull _nearestLocation) then
	{
		private _center = OO_GET(_area,StrongpointArea,Center);

		private _locations = [];

		private _radius = 1000;
		while { count _locations == 0 } do
		{
			_locations = nearestLocations [_center, ["NameVillage", "NameCity", "NameCityCapital"], _radius, _center];
			_radius = _radius + 1000;
		};

		_nearestLocation = _locations select 0;

		OO_SET(_area,StrongpointArea,NearestLocation,_nearestLocation);
	};

	_nearestLocation;
};

OO_BEGIN_CLASS(StrongpointArea);
	OO_OVERRIDE_METHOD(StrongpointArea,Root,Create,SPM_StrongpointArea_Create);
	OO_DEFINE_METHOD(StrongpointArea,GetNearestLocation,SPM_StrongpointArea_GetNearestLocation);
	OO_DEFINE_PROPERTY(StrongpointArea,Center,"ARRAY",[]);
	OO_DEFINE_PROPERTY(StrongpointArea,InnerRadius,"SCALAR",0);
	OO_DEFINE_PROPERTY(StrongpointArea,OuterRadius,"SCALAR",0);
	OO_DEFINE_PROPERTY(StrongpointArea,NearestLocation,"LOCATION",locationNull);
OO_END_CLASS(StrongpointArea);

SPM_Strongpoint_FindByName =
{
	params ["_name"];

	private _parameters = [_name];
	private _code =
		{
			params ["_name"];
			if (OO_GET(_x,Strongpoint,Name) == _name) exitWith { true };
			false;
		};
	private _strongpoint = OO_FOREACHINSTANCE(Strongpoint,_parameters,_code);

	_strongpoint
};

// The time that players have to populate the area before win/lose checks start
#define SPM_GRACE_PERIOD 120

SPM_Strongpoint_AddCategory =
{
	params ["_strongpoint", "_category"];

	OO_GET(_strongpoint,Strongpoint,Categories) pushBack _category;
	OO_SETREF(_category,Category,Strongpoint,_strongpoint);
};

SPM_Strongpoint_Run =
{
	params ["_strongpoint"];

	private _spawnManager = OO_GET(_strongpoint,Strongpoint,SpawnManager);
	private _times = OO_GET(_strongpoint,Strongpoint,Times);
	OO_SET(_times,StrongpointTimes,Start,diag_tickTime);

	OO_SET(_strongpoint,Strongpoint,RunState,"running");

	while { OO_GET(_strongpoint,Strongpoint,RunState) == "running" } do
	{
		if (OO_GET(_strongpoint,Strongpoint,RunState) == "command-terminated") exitWith {};

		private _time = diag_tickTime;

		if (_time > (OO_GET(_times,StrongpointTimes,Start) + OO_GET(_times,StrongpointTimes,Duration))) then
		{
			OO_SET(_strongpoint,Strongpoint,RunState,"timeout");
		}
		else
		{
			if (_time > OO_GET(_strongpoint,Strongpoint,UpdateTime)) then
			{
				private _updateScript = [_strongpoint] spawn { params ["_strongpoint"]; [] call OO_METHOD(_strongpoint,Strongpoint,Update); };
				waitUntil { sleep 0.1; scriptDone _updateScript };
			};

			{
				private _category = _x;

				if (_time > OO_GET(_category,Category,UpdateTime)) then
				{
					_updateScript = [_category] spawn { params ["_category"]; [] call OO_METHOD(_category,Category,Update); };
					waitUntil { sleep 0.1; scriptDone _updateScript };
				};
			} forEach OO_GET(_strongpoint,Strongpoint,Categories);

			if (OO_GET(_strongpoint,Strongpoint,RunState) == "running") then
			{
				_updateScript = [_spawnManager] spawn { params ["_spawnManager"]; [] call OO_METHOD(_spawnManager,SpawnManager,Update); };
				waitUntil { sleep 0.1; scriptDone _updateScript };
			};
		};

		sleep 1;
	};
};

SPM_Strongpoint_Create =
{
	params ["_strongpoint", "_center", "_radius"];

	OO_SET(_strongpoint,Strongpoint,Position,_center);
	OO_SET(_strongpoint,Strongpoint,Radius,_radius);

	private _times = [] call OO_CREATE(StrongpointTimes);
	OO_SET(_strongpoint,Strongpoint,Times,_times);

	private _spawnManager = [] call OO_CREATE(SpawnManager);
	OO_SET(_strongpoint,Strongpoint,SpawnManager,_spawnManager);
};

SPM_Strongpoint_Delete =
{
	params ["_strongpoint"];

	private _times = OO_GET(_strongpoint,Strongpoint,Times);
	call OO_DELETE(_times);

	private _categories = OO_GET(_strongpoint,Strongpoint,Categories);
	while { count _categories > 0 } do
	{
		private _category = _categories deleteAt 0;

		call OO_DELETE(_category);
	};
};

OO_BEGIN_CLASS(StrongpointTimes);
	OO_DEFINE_PROPERTY(StrongpointTimes,Start,"SCALAR",0);
	OO_DEFINE_PROPERTY(StrongpointTimes,Duration,"SCALAR",1e30);
OO_END_CLASS(StrongpointTimes);

OO_BEGIN_CLASS(Strongpoint);
	OO_OVERRIDE_METHOD(Strongpoint,Root,Create,SPM_Strongpoint_Create);
	OO_OVERRIDE_METHOD(Strongpoint,Root,Delete,SPM_Strongpoint_Delete);
	OO_DEFINE_METHOD(Strongpoint,Run,SPM_Strongpoint_Run);
	OO_DEFINE_METHOD(Strongpoint,Update,{});
	OO_DEFINE_METHOD(Strongpoint,AddCategory,SPM_Strongpoint_AddCategory);
	OO_DEFINE_PROPERTY(Strongpoint,UpdateTime,"SCALAR",0);
	OO_DEFINE_PROPERTY(Strongpoint,Position,"ARRAY",[]);
	OO_DEFINE_PROPERTY(Strongpoint,Radius,"SCALAR",0);
	OO_DEFINE_PROPERTY(Strongpoint,Name,"STRING","");
	OO_DEFINE_PROPERTY(Strongpoint,RunState,"STRING","starting"); // starting, running, command-terminated, timeout, completed-failed, completed-success, completed-error
	OO_DEFINE_PROPERTY(Strongpoint,Times,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(Strongpoint,Categories,"ARRAY",[]);
	OO_DEFINE_PROPERTY(Strongpoint,SpawnManager,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(Strongpoint,InitializeObject,"CODE",{});
OO_END_CLASS(Strongpoint);

OO_TRACE_DECL(SPM_Category_InitializeObject) =
{
	params ["_category", "_object"];

	private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
	private _initializeObject = OO_GET(_strongpoint,Strongpoint,InitializeObject);

	[_category,_object] call _initializeObject;
};

OO_BEGIN_CLASS(Category);
	OO_DEFINE_METHOD(Category,Update,{});
	OO_DEFINE_PROPERTY(Category,Strongpoint,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(Category,InitializeObject,"CODE",SPM_Category_InitializeObject); // By default, use the strongpoint's initializer
	OO_DEFINE_PROPERTY(Category,UpdateTime,"SCALAR",0);
OO_END_CLASS(Category);
