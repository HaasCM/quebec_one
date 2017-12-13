EOS_Spawn = compile preprocessfilelinenumbers "scripts\eos\core\eos_launch.sqf";null=[] execVM "scripts\eos\core\spawn_fnc.sqf";onplayerConnected {[] execVM "scripts\eos\Functions\EOS_Markers.sqf";};
/* 
EOS 1.98 by BangaBob 

GROUP SIZES
 0 = 1
 1 = 2,4
 2 = 4,8
 3 = 8,12
 4 = 12,16
 5 = 16,20

EXAMPLE CALL - EOS
 null = [["MARKERNAME","MARKERNAME2"],[2,1,70],[0,1],[1,2,30],[2,60],[2],[1,0,10],[1,0,250,WEST]] call EOS_Spawn;
 null=[["M1","M2","M3"],[HOUSE GROUPS,SIZE OF GROUPS,PROBABILITY],[PATROL GROUPS,SIZE OF GROUPS,PROBABILITY],[LIGHT VEHICLES,SIZE OF CARGO,PROBABILITY],[ARMOURED VEHICLES,PROBABILITY], [STATIC VEHICLES,PROBABILITY],[HELICOPTERS,SIZE OF HELICOPTER CARGO,PROBABILITY],[FACTION,MARKERTYPE,DISTANCE,SIDE,HEIGHTLIMIT,DEBUG]] call EOS_Spawn;
*/

VictoryColor="colorGreen";	// Colour of marker after completion
HostileColor="colorRed";	// Default colour when enemies active
DefendColor="colorOrange";	// Colour for bastion marker
StopColor="colorBlack";		// Color to stop running
EOS_DAMAGE_MULTIPLIER=1;	// 1 is default
EOS_KILLCOUNTER=false;		// Counts killed units