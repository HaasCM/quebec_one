//#define TEST

#include "..\..\SPM\strongpoint.h"

AD_GetOperationList =
{
	private _aoMarkers = _this select 0;

	private _numberTargets = (count _aoMarkers) min (5 + round random 1);

	private _remainingTargets = +_aoMarkers;
	private _referenceLocation = getMarkerPos (selectRandom _remainingTargets);

	private _selectedOperations = [];
	while { count _selectedOperations < _numberTargets } do
	{
		private _max = 3000 + random 1000;
		private _idealTargets = [];
		while { count _idealTargets == 0 } do
		{
			_idealTargets = _remainingTargets select
				{
					private _distance = (getMarkerPos _x) distance2D _referenceLocation;
					_distance > 2000 && _distance < _max
				};
			_max = _max + 500;
		};

		private _nextTarget = selectRandom _idealTargets;

		_referenceLocation = getMarkerPos _nextTarget;
		_selectedOperations pushBack _nextTarget;
		_remainingTargets = _remainingTargets - [_nextTarget];
	};

	_selectedOperations
};

private _aoMarkersSW =
[
	"Skopos Castle",
	"Zaros Power Station",
	"Zaros",
	"Zaros Outpost",
	"Drimea Water Plant",
	"Eginio",
	"Panochori",
	"The Stadium",
	"Vikos Outpost",
	"Athanos",
	"Naftia Lighthouse",
	"Tafos Dump",
	"Panochori Bay",
	"Xirolimni Dam",
	"Sfaka",
	"Topolia",
	"Aggelochori",
	"Kavala",
	"The Crater",
	"Neri",
	"Neri Quarry",
	"Neri Bay",
	"Kavirida"
];

private _aoMarkersSE =
[
	"Feres",
	"Chalkeia",
	"Didymos Turbines",
	"Dorida",
	"Panagia",
	"Selakano",
	"Selakano Outpost",
	"Faronaki",
	"Mazi Bay",
	"Faronaki Quarry",
	"Kategidis Point",
	"Pyrgos Military Base",
	"Pyrgos",
	"Pyrgos Outpost",
	"Livadi Beach",
	"Selakano Airfield",
	"Aktinarki"
];

private _aoMarkersNW =
[
	"Northwest Outpost",
	"Pyrsos",
	"Factory",
	"Syrta",
	"Aristi Turbines",
	"Oreokastro Dump",
	"Negades",
	"Abdera",
	"Kore",
	"Oreokastro",
	"Galati Outpost",
	"Fotia Turbines",
	"Agios Konstantinos",
	"Faros",
	"Krya Nera Airbase",
	"Krya Nera Airfield",
	"Krya Nera Turbines",
	"Atsalis Island",
	"Bomos",
	"Thronos Castle",
	"Gori Outpost",
	"Magos Power Plant",
	"Ammo Storage Facility"
];

private _aoMarkersNE =
[
	"Sideras Outpost",
	"Pefkas Outpost",
	"Sofia Radar Station",
	"Research Facility",
	"Limni",
	"Paros",
	"Molos",
	"Delfinaki Outpost",
	"Nidasos Woodlands",
	"Sofia Powerplant",
	"Sofia",
	"Gatolia Solar Farm",
	"Molos Airfield",
	"Ghost Hotel",
	"Molos Airbase",
	"Almyra Airfield",
	"Kalochori",
	"Kalochori Solar Farm",
	"Rodopoli",
	"Kalithea",
	"Charkia",
	"Cap Thelos",
	"Thelos Bay",
	"Nifi"
];

private _aoMarkersCE =
[
	"Ifestiona",
	"Ifestiona Outpost",
	"Telos",
	"Anthrakia",
	"Zeloran Outpost",
	"Nychi",
	"Frini",
	"Agios Dionysios",
	"Frini Woodlands",
	"AAC Airfield",
	"Poliakko",
	"Therisa",
	"Katalaki",
	"Neochori",
	"Alikampos",
	"Lakka",
	"Lakka Outpost",
	"Orino",
	"Koroni",
	"Athira",
	"Tonos Bay",
	"Stavros",
	"Makrynisi Island",
	"Sagonisi Outpost",
	"South Harbor Power Plant",
	"Kalithea Bay"
];

_aoMarkers = [];
_fobMarkers = [];

