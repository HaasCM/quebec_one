/*
| Author:
|
|	Quiksilver.
|_____
|
| Description:
|
|	Created: 26/11/2013.
|	Last modified: 13/10/2014.
|	Coded for I&A and hosted on allfps.com.au servers.
|	You may use and edit the code.
|	You may not remove any entries from Credits without first removing the relevant author's contributions,
|	or asking permission from the mission authors/contributors.
|	You may not remove the Credits tab, without consent of Ahoy World or allFPS.
| 	Feel free to re-format or make it look better.
|_____
|
| Usage:
|
|	Search below for the diary entries you would like to edit.
|	DiarySubjects appear in descending order when player map is open.
|	DiaryRecords appear in ascending order when selected.
|_____
|
| Credit:
|
|	Invade & Annex 2.00 was developed by Rarek [ahoyworld.co.uk] with hundreds of hours of work
|	The current version was developed by Quiksilver with hundreds more hours of work.
|
|	Contributors: Razgriz33 [AW], Jester [AW], Kamaradski [AW], David [AW], chucky [allFPS].
|
|	Please be respectful and do not remove credit.
|______________________________________________________________*/

if (!hasInterface) exitWith {};

waitUntil {!isNull player};

player createDiaryRecord ["diary", ["Special Operations",
"
Special operations consist of a series of missions executed by a small team.  That team has specific game slots in the server lobby, all beginning with 'SPECOPs'.
It is intended to be a self-contained unit, with its own pilot, medics, explosives experts, marksmen and so forth.  Missions are requested by the satellite phone
on the desk in the SPECOPs building.  Once requested, a series of missions will be provided to the team.  Failure on any mission will end the current series, requiring
the team to make another request.  Note that only SPECOPs members may request missions or complete the essential steps to a mission.  Note also that only SPECOPs
members receive notifications from Special Operations Command.
<br/>
<br/>
During missions that take place in cities and villages, the team may encounter enemy vehicles where the crew has dismounted in town before the SPECOPs team has arrived.
Those vehicles may be taken by the SPECOPs team and used by them.  If destroyed, they do not respawn.  If damaged, it might not be possible to repair them, depending on
the vehicle type.
<br/>
<br/>
SPECOPs members are subject to fatigue and weight limits.  At the same time, they are better marksmen than regular infantry.
<br/>
<br/>
Note that the RPG gunner may gun armored vehicles, and the explosives specialist may drive armored vehicles.  As with regular infantry, any team member may drive unarmored vehicles.
"
]];

player createDiaryRecord ["diary", ["Main Operation",
"
The main operation is divided into two phases, an initial assault and an enemy counterattack.  Regardless of phase, you can reach the main operation by using vehicles in the parking
lot on the northwest side of the headquarters building, by boarding player-flown transport helicopters, or by use of the HALO system, which is available by boarding the green
Huron helicopter at base, marked on the map.
<br/>
<br/>
Assault phase:
<br/>
<br/>
During the assault phase, the main operation is indicated by a red shaded circle on the map.  The primary objective is to seek and destroy the enemy, which is scattered around the marked
area on the map.  The enemy will have attack helicopters, armor and infantry.  The infantry will be both garrisoned in buildings as well as patrolling the area of operation (AO).  See
the Rules of Engagement tab for more information.
<br/>
<br/>
A secondary objective is to destroy the radio tower which is used by the enemy to call in their attack aircraft.
<br/>
<br/>
Once all enemies have been eliminated - or once the tower is destroyed and the vast majority of enemies have been eliminated - the assault phase of the operation will end.
Then the defensive phase will begin, with the enemy counterattacking.
<br/>
<br/>
Defensive phase:
<br/>
<br/>
Counterattacks will come both by land (armored transports) and by air (paradrops) and the encounter is timed to last between 15 and 30 minutes.  Simply put, the enemy will spawn
outside of the red circle and then attempt to enter and hold positions in the green circle, establishing a strongpoint.  It is the task of the players to prevent that from happening by maintaining numerical
superiority in that circle.  If the enemy esablishes 10:1 numerical superiority in that green circle, the encounter is declared a player defeat.  If the players hold off the attack,
it is considered a stalemate.  If all enemies are eliminated before the end of the timed period, the encounter is declared a player victory.
<br/>
<br/>
The enemy will commit only those forces that it believes that it needs to take back the area.  It will always send infantry in order to control the green target area, but it will
send armor only if players are operating armor in the area.  The same is true of combat air patrol aircraft.  If players are operating ground attack aircraft, the enemy will send in air defense units to protect their infantry assault.
"
]];

