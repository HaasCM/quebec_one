/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

SPM_Transport_CallupsEastAir =
[
	["I_Heli_Transport_02_F", [1, 2,
			{
				private _flyInHeight = 50;
				(_this select 0) setPos (getPos (_this select 0) vectorAdd [0,0,_flyInHeight]);
				(_this select 0) flyInHeight _flyInHeight;
			}]],
	["O_Heli_Light_02_unarmed_F", [1, 2,
			{
				private _flyInHeight = 50;
				(_this select 0) setPos (getPos (_this select 0) vectorAdd [0,0,_flyInHeight]);
				(_this select 0) flyInHeight _flyInHeight;
			}]],
	["O_Heli_Attack_02_F", [1, 2,
			{
				private _flyInHeight = 50;
				(_this select 0) setPos (getPos (_this select 0) vectorAdd [0,0,_flyInHeight]);
				(_this select 0) flyInHeight _flyInHeight;
				[_this select 0]  call SPM_Transport_RemoveWeapons;
				(_this select 0) addMagazine "2000Rnd_65x39_Belt_Tracer_Green_Splash";
				(_this select 0) addWeapon "LMG_Minigun_heli";
			}]]
];

SPM_Transport_RatingsEastAir = SPM_Transport_CallupsEastAir apply { [_x select 0, (_x select 1) select [0, 2]] };

SPM_Transport_CallupsEastGround =
[
	["O_APC_Tracked_02_cannon_F",
		[1, 3,
			{
				[_this select 0] call SPM_Transport_RemoveWeapons;
				(_this select 0) animate ["HideTurret", 1];
			}]],
	["O_APC_Tracked_02_cannon_F", // Intentional duplicate to increase odds of this vehicle type
		[1, 3,
			{
				[_this select 0] call SPM_Transport_RemoveWeapons;
				(_this select 0) animate ["HideTurret", 1];
			}]],
	["O_APC_Tracked_02_cannon_F",
		[1, 3,
			{
				[_this select 0] call SPM_Transport_RemoveWeapons;
				(_this select 0) addMagazine "500Rnd_65x39_Belt_Tracer_Green_Splash";
				(_this select 0) addWeapon "LMG_RCWS";
			}]],
	["O_APC_Wheeled_02_rcws_F",
		[1, 3,
			{
				[_this select 0] call SPM_Transport_RemoveWeapons;

				(_this select 0) addMagazine "500Rnd_65x39_Belt_Tracer_Green_Splash";
				(_this select 0) addWeapon "LMG_RCWS";
			}
		]]
];

SPM_Transport_RatingsEastGround = SPM_Transport_CallupsEastGround apply { [_x select 0, (_x select 1) select [0, 2]] };

SPM_Transport_CallupsEastBoat =
[
	["O_Boat_Armed_01_hmg_F",
		[1, 3,
			{
				[_this select 0] call SPM_Transport_RemoveWeapons;
				(_this select 0) addMagazine "500Rnd_65x39_Belt_Tracer_Green_Splash";
				(_this select 0) addWeapon "LMG_RCWS";
			}]]
];

SPM_Transport_RatingsEastBoat = SPM_Transport_CallupsEastBoat apply { [_x select 0, (_x select 1) select [0, 2]] };

SPM_Transport_CallupsEast = SPM_Transport_CallupsEastAir + SPM_Transport_CallupsEastGround;
SPM_Transport_RatingsEast = SPM_Transport_CallupsEast apply { [_x select 0, (_x select 1) select [0, 2]] };

SPM_Transport_RatingsCivilian =
[
	["C_Hatchback_01_F", [1, 1, {}]],
	["C_Offroad_01_unarmed_F", [1, 1, {}]],
	["C_SUV_01_F", [1, 1, {}]],
	["C_Offroad_01_F", [1, 1, {}]]
];

SPM_Transport_RemoveWeapons =
{
	private _vehicle = _this select 0;
	{
		_vehicle removeWeapon _x;
	} foreach weapons _vehicle;

	{
		_vehicle removeMagazines _x;
	} forEach magazines _vehicle;
};

OO_TRACE_DECL(SPM_Transport_Update) =
{
	params ["_category"];

	private _updateTime = diag_tickTime + 5;
	OO_SET(_category,Category,UpdateTime,_updateTime);

	private _operations = OO_GET(_category,TransportCategory,Operations);

	for "_i" from (count _operations - 1) to 0 step -1 do
	{
		private _operation = _operations select _i;
		if (count OO_GET(_operation,TransportOperation,Requests) == 0) then { _operation = _operations deleteAt _i; call OO_DELETE(_operation) };
	};

	{
		[_category] call OO_METHOD(_x,TransportOperation,Update);
	} forEach _operations;
};

OO_TRACE_DECL(SPM_Transport_AddOperation) =
{
	params ["_category", "_operation"];

	OO_SETREF(_operation,TransportOperation,Category,_category);

	private _operations = OO_GET(_category,TransportCategory,Operations);
	_operations pushBack _operation;
};

OO_TRACE_DECL(SPM_Transport_Delete) =
{
	params ["_category"];

	private _operations = OO_GET(_category,TransportCategory,Operations);
	while { count _operations > 0 } do
	{
		private _operation = _operations select 0;
		[] call OO_METHOD(_operation,Root,Delete);
		_operations deleteAt 0;
	};
};

OO_TRACE_DECL(SPM_Transport_Create) =
{
	params ["_category"];

	OO_SET(_category,ForceCategory,RatingsEast,SPM_Transport_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_Transport_CallupsEast);
};

