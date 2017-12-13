BILLBOARD_ShowRules =
{
	[0.9, 0.4, parseText loadFile "media\text\billboard-rules.txt"] call Billboard_ShowMessage;
};

(_this select 0) setObjectTextureGlobal [0, "media\images\7cavflag.jpg"];
(_this select 0) addAction ["Rules of Conduct", BILLBOARD_ShowRules, nil, 10, true, true];