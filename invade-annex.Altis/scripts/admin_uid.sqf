// admin_uid.sqf
waitUntil {(getPlayerUID player) != ""};

_uid = getPlayerUID player;

switch(_uid)do 
{  
	case "76561198084065754": // Quiksilver
 	{
		player addAction ["<t color='#900000'>Spectate</t>", "scripts\spectator\specta.sqf",[],-99,false,false,"",''];
 	};
	
 	case "76561198075731453": // allFPS texaschainsaw01
 	{
		player addAction ["<t color='#900000'>Spectate</t>", "scripts\spectator\specta.sqf",[],-99,false,false,"",''];
 	};
    
	case "76561197984885481": // allFPS BananaMan62
 	{
		player addAction ["<t color='#900000'>Spectate</t>", "scripts\spectator\specta.sqf",[],-99,false,false,"",''];
 	};
	
	case "76561198027844423": // allFPS chucky
 	{
		player addAction ["<t color='#900000'>Spectate</t>", "scripts\spectator\specta.sqf",[],-99,false,false,"",''];
 	};
	
	case "76561197982847025": // allFPS SNAFU
	{
		player addAction ["<t color='#900000'>Spectate</t>", "scripts\spectator\specta.sqf",[],-99,false,false,"",''];
	};
	
	case "76561197968938828": // allFPS Salty
	{
		player addAction ["<t color='#900000'>Spectate</t>", "scripts\spectator\specta.sqf",[],-99,false,false,"",''];
	};
	
	case "76561198088441620": // allFPS Marquez
	{
		player addAction ["<t color='#900000'>Spectate</t>", "scripts\spectator\specta.sqf",[],-99,false,false,"",''];
	};
	
	case "76561197970842179": // allFPS Deejai
	{
		player addAction ["<t color='#900000'>Spectate</t>", "scripts\spectator\specta.sqf",[],-99,false,false,"",''];
	};
	
	case "76561198041490053": // Reapre
	{
		player addAction ["<t color='#900000'>Spectate</t>", "scripts\spectator\specta.sqf",[],-99,false,false,"",''];
	};
	
 	default
     	{
 	};
};