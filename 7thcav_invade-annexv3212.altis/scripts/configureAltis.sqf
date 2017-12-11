// Base trash
{
	((_x select 0) nearestObject (_x select 1)) hideObject true;
} forEach
[
	[[14580,16744,0], 458739],
	[[14576,16745,0], 458738],
	[[14576,16749,0], 458740],
	[[14572,16752,0], 458712],
	[[14488,16730,0], 523233],
	[[14489,16723,0], 523211],
	[[14484,16729,0], 523216],
	[[14485,16731,0], 523224],
	[[14487,16723,0], 523229],
	[[14484,16725,1], 523225],
	[[14483,16725,0], 523235],
	[[14483,16732,1], 523222],
	[[14482,16730,0], 523237],
	[[14481,16729,0], 523202],
	[[14483,16721,1], 523218],
	[[14484,16719,1], 523219],
	[[14487,16720,1], 523197],
	[[14481,16720,0], 523200],
	[[14482,16718,2], 523195],
	[[14485,16717,0], 523231],
	[[14484,16715,0], 523245],
	[[14481,16716,0], 523210],
	[[14488,16715,1], 523248],
	[[14483,16711,0], 523204],
	[[14493,16710,1], 523221],
	[[14494,16712,0], 523228],
	[[14493,16714,0], 523212],
	[[14488,16704,1], 523199],
	[[14491,16709,0], 523236],
	[[14496,16699,0], 523205],
	[[14493,16702,0], 523203],
	[[14478,16693,2], 523196],
	[[14481,16690,1], 523220],
	[[14480,16688,0], 523201],
	[[14483,16688,0], 523223],
	[[14480,16685,0], 523213],
	[[14482,16685,0], 523198],
	[[14486,16687,0], 523230],
	[[14486,16686,0], 523234],
	[[14488,16685,0], 523215],
	[[14487,16683,1], 523226],
	[[14486,16681,0], 523350],
	[[14490,16684,1], 523247],
	[[14486,16680,0], 523349],
	[[14486,16679,1], 523327],
	[[14489,16678,1], 523326],
	[[14490,16676,1], 523328],
	[[14493,16680,0], 523330],
	[[14493,16677,1], 523332],
	[[14495,16679,0], 523331],
	[[14496,16677,1], 523329],
	[[14501,16682,0], 523206],
	[[14484,16683,0], 523214],
	[[14476,16719,0], 523208],
	[[14487,16735,0], 523217],
	[[14496,16741,2], 458692]
];

// Bushes sticking up through heavy lift pad
{
	((_x select 0) nearestObject (_x select 1)) hideObject true;
} forEach
[
[[14471,16761,2], 458691],
[[14469,16764,2], 458685],
[[14469,16763,2], 458683],
[[14495,16744,2], 458693],
[[14500,16744,2], 458700],
[[14443,16727,1], 523093],
[[14418,16749,2], 458471],
[[14416,16748,1], 458458]
];

// Base duplicate light poles
{
	((_x select 0) nearestObject (_x select 1)) hideObject true;
} forEach
[
	[[14637,16889,0], 493647],
	[[14639,16887,0], 493682],
	[[14639,16887,0], 493666],
	[[14585,16917,0], 458175],
	[[14564,16918,-3], 458184],
	[[14518,16871,-3], 458242],
	[[14473,16823,-3], 458557],
	[[14499,16769,0], 458690],
	[[14533,16767,0], 458741],
	[[14559,16829,-3], 458622],
	[[14677,16777,0], 493984],
	[[14616,16714,0], 529331]
];

// Temporary hangar in fixed wing area

([15059,17157,0] nearestObject 493386) hideObject true;

// Building and trash bin for repair yard
{
	((_x select 0) nearestObject (_x select 1)) hideObject true;
} forEach
[
	[[14713,16922,1], 493622],
	[[14712,16913,0], 493601]
];

// Radar domes at base
{
	((_x select 0) nearestObject (_x select 1)) hideObject true;
} forEach
[
	[[14320,16190,0], 526035],
	[[15265,17087,0], 494129]
];

// Obstructions on SpecOps road
{
	((_x select 0) nearestObject (_x select 1)) hideObject true;
} forEach
[
	[[15143,17379,7], 490837],
	[[15143,17381,2], 490849],
	[[15136,17374,2], 490847],
	[[15135,17374,2], 490848],
	[[15135,17373,5], 490872],
	[[15112,17410,1], 490244],
	[[15109,17409,2], 490241],
	[[15085,17441,0], 490155],
	[[15092,17448,0], 490154],
	[[15078,17434,0], 490156],
	[[15067,17447,5], 490170],
	[[15070,17449,2], 490165],
	[[15066,17450,2], 490163],
	[[15068,17451,2], 490111],
	[[15063,17449,1], 490152],
	[[15062,17445,5], 490169],
	[[15060,17446,2], 490166],
	[[15060,17450,2], 490164],
	[[15057,17451,2], 56457],
	[[15056,17450,2], 56461],
	[[15056,17453,2], 56458]
];

// Main HQ double doors
{
	_x animate ["door_7a_move", 1];
	_x animate ["door_7b_move", 1];
	_x animate ["door_8a_move", 1];
	_x animate ["door_8b_move", 1];
} forEach [[14600, 16800, 0] nearestobject 458754, [14600, 16800, 0] nearestobject 493920];

// SpecOps HQ exit door
{
	_x animateSource ["door_2_sound_source", 1];
} forEach [[15210,17330,0] nearestobject 490995];