/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer) exitWith {};

#include "strongpoint.h"

SPM_MATCHED_COMMAND = 0;
SPM_NO_COMMAND = -1;
SPM_UNRECOGNIZED_COMMAND = -2;

SPM_MessageCaller =
{
	private _message = _this select 0;

	_message remoteExec ["systemchat", remoteExecutedOwner];
};

SPM_COMMAND_Sides = ["east", "opfor", "west", "blufor", "independent", "guerilla"];

SPM_COMMAND__CounterattackDisable =
{
	if (not SPM_CounterattackEnabled) then
	{
		["Strongpoint counterattacks are already disabled"] call SPM_MessageCaller;
	}
	else
	{
		SPM_CounterattackEnabled = false;

		["Strongpoint counterattacks have been disabled"] call SPM_MessageCaller;
	};

	SPM_MATCHED_COMMAND
};

SPM_COMMAND__CounterattackEnable =
{
	if (SPM_CounterattackEnabled) then
	{
		["Strongpoint counterattacks are already enabled"] call SPM_MessageCaller;
	}
	else
	{
		SPM_CounterattackEnabled = true;

		["Strongpoint counterattacks have been enabled"] call SPM_MessageCaller;
	};

	SPM_MATCHED_COMMAND
};

SPM_COMMAND__CounterattackStop =
{
	private _strongpoint = ["MainOperation-Counterattack"] call SPM_Strongpoint_FindByName;

	if (count _strongpoint == 0) then
	{
		["No strongpoint counterattack is active."] call SPM_MessageCaller;
	}
	else
	{
		if (OO_GET(_strongpoint,Strongpoint,RunState) == "command-terminated") then
		{
			["The counterattack has already been commanded to stop."] call SPM_MessageCaller;
		}
		else
		{
			["Stopping counterattack..."] call SPM_MessageCaller;

			OO_SET(_strongpoint,Strongpoint,RunState,"command-terminated");
		};
	};

	SPM_MATCHED_COMMAND
};

SPM_COMMAND__CounterattackKill =
{
	private _strongpoint = ["MainOperation-Counterattack"] call SPM_Strongpoint_FindByName;
	if (count _strongpoint == 0) then
	{
		["No strongpoint counterattack is active."] call SPM_MessageCaller;
	}
	else
	{
		call OO_DELETE(_strongpoint);
	};

	SPM_MATCHED_COMMAND
};

SPM_COMMAND__CounterattackSetDifficulty =
{
	private _commandWords = _this select 0;

	private _validCategory = false;
	private _validDifficulty = false;

	if (count _commandWords == 3) then
	{
		private _difficulty = parseNumber (_commandWords select 2);
		if (_difficulty >= 1 && _difficulty <= 10) then
		{
			_validDifficulty = true;

			private _categoryName = toLower (_commandWords select 1);

			if (_categoryName == "all") then
			{
				_validCategory = true;
				{
					_x set [1, _difficulty];
				} forEach SPM_StrongpointDifficulty;
			}
			else
			{
				private _categoryIndex = [SPM_StrongpointDifficulty, _categoryName] call BIS_fnc_findInPairs;

				if (_categoryIndex >= 0) then
				{
					_validCategory = true;
					(SPM_StrongpointDifficulty select _categoryIndex) set [1, _difficulty];
				};
			};

			if (_validCategory) then
			{
				[["difficulty"]] call SPM_COMMAND__CounterattackShowDifficulty;
			};
		};
	};

	if (not _validCategory) then
	{
		private _categoryNames = "";
		{
			_categoryNames = _categoryNames + ", '" + (_x select 0) + "'";
		} forEach SPM_StrongpointDifficulty;
		_categoryNames = _categoryNames select [2];

		[format ["Specify a combat category name (one of %1 or 'all')", _categoryNames]] call SPM_MessageCaller;
	}
	else
	{
		if (not _validDifficulty) then
		{
			["Specify a difficulty value between 1 (easiest) and 10 (most difficult)."] call SPM_MessageCaller;
		};
	};

	SPM_MATCHED_COMMAND
};

SPM_COMMAND__CounterattackSet =
{
	private _commandWords = _this select 0;

	private _commands =
	[
		["difficulty", SPM_COMMAND__CounterattackSetDifficulty]
	];

	private _match = [_commandWords select [1, count _commandWords - 1], _commands] call SPM_COMMAND_Match;

	if (_match select 0 < 0) exitWith
	{
		[format ["Unexpected: %1", _commandWords select [1, count _commandWords - 1]]] call SPM_MessageCaller;
		_match select 0
	};

	private _command = _match select 1;

	[[_command select 0] + (_commandWords select [2, count _commandWords - 2])] call (_command select 1);
};

SPM_COMMAND__CounterattackShowDifficulty =
{
	private _commandWords = _this select 0;

	if (count _commandWords == 1) then
	{
		private _difficulty = "";
		{
			_difficulty = format ["%1%2:%3  ", _difficulty, _x select 0, _x select 1];
		} forEach SPM_StrongpointDifficulty;

		[format ["Strongpoint counterattack difficulty levels: %1", _difficulty]] call SPM_MessageCaller;
	};

	SPM_MATCHED_COMMAND
};

SPM_COMMAND__CounterattackShow =
{
	private _commandWords = _this select 0;

	private _commands =
	[
		["difficulty", SPM_COMMAND__CounterattackShowDifficulty]
	];

	private _match = [_commandWords select [1, count _commandWords - 1], _commands] call SPM_COMMAND_Match;

	if (_match select 0 < 0) exitWith
	{
		[format ["Unexpected: %1", _commandWords select [1, count _commandWords - 1]]] call SPM_MessageCaller;
		_match select 0
	};

	private _command = _match select 1;

	[[_command select 0] + (_commandWords select [2, count _commandWords - 2])] call (_command select 1);
};

