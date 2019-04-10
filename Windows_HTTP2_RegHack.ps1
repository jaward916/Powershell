#This script disables HTTP2 on Windows 2016 servers which can cause issues with authentication over the "Windows" IIS Authentication binding on some applications
$registryPath = "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\HTTP\Parameters"

$nameEnableHttp2Tls = "EnableHttp2Tls"
$typeEnableHttp2Tls = "REG_DWORD"
$valueEnableHttp2Tls = "0"

$nameEnableHttp2Cleartext = "EnableHttp2Cleartext"
$typeEnableHttp2Cleartext = "REG_DWORD"
$valueEnableHttp2Cleartext = "0"

If (!(Test-Path $registryPath)) {
    New-ItemProperty -Path $registryPath -Name $nameEnableHttp2Tls -Value $valueEnableHttp2Tls -PropertyType $typeEnableHttp2Tls
    New-ItemProperty -Path $registryPath -Name $nameEnableHttp2Cleartext -Value $valueEnableHttp2Cleartext -PropertyType $typeEnableHttp2Cleartext
}
else {
    Set-ItemProperty -Path $registryPath -Name $nameEnableHttp2Tls -Value $valueEnableHttp2Tls -PropertyType $typeEnableHttp2Tls
    Set-ItemProperty -Path $registryPath -Name $nameEnableHttp2Cleartext -Value $valueEnableHttp2Cleartext -PropertyType $typeEnableHttp2Cleartext
}