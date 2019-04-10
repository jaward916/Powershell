#This Script increases the TCP parameters in Windows to their maximum to allow multiple connections for multiple applications
#Prime use for this used to be when Epicor ERP and MS SharePoint were installed on the same server
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "MaxUserPort" /t REG_DWORD /d 65536 /f
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpTimedWaitDelay" /t REG_DWORD /d 30 /f