switch (toLower worldName) do
{
	case "malden":
	{
		_aoMarkers = ["Moray Airfield", "Lolisse", "Malden Radio Station", "Larche", "Lavalle", "La Pessagne", "South Military Base", "Le Port", "Le Port Harbor", "La Trinite", "Arudy", "Military Ruins", "North Military Base", "Saint Jean", "Goisse", "Saint Louis", "Dourdan", "Houdan", "Chapoi", "Sainte Marie Farms", "Cancon", "La Riviere", "Faro", "Arette", "Corton Vinyard", "Dorres Valley"];
		_fobMarkers = ["FOB_N", "FOB_S"];
	};

	case "altis":
	{
		_aoMarkers append _aoMarkersSW;
		_aoMarkers append _aoMarkersSE;
		_aoMarkers append _aoMarkersCE;
		_aoMarkers append _aoMarkersNW;
		_aoMarkers append _aoMarkersNE;
		_fobMarkers = ["FOB_SW", "FOB_SE", "FOB_NW", "FOB_NE", "FOB_CE"];
	};
};

private _selectedOperations = [_aoMarkers] call AD_GetOperationList;

// Find closest FOB and start missions to it

private _averagePosition = [0,0,0];
{ _averagePosition = _averagePosition vectorAdd (getMarkerPos _x) } forEach _selectedOperations;
_averagePosition = _averagePosition vectorMultiply (1.0 / count _selectedOperations);

private _closestFOB = "";
private _closestFOBDistance = 1e30;
{
	private _fobDistance = (getMarkerPos _x) distance _averagePosition;
	if (_fobDistance < _closestFOBDistance) then
	{
		_closestFOB = _x;
		_closestFOBDistance = _fobDistance;
	};
} forEach _fobMarkers;

private _fobMarkers = [_closestFOB];

{
	_fobMarkers pushBack format ["%1_%2", _closestFOB, _x];
} forEach ["Hmv", "Hmv_1", "LZ", "Repair", "Medic", "Fuel", "Ammo", "APC", "Supp"];

_fobMarkers execVM "mission\fob\main.sqf";

// Start the main operations

