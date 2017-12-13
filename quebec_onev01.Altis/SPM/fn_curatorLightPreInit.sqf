/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not hasInterface) exitWith {};

SPM_CuratorLightOn = false;
SPM_CuratorLightLight = objNull;

SPM_CuratorLight =
{
	if (isNull SPM_CuratorLightLight) then
	{
		SPM_CuratorLightLight = "#lightpoint" createvehiclelocal [0,0,0];
		SPM_CuratorLightLight setLightDayLight true;
		SPM_CuratorLightLight setLightBrightness 0;
		SPM_CuratorLightLight setLightAmbient [0.0, 0.0, 0.0];
		SPM_CuratorLightLight setLightColor [1.0, 1.0, 1.0];
		SPM_CuratorLightLight setLightAttenuation [5000, 2, 1, 1];

		addMissionEventHandler ["EachFrame",
			{
				private _cameraPosition = getPos curatorCamera;

				if (SPM_CuratorLightOn && (_cameraPosition select 0) != 0) then
				{
					_cameraPosition set [2, 400];

					SPM_CuratorLightLight setLightBrightness 0.6;
					SPM_CuratorLightLight setPos _cameraPosition;
				}
				else
				{
					SPM_CuratorLightLight setLightBrightness 0;
				};
			}];
	};

	SPM_CuratorLightOn = not SPM_CuratorLightOn;
};

