if (hasInterface) then
{
	private _description = switch (typeOf FOB_MissionTruck) do
	{
		case "B_Truck_01_fuel_F": { ["fuel", "Fuel"] };
		case "B_Truck_01_medical_F": { ["medical supplies", "Medical Supplies"] };
		case "B_Truck_01_ammo_F": { ["munitions", "Munitions"] };
		case "B_Truck_01_Repair_F": { ["spare parts", "Spare Parts"] };
		case "B_Truck_01_box_F": { ["basic supplies", "Basic Supplies"] };
		default { ["stuff", "Stuff"] };
	};

	hint parseText format ["<t align='center'><t size='2.2'>Supply Mission</t><br/><t size='1.5' color='#00B2EE'>%2</t><br/>____________________<br/>This HEMTT contains the %1 for Forward Operating Base Vigilance.  Drive it to the FOB and beware of ambushes as OPFOR is looking for this truck.</t>", _description select 0, _description select 1];
};
