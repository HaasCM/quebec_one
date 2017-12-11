/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

#define INFANTRY_BORDERWIDTH 100
#define STRONGPOINT_BORDERWIDTH 350

OO_TRACE_DECL(SPM_Counterattack_Update) =
{
	params ["_counterattack"];

	private _times = OO_GET(_counterattack,Strongpoint,Times);

	private _endOfGracePeriod = (OO_GET(_times,StrongpointTimes,Start) + OO_GET(_counterattack,Counterattack,GracePeriod));
	if (diag_tickTime < _endOfGracePeriod) exitWith
	{
		OO_SET(_counterattack,Strongpoint,UpdateTime,_endOfGracePeriod);
	};

	private _updateTime = diag_tickTime + 10;
	OO_SET(_counterattack,Strongpoint,UpdateTime,_updateTime);

	private _infantry = OO_GET(_counterattack,Counterattack,Infantry);
	private _westForce = [INFANTRY_BORDERWIDTH] call OO_METHOD(_infantry,ForceCategory,GetForceLevelsWest); // West infantry in infantry area
	private _eastForce = [-1] call OO_METHOD(_infantry,ForceCategory,GetForceLevelsEast); // East infantry

	private _westRating = 0;
	{ _westRating = _westRating + OO_GET(_x,ForceRating,Rating); } forEach _westForce;

	private _eastRating = 0;
	{ _eastRating = _eastRating + OO_GET(_x,ForceRating,Rating); } forEach _eastForce;

	private _ratio = "No forces present";

	if (_westRating != 0 || _eastRating != 0) then
	{
		switch (true) do
		{
			case (_westRating == 0): { _ratio = "East unopposed" };
			case (_eastRating == 0): { _ratio = "West unopposed" };
			case (_westRating > _eastRating): { _ratio = format ["%1:1", (floor ((_westRating / _eastRating) * 10)) / 10] };
			default { _ratio = format ["1:%1", (floor ((_eastRating / _westRating) * 10)) / 10] };
		};
	};

	private _traceObject = OO_GET(_counterattack,Counterattack,_TraceObject);
	[_traceObject, "C1", format ["West/East Ratio: %1", _ratio]] call TRACE_SetObjectString;
	[_traceObject, "C2", format ["East Reserves %1", OO_GET(_infantry,ForceCategory,Reserves)]] call TRACE_SetObjectString;

	// Note that west units are rated at twice that of east.  So a 6:1 west:east force check is essentially a 3:1 numerical check.  Conversely, a 6:1 east:west check is a 12:1 numerical check

	// If the east's reserves are depleted and west force in the infantry area holds a 6:1 force superiority of infantry (no matter where the east infantry is), then west wins
	if (OO_GET(_infantry,ForceCategory,Reserves) <= 0 && _westRating >= _eastRating * 6) then
	{
		diag_log format ["SPM_Counterattack_Update: west wins - east: %1 vs west: %2", _eastRating, _westRating];
		OO_SET(_counterattack,Strongpoint,RunState,"completed-success");
	}
	else
	{
		private _eastForce = [INFANTRY_BORDERWIDTH] call OO_METHOD(_infantry,ForceCategory,GetForceLevelsEast); // East infantry in infantry area

		private _eastRating = 0;
		{ _eastRating = _eastRating + OO_GET(_x,ForceRating,Rating); } forEach _eastForce;

		// If the east holds a 6:1 force superiority of infantry in the infantry area, then west loses
		if (_eastRating > 0 && _eastRating >= _westRating * 6) then
		{
			diag_log format ["SPM_Counterattack_Update: east wins - east: %1 vs west: %2", _eastRating, _westRating];
			OO_SET(_counterattack,Strongpoint,RunState,"completed-failure");
		};
	};
};

