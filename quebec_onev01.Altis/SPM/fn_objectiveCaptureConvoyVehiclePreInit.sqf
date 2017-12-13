/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveCaptureConvoyVehicle_TransportOnLoad) =
{
	params ["_request"];

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	private _clientData = OO_GET(_request,TransportRequest,ClientData);
	private _objective = _clientData select 1;

	OO_SET(_objective,ObjectiveCaptureConvoyVehicle,Vehicle,_vehicle);
	_vehicle setVehicleLock "unlocked";

	private _operation = OO_GETREF(_request,TransportRequest,Operation);
	private _transport = OO_GETREF(_operation,TransportOperation,Category);
	private _sideWest = OO_GET(_transport,ForceCategory,SideWest);

	private _captureDistance = OO_GET(_objective,ObjectiveCaptureConvoyVehicle,CaptureDistance);
	private _secureArea = OO_GET(_objective,ObjectiveCaptureConvoyVehicle,SecureArea);
	if (_captureDistance != 1e30 || count _secureArea > 0) then
	{
		private _parameters = [_vehicle, _sideWest] call OO_CREATE(VehicleCaptureParameters);
		OO_SET(_parameters,VehicleCaptureParameters,CaptureDistance,_captureDistance);
		OO_SET(_parameters,VehicleCaptureParameters,SecureArea,_secureArea);
		OO_SET(_objective,ObjectiveCaptureConvoyVehicle,_VehicleCaptureParameters,_parameters);
	};

	_vehicle addEventHandler ["GetIn",
		{
			params ["_vehicle", "_position", "_unit", "_turret"];

			if (isPlayer _unit) then //TODO: Technically, any unit that is _sideWest per above
			{
				[_vehicle, -1] call JB_fnc_limitSpeed;
			};
		}];

	[_vehicle, "OCV", "OBJECTIVE"] call TRACE_SetObjectString;

	true
};

OO_TRACE_DECL(SPM_ObjectiveCaptureConvoyVehicle_ModifyConvoyOperation) =
{
	params ["_objective", "_convoyOperation"];

	private _mission = OO_GETREF(_objective,Category,Strongpoint);

	private _convoyVehicle = OO_GET(_objective,ObjectiveCaptureConvoyVehicle,ConvoyVehicle);
	private _request = [_convoyVehicle] call OO_METHOD(_mission,MissionInterceptConvoy,CreateRequest);
	private _clientData = OO_GET(_request,TransportRequest,ClientData);
	_clientData set [1, _objective];

	private _destination = OO_GET(_mission,Strongpoint,Position);
	OO_SET(_request,TransportRequest,Destination,_destination);
	OO_SET(_request,TransportRequest,OnLoad,SPM_ObjectiveCaptureConvoyVehicle_TransportOnLoad);

	private _requestCount = count OO_GET(_convoyOperation,TransportOperation,Requests);
	[_request, floor (_requestCount / 2)] call OO_METHOD(_convoyOperation,TransportOperation,AddRequest);

	OO_SETREF(_objective,ObjectiveCaptureConvoyVehicle,_VehicleRequest,_request);
	OO_SET(_objective,MissionObjective,State,"active");
};

OO_TRACE_DECL(SPM_ObjectiveCaptureConvoyVehicle_GetDescription) =
{
	params ["_objective"];

	OO_GET(_objective,ObjectiveCaptureConvoyVehicle,ObjectiveDescription);
};

OO_TRACE_DECL(SPM_ObjectiveCaptureConvoyVehicle_Update) =
{
	params ["_objective"];

	private _updateTime = diag_tickTime + 5;

	private _vehicle = OO_GET(_objective,ObjectiveCaptureConvoyVehicle,Vehicle);
	if (typeName _vehicle != typeName "") then
	{
#ifdef OO_TRACE
		diag_log format ["SPM_ObjectiveCaptureConvoyVehicle_Update: type %1 alive %2 null %3", typeof _vehicle, alive _vehicle, isNull _vehicle];
#endif
		if (isNull _vehicle) exitWith { OO_SET(_objective,MissionObjective,State,"error"); };
		if (not alive _vehicle) exitWith { OO_SET(_objective,MissionObjective,State,"failed"); };

		private _request = OO_GETREF(_objective,ObjectiveCaptureConvoyVehicle,_VehicleRequest);
		private _destination = OO_GET(_request,TransportRequest,Destination);

		if (_vehicle distance _destination < 100) exitWith { OO_SET(_objective,MissionObjective,State,"failed"); };

		private _parameters = OO_GET(_objective,ObjectiveCaptureConvoyVehicle,_VehicleCaptureParameters);
		if ([] call OO_METHOD(_parameters,VehicleCaptureParameters,IsCaptured)) then
		{
			[_vehicle] call JB_fnc_respawnVehicleInitialize;
			[_vehicle, 300, 5, 0, true] call JB_fnc_respawnVehicleWhenAbandoned;

			[] call OO_METHOD(_request,TransportRequest,DetachVehicle);
			[] call OO_METHOD(_parameters,VehicleCaptureParameters,Delete);
			OO_SET(_objective,ObjectiveCaptureConvoyVehicle,_VehicleCaptureParameters,[]);
			OO_SET(_objective,MissionObjective,State,"completed");
		};
	};

	OO_SET(_objective,Category,UpdateTime,_updateTime);
};

OO_TRACE_DECL(SPM_ObjectiveCaptureConvoyVehicle_Create) =
{
	params ["_objective", "_convoyVehicle", "_objectiveDescription"];

	OO_SET(_objective,ObjectiveCaptureConvoyVehicle,ConvoyVehicle,_convoyVehicle);
	OO_SET(_objective,ObjectiveCaptureConvoyVehicle,ObjectiveDescription,_objectiveDescription);
};

OO_BEGIN_SUBCLASS(ObjectiveCaptureConvoyVehicle,ConvoyObjective);
	OO_OVERRIDE_METHOD(ObjectiveCaptureConvoyVehicle,Root,Create,SPM_ObjectiveCaptureConvoyVehicle_Create);
	OO_OVERRIDE_METHOD(ObjectiveCaptureConvoyVehicle,Category,Update,SPM_ObjectiveCaptureConvoyVehicle_Update);
	OO_OVERRIDE_METHOD(ObjectiveCaptureConvoyVehicle,MissionObjective,GetDescription,SPM_ObjectiveCaptureConvoyVehicle_GetDescription);
	OO_OVERRIDE_METHOD(ObjectiveCaptureConvoyVehicle,ConvoyObjective,ModifyConvoyOperation,SPM_ObjectiveCaptureConvoyVehicle_ModifyConvoyOperation);
	OO_DEFINE_PROPERTY(ObjectiveCaptureConvoyVehicle,Vehicle,"OBJECT",""); // Junk value because we can't use objNull as our uninitialized state
	OO_DEFINE_PROPERTY(ObjectiveCaptureConvoyVehicle,ConvoyVehicle,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveCaptureConvoyVehicle,ObjectiveDescription,"STRING","Capture/destroy vehicle");
	OO_DEFINE_PROPERTY(ObjectiveCaptureConvoyVehicle,SecureArea,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveCaptureConvoyVehicle,CaptureDistance,"SCALAR",1e30);
	OO_DEFINE_PROPERTY(ObjectiveCaptureConvoyVehicle,_VehicleRequest,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveCaptureConvoyVehicle,_VehicleCaptureParameters,"ARRAY",[]);
OO_END_SUBCLASS(ObjectiveCaptureConvoyVehicle);