SPM_COMMAND__Counterattack =
{
	private _commandWords = _this select 0;

	private _commands =
	[
		["disable", SPM_COMMAND__CounterattackDisable],
		["enable", SPM_COMMAND__CounterattackEnable],
		["stop", SPM_COMMAND__CounterattackStop],
		["kill", SPM_COMMAND__CounterattackKill],
		["set", SPM_COMMAND__CounterattackSet],
		["show", SPM_COMMAND__CounterattackShow]
	];

	private _match = [_commandWords select [1, count _commandWords - 1], _commands] call SPM_COMMAND_Match;

	if (_match select 0 < 0) exitWith
	{
		[format ["Unexpected: %1", _commandWords select [1, count _commandWords - 1]]] call SPM_MessageCaller;
		_match select 0
	};

	private _command = _match select 1;

	[[_command select 0] + (_commandWords select [2, count _commandWords - 2])] call (_command select 1);
};

SPM_COMMAND__SpecialOperationsDisable =
{
	if (not SPM_SpecialOperationsEnabled) then
	{
		["Strongpoint special operations are already disabled"] call SPM_MessageCaller;
	}
	else
	{
		SPM_SpecialOperationsEnabled = false;

		["Strongpoint special operations have been disabled"] call SPM_MessageCaller;
	};

	SPM_MATCHED_COMMAND
};

SPM_COMMAND__SpecialOperationsEnable =
{
	if (SPM_SpecialOperationsEnabled) then
	{
		["Strongpoint special operations are already enabled"] call SPM_MessageCaller;
	}
	else
	{
		SPM_SpecialOperationsEnabled = true;

		["Strongpoint special operations have been enabled"] call SPM_MessageCaller;
	};

	SPM_MATCHED_COMMAND
};

SPM_COMMAND__SpecialOperationStop =
{
	private _strongpoint = ["SpecialOperation"] call SPM_Strongpoint_FindByName;

	if (count _strongpoint == 0) then
	{
		["No strongpoint special operation is active."] call SPM_MessageCaller;
	}
	else
	{
		if (OO_GET(_strongpoint,Strongpoint,RunState) == "command-terminated") then
		{
			["The special operation has already been commanded to stop."] call SPM_MessageCaller;
		}
		else
		{
			["Stopping special operation..."] call SPM_MessageCaller;

			OO_SET(_strongpoint,Strongpoint,RunState,"command-terminated");
		};
	};

	SPM_MATCHED_COMMAND
};

SPM_COMMAND__SpecialOperationKill =
{
	private _strongpoint = ["SpecialOperation"] call SPM_Strongpoint_FindByName;
	if (count _strongpoint == 0) then
	{
		["No strongpoint special operation is active."] call SPM_MessageCaller;
	}
	else
	{
		call OO_DELETE(_strongpoint);
	};

	SPM_MATCHED_COMMAND
};

SPM_COMMAND__SpecialOperation =
{
	private _commandWords = _this select 0;

	private _commands =
	[
		["disable", SPM_COMMAND__SpecialOperationsDisable],
		["enable", SPM_COMMAND__SpecialOperationsEnable],
		["stop", SPM_COMMAND__SpecialOperationStop],
		["kill", SPM_COMMAND__SpecialOperationKill]
	];

	private _match = [_commandWords select [1, count _commandWords - 1], _commands] call SPM_COMMAND_Match;

	if (_match select 0 < 0) exitWith
	{
		[format ["Unexpected: %1", _commandWords select [1, count _commandWords - 1]]] call SPM_MessageCaller;
		_match select 0
	};

	private _command = _match select 1;

	[[_command select 0] + (_commandWords select [2, count _commandWords - 2])] call (_command select 1);
};

SPM_COMMAND_Match =
{
	private _commandWords = _this select 0;
	private _commands = _this select 1;

	if (count _commandWords == 0) exitWith
	{
		[SPM_NO_COMMAND]
	};

	private _command = [];

	private _executeWord = toLower (_commandWords select 0);
	private _executeWordLength = count _executeWord;
	{
		private _commandWord = _x select 0;

		if (_commandWord == _executeWord) exitWith
		{
			_command = _x;
		};

		private _partialMatch = (_commandWord find _executeWord == 0);

		if (_partialMatch && count _command > 0) exitWith
		{
			_command = [];
		};

		if (_partialMatch) then
		{
			_command = _x;
		};
	} forEach _commands;

	if (count _command == 0) exitWith
	{
		[SPM_UNRECOGNIZED_COMMAND]
	};

	[SPM_MATCHED_COMMAND, _command]
};

SPM_COMMAND_SecurityCheck = { true };

SPM_ExecuteCommand =
{
	private _commandString = _this select 0;

	private _commandWords = _commandString splitString " ";

	private _commands =
	[
		["counterattack", SPM_COMMAND__Counterattack],
		["specops", SPM_COMMAND__SpecialOperation]
	];

	private _match = [_commandWords, _commands] call SPM_COMMAND_Match;

	if (_match select 0 < 0) exitWith
	{
		[format ["Unexpected: %1", _commandWords select [1, count _commandWords - 1]]] call SPM_MessageCaller;
		_match select 0
	};

	private _command = _match select 1;

	if (not ([_command] call SPM_COMMAND_SecurityCheck)) then
	{
		[format ["Insufficient rights: %1", _command select 0]] call SPM_MessageCaller;
	}
	else
	{
		private _result = [[_command select 0] + (_commandWords select [1, count _commandWords - 1])] call (_command select 1);

		if (_result != SPM_MATCHED_COMMAND) then
		{
			diag_log format ["SPM_ExecuteCommand: unmatched command %1", _result];
		};
	};
};