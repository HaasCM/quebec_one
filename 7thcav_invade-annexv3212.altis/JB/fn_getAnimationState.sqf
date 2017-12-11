private _animationState = param [0, "", [""]];
private _key = param [1, "", [""]];

private _state = "";

switch (_key) do
{
	case "A": { _state = _animationState select [1, 3] };
	case "P": { _state = _animationState select [5, 3] };
	case "M": { _state = _animationState select [9, 3] };
	case "S": { _state = _animationState select [13, 3] };
	case "W": { _state = _animationState select [17, 3] };
	case "D": { _state = _animationState select [21, 3] };
};

_state;