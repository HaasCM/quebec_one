// Icon to use to indicate incapacitated soldiers in the 3D view
#define MEDICAL_ICON "a3\ui_f\data\map\MapControl\hospital_ca.paa"
// Distance medics will be able to see incapacitated soldiers in the 3D view
#define MEDIC_VISION_RANGE 500

[] call JBM_SetupActions;
player addEventHandler ["HandleDamage", JBM_HandleDamage];
player addEventHandler ["Respawn", JBM_Respawned];
player addEventHandler ["Killed", JBM_Killed];

JBM_CS_Medical = call JB_fnc_criticalSectionCreate;

if (!(player getUnitTrait "medic")) then
{
	addMissionEventHandler ["Draw3D", { JBM_FrameNumber = JBM_FrameNumber + 1 }];
}
else
{
	addMissionEventHandler ["Draw3D",
		{
			JBM_FrameNumber = JBM_FrameNumber + 1;

			{
				if (_x != player && { lifeState _x == "INCAPACITATED" }) then
				{
					private _distance = round (player distance _x);
					if (_distance < MEDIC_VISION_RANGE) then
					{
						private _color = [1.0, 0.0, 0.0, (0.1 + (1.0 - _distance / MEDIC_VISION_RANGE)) min 1.0];

						private _position = getPosVisual _x;
						_position set [2, (getPosATL _x) select 2];

						private _label = format["%1  %2m", name _x, _distance];

						drawIcon3D [MEDICAL_ICON, _color, _position, 0.5, 0.5, 0, _label, 0, 0.03];
					};
				};
			} foreach allPlayers;
		}];
};