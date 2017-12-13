#include "..\OO\oo.h"

SPM_CHANGES_RETIRE = 0;
SPM_CHANGES_REINSTATE = 1;
SPM_CHANGES_CALLUP = 2;
SPM_CHANGES_RESERVES = 3;
#define CHANGES(array, item) ((array) select SPM_CHANGES_##item)