{
	currentAO = _x;
	publicVariable "currentAO";

	//------------------------------------------ Edit and place markers for new target

	"aoCircle" setMarkerPos (getMarkerPos currentAO);
	"aoCircle" setMarkerSize [PARAMS_AOSize, PARAMS_AOSize];

	"aoMarker" setMarkerPos (getMarkerPos currentAO);
	"aoMarker" setMarkerText format["Take %1", currentAO];

	//------------------------------------------ Create AO detection trigger

	private _aafTrigger = createTrigger ["EmptyDetector", getMarkerPos currentAO];
	_aafTrigger setTriggerArea [PARAMS_AOSize, PARAMS_AOSize, 0, false];
	_aafTrigger setTriggerActivation ["GUER", "PRESENT", false];
	_aafTrigger setTriggerStatements ["this","",""];

	private _csatTrigger = createTrigger ["EmptyDetector", getMarkerPos currentAO];
	_csatTrigger setTriggerArea [PARAMS_AOSize, PARAMS_AOSize, 0, false];
	_csatTrigger setTriggerActivation ["EAST", "PRESENT", false];
	_csatTrigger setTriggerStatements ["this","",""];

	//------------------------------------------ Spawn enemies

	enemiesArray = [currentAO, _csatTrigger] call QS_fnc_AOenemy;
	publicVariable "enemiesArray";

	//------------------------------------------ Spawn radiotower

	radioTower = objNull;
	private _radioTowerMessage = "";
	private _mineField = [];

	if (count allPlayers >= PARAMS_PlayersNeededForAircraft) then
	{
		private _exactPosition = [];

		while { (count _exactPosition) < 1 } do
		{
			private _position = [[[getMarkerPos currentAO, PARAMS_AOSize], _aafTrigger], ["water","out"]] call BIS_fnc_randomPos;
			_exactPosition = _position isFlatEmpty[3, 1, 0.3, 30, 0, false];
		};

		private _roughPosition =
		[
			((_exactPosition select 0) - 200) + (random 400),
			((_exactPosition select 1) - 200) + (random 400),
			0
		];

		radioTower = "Land_TTowerBig_2_F" createVehicle _exactPosition;
		waitUntil { sleep 0.5; alive radioTower };
		radioTower setVectorUp [0,0,1];

		[[radioTower]] call SERVER_CurateEditableObjects;

		"radioMarker" setMarkerPos _roughPosition;
		"radioCircle" setMarkerPos _roughPosition;

		//-----------------------------------------------Spawn minefield

		if (random 10 > PARAMS_RadioTowerMineFieldChance) then
		{
			"radioMarker" setMarkerText "Radiotower";
		}
		else
		{
			_mineField = [_exactPosition] call QS_fnc_AOminefield;
			"radioMarker" setMarkerText "Radiotower (Minefield)";
		};

		_radioTowerMessage = "<br/><br/>Be advised that in order to stop them from calling in air support you must destroy the radio tower.";
	};

	publicVariable "radioTower";

	private _missionHint = format
	[
		"<t align='center' size='2.2'>Assault</t><br/><t size='1.5' align='center' color='#FFCF11'>%1</t><br/>____________________<br/>Intel shows that OPFOR has entrenched at %1.  Command has given us a green light to assault that area. Mobilize all available forces for an immediate attack.%2",
		currentAO, _radioTowerMessage
	];

	[_missionHint] remoteExec ["AW_fnc_globalHint",0,false];
	["NewMain", currentAO] remoteExec ["AW_fnc_globalNotification",0,false];

	if (not isNull radioTower) then
	{
		["NewSub", "Destroy the enemy radio tower."] remoteExec ["AW_fnc_globalNotification",0,false];
	};

	if (PARAMS_AOReinforcementJet == 1) then
	{
		[] spawn
			{
				sleep (30 + (random 180));

				while { (alive radioTower) } do
				{
					[] call QS_fnc_enemyCAS;
					[] call QS_fnc_enemyCAS;
					sleep (480 + (random 480));
				};
			};
	};

	// Get the lists off the aaf and csat detectors.  If this is attempted before the server has
	// started simulation, 'list' will return nil.  As I can't find a way to wait on the simulation
	// being started, the code waits until each 'list' returns a value.

	private _aafSoldiers = nil;
	private _csatSoldiers = nil;

	while { isNil "_aafSoldiers" || isNil "_csatSoldiers" } do
	{
		_aafSoldiers = list _aafTrigger;
		_csatSoldiers = list _csatTrigger;
	};

	private _threshhold = ((count _aafSoldiers) + (count _csatSoldiers)) * 0.1;

	// If created, wait for the radio tower to go down

	if (not isNull radioTower) then
	{
		waitUntil
		{
			sleep 3;

			not alive radioTower || (count _csatSoldiers + count _aafSoldiers) == 0
		};

		"radioMarker" setMarkerPos [-10000,-10000,-10000];
		"radioCircle" setMarkerPos [-10000,-10000,-10000];

		if (not alive radioTower) then
		{
			["CompletedSub", "Enemy radio tower destroyed."] remoteExec ["AW_fnc_globalNotification",0,false];
		}
		else
		{
			deleteVehicle radioTower;
		};
	};

	// Wait until a threshhold of surviving enemies has been reached

	waitUntil
		{
			sleep 3;

			(count _csatSoldiers) + (count _aafSoldiers) <= _threshhold;
		};

	private _cleanupCenter = getMarkerPos "aoCircle";
	private _cleanupRadius = ((getMarkerSize "aoCircle") select 0) * 1.5;

	"aoCircle" setMarkerPos [-10000,-10000,-10000];
	"aoMarker" setMarkerPos [-10000,-10000,-10000];

	"radioCircle" setMarkerPos [-10000,-10000,-10000];

	_missionHint = format ["<t align='center' size='2.2'>Assault Complete</t><br/><t size='1.5' align='center' color='#FFCF11'>%1</t><br/>____________________<br/><t align='left'>The allied assault on %1 is complete.  Headquarters staff sends a ""Well done"".</t>",currentAO];
	[_missionHint] remoteExec ["AW_fnc_globalHint",0,false];

	["CompletedMain", currentAO] remoteExec ["AW_fnc_globalNotification",0,false];

	// Clean up

	deleteVehicle _aafTrigger;
	deleteVehicle _csatTrigger;

	[enemiesArray] spawn QS_fnc_AOdelete;

	if (count _mineField > 0) then
	{
		[_mineField] spawn QS_fnc_AOdelete;
	};

	//------------------------------------------------- DEFEND AO

	if (SPM_CounterattackEnabled) then
	{
#ifdef TEST
		sleep 0;
#else
		sleep 10 + random 10;
#endif
		private _defendHint = format ["<t align='center' size='2.2'>Defend</t><br/><t size='1.5' align='center' color='#0d4e8f'>%1</t><br/>____________________<br/>Enemy forces are inbound, apparently intent on retaking the area.",	currentAO];
		[_defendHint] remoteExec ["AW_fnc_globalHint",0,false];

#ifdef TEST
		sleep 0;
#else
		sleep 10 + random 10;
#endif
		_defendHint = format ["<t size='1.5' align='center' color='#C92626'>Attack Imminent</t><br/><br/>____________________<br/>OPFOR has been spotted approaching %1. Prepare a defense.", currentAO];
		[_defendHint] remoteExec ["AW_fnc_globalHint",0,false];

#ifdef TEST
		sleep 0;
#else
		sleep 5 + random 5;
#endif
		["NewMainDefend", currentAO] remoteExec ["AW_fnc_globalNotification",0,false];

		defendAO = currentAO;
		publicVariable "defendAO";

		private _strongpoint = [getMarkerPos currentAO, PARAMS_AOSize - 300] call OO_CREATE(Counterattack);

		private _times = OO_GET(_strongpoint,Strongpoint,Times);
		private _duration = (15 * 60) + random (15 * 60);
		OO_SET(_times,StrongpointTimes,Duration,_duration);

		private _counterattackScript = [_strongpoint] spawn
			{
				params ["_strongpoint"];

				[] call OO_METHOD(_strongpoint,Strongpoint,Run);
			};

		private _counterattackStarted = false;
		while { not scriptDone _counterattackScript } do
		{
			if (OO_GET(_strongpoint,Strongpoint,RunState) == "running" && not _counterattackStarted) then
			{
				_counterattackStarted = true;

				"aoMarker_2" setMarkerPos OO_GET(_strongpoint,Strongpoint,Position);
				"aoMarker_2" setMarkerText "Defend area";
			};

			sleep 1;				
		};

		private _defendResult = OO_GET(_strongpoint,Strongpoint,RunState);

		call OO_DELETE(_strongpoint);

		defendAO = "";
		publicVariable "defendAO";

		switch (_defendResult) do
		{
			case "timeout":
			{
				private _hint = format ["<t align='center' size='2.2'>STALEMATE</t><br/><t size='1.5' align='center' color='#0d4e8f'>%1</t><br/>____________________<br/>Neither side has gained clear control of the area.", currentAO];
				[_hint] remoteExec ["AW_fnc_globalHint",0,false];
			};
			case "completed-success":
			{
				private _hint = format ["<t align='center' size='2.2'>VICTORY</t><br/><t size='1.5' align='center' color='#0d4e8f'>%1</t><br/>____________________<br/>Well done!  Friendly forces have wiped out the enemy assault.", currentAO];
				[_hint] remoteExec ["AW_fnc_globalHint",0,false];
			};
			case "completed-failure":
			{
				private _hint = format ["<t align='center' size='2.2'>DEFEAT</t><br/><t size='1.5' align='center' color='#0d4e8f'>%1</t><br/>____________________<br/>The enemy has taken the area.", currentAO];
				[_hint] remoteExec ["AW_fnc_globalHint",0,false];
			};
			case "command-terminated":
			{
				private _hint = format ["<t align='center' size='2.2'>NO VERDICT</t><br/><t size='1.5' align='center' color='#0d4e8f'>%1</t><br/>____________________<br/>The assault was ended prematurely by command.", currentAO];
				[_hint] remoteExec ["AW_fnc_globalHint",0,false];
			};
		};
	};

	"aoMarker_2" setMarkerPos [-10000,-10000,-10000];

	currentAO = "";
	publicVariable "currentAO";

	//----------------------------------------------------- MAINTENANCE

	private _aoClean = [_cleanupCenter, _cleanupRadius] execVM "scripts\misc\clearItemsAO.sqf";

	waitUntil { scriptDone _aoClean };

#ifdef TEST
		sleep 0;
#else
		sleep 30 + random 30;
#endif

} forEach _selectedOperations;

[] call compile preProcessFile "mission\fob\abandon.sqf";