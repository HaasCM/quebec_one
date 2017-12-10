private _headquartersArea = triggerArea headquarters;
([getPos headquarters] + _headquartersArea) remoteExec ["SERVER_DeleteWeaponHolders", 2];