if (not (player diarySubjectExists "server")) then { player createDiarySubject ["server", "Server Information"]; };

player createDiaryRecord ["server", ["Unit callsigns",
"
<font face='EtelkaMonospacePro' size='10'>
<br/><font size='12'>Base Aircraft</font>
<br/>
<br/>CH-67 Huron                   Grizzly 1
<br/>Mi-290 Taru                   Grizzly 2 and 3
<br/>UH-80 Ghost Hawk (Black)      Buffalo 1
<br/>UH-80 Ghost Hawk (Camo)       Buffalo 2
<br/>UH-80 Ghost Hawk (Recon)      Recon 1
<br/>MH-9 Hummingbird (Black)      Sparrow 1
<br/>MH-9 Hummingbird (Camo)       Sparrow 2
<br/>AH-99 Blackfoot               Raider 1
<br/>A-164 Wipeout                 Eagle 1
<br/>V-44X Blackfish (Infantry)    Condor 1
<br/>V-44X Blackfish (Vehicle)     Condor 2
<br/>V-44X Blackfish (Armed)       Spectre
<br/>MQ-4A Greyhawk drone          Deathstar
<br/>MQ-12 Falcon drone            Falcon
<br/>
</font>
<br/>Additional aircraft acquire callsigns by type.  Attack aircraft are Eagles, attack helicopters are Raiders, etc.
<font face='EtelkaMonospacePro' size='10'>
<br/>
<br/><font size='12'>Base Armor</font>
<br/>
<br/>M2A1 Slammer                  Sabre 1 and 2
<br/>IFV-6a Cheetah                Flyswatter
<br/>Armored personnel carriers    Tincan
<br/>
</font>
<br/>Additional armored vehicles acquire callsigns by type.  Main battle tanks are Sabres, etc.
<font face='EtelkaMonospacePro' size='10'>
</font>
"
]];

player createDiaryRecord ["server", ["TeamSpeak information",
"
<br/> Address: ts3.7cav.us
<br/> Password: 7thCavalry
<br/> NOTE: Password is case sensitive
<br/>
<br/> Visitors and guests welcome!
"
]];

player createDiaryRecord ["server", ["Rules of conduct",
"
<br/>1. No fratricide.
<br/>2. No destruction of friendly equipment.
<br/>3. All pilots, UAV and artillery operators must be on TeamSpeak.
<br/>4. All aircraft / artillery support must be on call.
<br/>5. Weapons must be kept safed on base.
<br/>6. No foul language, racism, or insults of any type will be tolerated.
<br/>
<br/>If you see a player in violation of any of the above, contact a moderator or administrator (TeamSpeak).
"
]];

if (not (player diarySubjectExists "special operations")) then { player createDiarySubject ["special operations", "Special Operations"]; };

if (not (player diarySubjectExists "credits")) then { player createDiarySubject ["credits", "Credits"]; };

player createDiaryRecord ["credits", ["Invade & Annex",
"
<br/>Mission authors:<br/><br/>

- <font size='16'>Quiksilver</font> - All FPS (allfps.com.au)<br/><br/>
- <font size='16'>Rarek</font> - Ahoy World (ahoyworld.co.uk)<br/>

<br/>Contributors:<br/><br/>
- Jester - Ahoy World (ahoyworld.co.uk)<br/>
- Razgriz33 - Ahoy World (ahoyworld.co.uk)<br/>
- Kamaradski - Ahoy World (ahoyworld.co.uk)<br/>
- BACONMOP - Ahoy World (ahoyworld.co.uk)<br/>
- chucky - All FPS (allfps.com.au)<br/><br/>

<br/>Modified for the 7th Cavalry By:<br/><br/>
- <font size='16'>Treck</font> - 7th Cavalry (7thcavalry.us)		 <br/><br/>
- <font size='16'>Dakota</font> - 7th Cavalry (7thcavalry.us)		 <br/><br/>

<br/>Other:<br/><br/>
EOS<br/>
- BangaBob<br/><br/>
TAW View Distance<br/>
- Tonic<br/> <br/>
aw_fnc<br/>
- Alex Wise<br/><br/>
SHK Taskmaster<br/>
- Shuko<br/><br/>
Map and GPS Icons (Soldier Tracker)<br/>
- Quiksilver<br/><br/>
"
]];

player createDiaryRecord ["credits", ["Strongpoints",
"
<br/>
<align='center'>Design</font>
<br/>
<font font size='16' align='center'>Dakota (7th Cavalry)</font>
<br/>
<br/>
<font size='16'>Scripting:</font>
<br/>
<font font size='16' align='center'>JB></font>
"
]];