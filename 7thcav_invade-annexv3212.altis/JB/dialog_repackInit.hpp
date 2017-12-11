class JBRM_RepackMagazines
{
	idd = 3000;
	movingEnable = false;
	moving = 1;
	onLoad = "";
	onUnload = "_this call JBRM_RepackUnload";

	class controlsBackground
	{
		class iBackground : RscText
		{
			idc = 1000;
			text = "";
			x = 0.19;
			y = 0.19;
			w = 0.62;
			h = 0.07;
			colorBackground[] = { 0, 0, 0, 0.7 };
		};
	};

	class controls
	{
		class iProgress : JB_RscProgress
		{
			idc = 2000;
			x = 0.20;
			y = 0.213;
			w = 0.60;
			h = 0.03;
			colorBar[] = { "(profilenamespace getvariable ['GUI_BCG_RGB_R',0.3843])", "(profilenamespace getvariable ['GUI_BCG_RGB_G',0.7019])", "(profilenamespace getvariable ['GUI_BCG_RGB_B',0.8862])", "(profilenamespace getvariable ['GUI_BCG_RGB_A',0.7])" };
			colorFrame[] = { "(profilenamespace getvariable ['GUI_BCG_RGB_R',0.3843])", "(profilenamespace getvariable ['GUI_BCG_RGB_G',0.7019])", "(profilenamespace getvariable ['GUI_BCG_RGB_B',0.8862])", "(profilenamespace getvariable ['GUI_BCG_RGB_A',0.7])" };
		};
	};
};