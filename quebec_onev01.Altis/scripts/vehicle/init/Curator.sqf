if (isServer) then
{
	private _curator = _this select 0;

	if (isNull SERVER_CuratorMaster) then
	{
		SERVER_CuratorMaster = _curator;
	};

	[_curator, [-1, -2, 0]] call BIS_fnc_setCuratorVisionModes;
};