OO_TRACE_DECL(SPM_Counterattack_Create) =
{
	params ["_counterattack", "_areaCenter", "_areaRadius"];

	OO_SET(_counterattack,Strongpoint,Name,"MainOperation-Counterattack");
	OO_SET(_counterattack,Strongpoint,InitializeObject,SERVER_InitializeObject);

	// Number of enemies total.  Counterattack will attempt to keep half that number active at all times
	private _garrisonCount = (count allPlayers * 3) max 32;

	private _areaPerSoldier = 625; // m^2
	private _garrisonRadius = sqrt (((_garrisonCount * 0.5) * _areaPerSoldier) / pi);

	private _counterattackPosition = _areaCenter;

	//TODO: A chain that increases the radius of search for garrison buildings.  It just sets the value of a "garrison-radius" variable between two limits in defined steps
	private _data = [];
	private _chain = [[SPM_Chain_FixedPosition, [_areaCenter]], [SPM_Chain_PositionToBuildings, [0, _areaRadius]], [SPM_Chain_BuildingsToEnterableBuildings, []], [SPM_Chain_EnterableBuildingsToOccupancyBuildings, [4]], [SPM_Chain_OccupancyBuildingsToGarrisonPosition, [_garrisonRadius, _garrisonCount, true]]];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (_complete) then
	{
		_counterattackPosition = [_data, "garrison-position"] call SPM_GetDataValue;
	};

	private _counterattackRadius = _garrisonRadius + STRONGPOINT_BORDERWIDTH;

	[_counterattackPosition, _counterattackRadius] call OO_METHOD_PARENT(_counterattack,Root,Create,Strongpoint);

	private _category = OO_NULL;
	private _categories = [];

	_area = [_counterattackPosition, 0, _counterattackRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(AirDefenseCategory);
	_categories pushBack _category;

	_category = [] call OO_CREATE(TransportCategory);
	private _transport = _category;
	_categories pushBack _category;

	_area = [_counterattackPosition, _counterattackRadius, _counterattackRadius + 1000] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(AirPatrolCategory);
	_categories pushBack _category;

	_area = [_counterattackPosition, _garrisonRadius, _counterattackRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(ArmorCategory);
	_categories pushBack _category;

	_area = [_counterattackPosition, 0, _garrisonRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,0);
	OO_SET(_category,InfantryGarrisonCategory,Transport,_transport);

	private _basicInfantryRatingEast = OO_GET(_category,ForceCategory,RatingsEast) select 0 select 1 select 0; // The rating of the first east soldier type

	private _garrisonRating = _garrisonCount * _basicInfantryRatingEast;

	private _basicInfantryRatingWest = OO_GET(_category,ForceCategory,RatingsWest) select 0 select 1 select 0; // The rating of the first west soldier type

	private _minimumWestRating = 0;
	private _minimumWestForce = [];
	while { _minimumWestRating < _garrisonRating * 0.5 } do
	{
		_minimumWestForce pushBack ([objNull, _basicInfantryRatingWest] call OO_CREATE(ForceRating));
		_minimumWestRating = _minimumWestRating + _basicInfantryRatingWest;
	};

	OO_SET(_category,ForceCategory,Reserves,_garrisonRating);
	OO_SET(_category,InfantryGarrisonCategory,MinimumWestForce,_minimumWestForce);

	_categories pushBack _category;

	private _infantry = _category;

	{
		[_x] call OO_METHOD(_counterattack,Strongpoint,AddCategory);
	} forEach _categories;

	OO_SET(_counterattack,Counterattack,Infantry,_infantry);

	private _innerMarker = createMarker [format ["Strongpoint-Counterattack-%1-Inner", OO_INSTANCE_ID(_counterattack)], _counterattackPosition];
	_innerMarker setMarkerShape "ellipse";
	_innerMarker setMarkerColor "ColorGreen";
	_innerMarker setMarkerBrush "border";
	_innerMarker setMarkerSize [_garrisonRadius + INFANTRY_BORDERWIDTH, _garrisonRadius + INFANTRY_BORDERWIDTH];

	private _outerMarker = createMarker [format ["Strongpoint-Counterattack-%1-Outer", OO_INSTANCE_ID(_counterattack)], _counterattackPosition];
	_outerMarker setMarkerShape "ellipse";
	_outerMarker setMarkerColor "ColorRed";
	_outerMarker setMarkerBrush "border";
	_outerMarker setMarkerSize [_counterattackRadius, _counterattackRadius];

	private _markers = [_innerMarker, _outerMarker];
	OO_SET(_counterattack,Counterattack,Markers,_markers);

	private _traceObject = "Land_FirePlace_F" createVehicle (_counterattackPosition vectorAdd ([1,0,0] vectorMultiply _counterattackRadius));
	_traceObject hideObjectGlobal true;
	OO_SET(_counterattack,Counterattack,_TraceObject,_traceObject);
};

OO_TRACE_DECL(SPM_Counterattack_Delete) =
{
	params ["_counterattack"];

	private _traceObject = OO_GET(_counterattack,Counterattack,_TraceObject);
	deleteVehicle _traceObject;

	private _markers = OO_GET(_counterattack,Counterattack,Markers);

	{
		deleteMarker _x;
	} forEach _markers;

	[] call OO_METHOD_PARENT(_counterattack,Root,Delete,Strongpoint);
};

OO_BEGIN_SUBCLASS(Counterattack,Strongpoint);
	OO_OVERRIDE_METHOD(Counterattack,Root,Create,SPM_Counterattack_Create);
	OO_OVERRIDE_METHOD(Counterattack,Root,Delete,SPM_Counterattack_Delete);
	OO_OVERRIDE_METHOD(Counterattack,Strongpoint,Update,SPM_Counterattack_Update);
	OO_DEFINE_PROPERTY(Counterattack,Markers,"ARRAY",[]);
	OO_DEFINE_PROPERTY(Counterattack,GracePeriod,"SCALAR",120);
	OO_DEFINE_PROPERTY(Counterattack,Infantry,"ARRAY",OO_NULL);
	OO_DEFINE_PROPERTY(Counterattack,_TraceObject,"OBJECT",objNull);
OO_END_SUBCLASS(Counterattack);