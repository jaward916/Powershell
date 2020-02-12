#DISM Cleanup Script for Windows Servers on Boot
dism /online /cleanup-image /checkhealth
dism /online /cleanup-image /startcomponentcleanup
dism /online /cleanup-image /startcomponentcleanup /resetbase
dism /online /cleanup-image /spsuperseeded