OO_TRACE_DECL(SPM_TransportRequest_DetachVehicle) =
{
	params ["_request"];

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	if (count _forceUnit > 0) then
	{
		OO_SET(_forceUnit,ForceUnit,Vehicle,objNull);
	};
};

OO_TRACE_DECL(SPM_TransportRequest_Create) =
{
	params ["_request", "_passengers", "_destination"];

	OO_SET(_request,TransportRequest,Passengers,_passengers);
	OO_SET(_request,TransportRequest,Destination,_destination);
};

OO_TRACE_DECL(SPM_TransportRequest_Delete) =
{
	params ["_request"];

	[_request] call OO_GET(_request,TransportRequest,OnSalvage);

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	if (count _forceUnit > 0) then
	{
		private _operation = OO_GETREF(_request,TransportRequest,Operation);
		private _category = OO_GETREF(_operation,TransportOperation,Category);
		[_category, _forceUnit] call SPM_Force_SalvageForceUnit;
	};
};

OO_TRACE_DECL(SPM_TransportOperation_Update) =
{
	params ["_operation", "_category"];

	private _callups = OO_GET(_operation,TransportOperation,VehicleCallups);
	if (count _callups == 0) then
	{
		_callups = OO_GET(_category,ForceCategory,CallupsEast);
		OO_SET(_operation,TransportOperation,VehicleCallups,_callups);
	};

	private _requests = OO_GET(_operation,TransportOperation,Requests);

	for "_i" from (count _requests - 1) to 0 step -1 do
	{
		private _request = _requests select _i;
		if (OO_GET(_request,TransportRequest,State) == "complete") then { _request = _requests deleteAt _i; call OO_DELETE(_request) };
	};

	{
		[_category, _operation] call OO_METHOD(_x,TransportRequest,Update);
	} forEach _requests;
};

OO_TRACE_DECL(SPM_TransportOperation_AddRequest) =
{
	params ["_operation", "_request", "_index"];

	OO_SETREF(_request,TransportRequest,Operation,_operation);

	private _requests = OO_GET(_operation,TransportOperation,Requests);

	if (isNil "_index") then
	{
		_requests pushBack _request;
	}
	else
	{
		_requests = (_requests select [0, _index]) + [_request] + (_requests select [_index, 1e4]);
		OO_SET(_operation,TransportOperation,Requests,_requests);
	};
};

OO_TRACE_DECL(SPM_TransportOperation_Create) =
{
	params ["_operation", "_area", "_spawnpoint"];

	OO_SET(_operation,TransportOperation,Area,_area);
	OO_SET(_operation,TransportOperation,Spawnpoint,_spawnpoint);
};

OO_TRACE_DECL(SPM_TransportOperation_Delete) =
{
	params ["_operation"];

	private _requests = OO_GET(_operation,TransportOperation,Requests);
	while { count _requests > 0 } do
	{
		private _request = _requests select 0;
		[] call OO_METHOD(_request,Root,Delete);
		_requests deleteAt 0;
	};
};

OO_BEGIN_CLASS(TransportRequest);
	OO_OVERRIDE_METHOD(TransportRequest,Root,Create,SPM_TransportRequest_Create);
	OO_OVERRIDE_METHOD(TransportRequest,Root,Delete,SPM_TransportRequest_Delete);
	OO_DEFINE_METHOD(TransportRequest,Update,{});
	OO_DEFINE_METHOD(TransportRequest,DetachVehicle,SPM_TransportRequest_DetachVehicle);
	OO_DEFINE_PROPERTY(TransportRequest,VehicleCallup,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequest,Operation,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(TransportRequest,Passengers,"SCALAR",0);
	OO_DEFINE_PROPERTY(TransportRequest,Destination,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequest,ForceUnit,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequest,Ratings,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequest,State,"STRING","create"); // create, pending, to-destination, retire, complete
	OO_DEFINE_PROPERTY(TransportRequest,ClientData,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequest,OnLoad,"CODE",{true});
	OO_DEFINE_PROPERTY(TransportRequest,OnUpdate,"CODE",{});
	OO_DEFINE_PROPERTY(TransportRequest,OnArrive,"CODE",{});
	OO_DEFINE_PROPERTY(TransportRequest,OnSalvage,"CODE",{});
OO_END_CLASS(TransportRequest);

OO_BEGIN_CLASS(TransportOperation);
	OO_OVERRIDE_METHOD(TransportOperation,Root,Create,SPM_TransportOperation_Create);
	OO_OVERRIDE_METHOD(TransportOperation,Root,Delete,SPM_TransportOperation_Delete);
	OO_DEFINE_METHOD(TransportOperation,AddRequest,SPM_TransportOperation_AddRequest);
	OO_DEFINE_METHOD(TransportOperation,Update,SPM_TransportOperation_Update);
	OO_DEFINE_PROPERTY(TransportOperation,Category,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(TransportOperation,Area,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(TransportOperation,Spawnpoint,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportOperation,Requests,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportOperation,VehicleCallups,"ARRAY",[]);
OO_END_CLASS(TransportOperation);

OO_BEGIN_SUBCLASS(TransportCategory,ForceCategory);
	OO_OVERRIDE_METHOD(TransportCategory,Root,Create,SPM_Transport_Create);
	OO_OVERRIDE_METHOD(TransportCategory,Root,Delete,SPM_Transport_Delete);
	OO_OVERRIDE_METHOD(TransportCategory,Category,Update,SPM_Transport_Update);
	OO_DEFINE_METHOD(TransportCategory,AddOperation,SPM_Transport_AddOperation);
	OO_DEFINE_PROPERTY(TransportCategory,AirDefense,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(TransportCategory,Operations,"ARRAY",[]);
OO_END_SUBCLASS(TransportCategory);