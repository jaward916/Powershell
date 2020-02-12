Function Get-SqlServerKeys {

    [CmdletBinding(DefaultParameterSetName = "Default")]

    Param(
        [parameter(Position = 0)]
        [string[]]$Servers,
        # Central Management Server
        [string]$CentralMgmtServer,
        # File with one server per line
        [string]$ServersFromFile
    )

    BEGIN {

        Function Unlock-SQLServerKey {

            param(

                [Parameter(Mandatory = $true)]

                [byte[]]$data,

                [int]$version

            )

            try {

                $Key = ($data)[0..66]

                if ($version -ge 11) { $Keyoffset = 0 } else { $Keyoffset = 52 }



                $isNKey = [int]($Key[14] / 6) -bAND 1

                $HF7 = 0xF7

                $Key[14] = ($Key[14] -bAND $HF7) -bOR (($isNKey -bAND 2) * 4)

                $i = 24

                [String]$Chars = "BCDFGHJKMPQRTVWXY2346789"



                do {

                    $Cur = 0

                    $X = 14

                    do {

                        $Cur = $Cur * 256

                        $Cur = $Key[$X + $Keyoffset] + $Cur

                        $Key[$X + $Keyoffset] = [math]::Floor([double]($Cur / 24))

                        $Cur = $Cur % 24

                        $X = $X - 1

                    } while ($X -ge 0)

                    $i = $i - 1

                    $KeyOutput = $Chars.SubString($Cur, 1) + $KeyOutput

                    $last = $Cur

                } while ($i -ge 0)



                $Keypart1 = $KeyOutput.SubString(1, $last)

                $Keypart2 = $KeyOutput.Substring(1, $KeyOutput.length - 1)



                if ($last -eq 0 ) {

                    $KeyOutput = "N" + $Keypart2

                }

                else {

                    $KeyOutput = $Keypart2.Insert($Keypart2.IndexOf($Keypart1) + $Keypart1.length, "N")

                }



                $a = $KeyOutput.Substring(0, 5)

                $b = $KeyOutput.substring(5, 5)

                $c = $KeyOutput.substring(10, 5)

                $d = $KeyOutput.substring(15, 5)

                $e = $KeyOutput.substring(20, 5)

                $keyproduct = $a + "-" + $b + "-" + $c + "-" + $d + "-" + $e

            }

            catch { $keyproduct = "Cannot decode product key." }

            return $keyproduct

        }
    }

    PROCESS {
        #if ((Get-Host).Version.Major -lt 3) { throw "PowerShell 3.0 and above required." }

        if ([Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") -eq $null )
        { throw "Quitting: SMO Required. You can download it from http://goo.gl/R4yA6u" }

        if ($CentralMgmtServer) {
            if ([Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.RegisteredServers") -eq $null )
            { throw "Can't load CMS assemblies. You must have SQL Server Management Studio installed to use the -CentralMgmtServer switch." }

            $server = New-Object Microsoft.SqlServer.Management.Smo.Server $CentralMgmtServer
            $sqlconnection = $server.ConnectionContext.SqlConnectionObject

            try { $cmstore = new-object Microsoft.SqlServer.Management.RegisteredServers.RegisteredServersStore($sqlconnection)}
            catch { throw "Cannot access Central Management Server" }
            $dbstore = $cmstore.DatabaseEngineServerGroup
            $servers = $dbstore.GetDescendantRegisteredServers().servername
            # Add the CM server itself, which can't be stored in the CM server.
            $servers += $CentralMgmtServer
            $basenames = @()
            foreach ($server in $servers) { $basenames += $server.Split("\")[0] }
            $servers = $basenames | Get-Unique
        }

        If ($ServersFromFile) {
            if ((Test-Path $ServersFromFile) -eq $false) { throw "Could not find file: $ServersFromFile" }
            $servers = Get-Content $ServersFromFile
        }

        if ([string]::IsNullOrEmpty($servers)) { $servers = $env:computername }

        $basepath = "SOFTWARE\Microsoft\Microsoft SQL Server"
        # Loop through each server
        $objectCollection = @()
        foreach ($servername in $servers) {
            $servername = $servername.Split("\")[0]

            if ($servername -eq "." -or $servername -eq "localhost" -or $servername -eq $env:computername) {
                $localmachine = [Microsoft.Win32.RegistryHive]::LocalMachine
                $defaultview = [Microsoft.Win32.RegistryView]::Default
                $reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey($localmachine, $defaultview)
            }
            else {
                # Get IP for remote registry access. It's the most reliable.
                try { $ipaddr = ([System.Net.Dns]::GetHostAddresses($servername)).IPAddressToString }
                catch { Write-Warning "Can't resolve $servername. Moving on."; continue }

                try {
                    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $ipaddr)
                }
                catch { Write-Warning "Can't access registry for $servername. Is the Remote Registry service started?"; continue }
            }

            $instances = $reg.OpenSubKey("$basepath\Instance Names\SQL", $false)
            if ($instances -eq $null) { Write-Warning "No instances found on $servername. Moving on."; continue }
            # Get Product Keys for all instances on the server.
            foreach ($instance in $instances.GetValueNames()) {
                if ($instance -eq "MSSQLSERVER") { $sqlserver = $servername } else { $sqlserver = "$servername\$instance" }

                $subkeys = $reg.OpenSubKey("$basepath", $false)
                $instancekey = $subkeys.GetSubKeynames() | Where-Object { $_ -like "*.$instance" }
                if ($instancekey -eq $null) { $instancekey = $instance } # SQL 2k5

                # Cluster instance hostnames are required for SMO connection
                $cluster = $reg.OpenSubKey("$basepath\$instancekey\Cluster", $false)
                if ($cluster -ne $null) {
                    $clustername = $cluster.GetValue("ClusterName")
                    if ($instance -eq "MSSQLSERVER") { $sqlserver = $clustername } else { $sqlserver = "$clustername\$instance" }
                }

                Write-Verbose "Attempting to connect to $sqlserver"
                $server = New-Object Microsoft.SqlServer.Management.Smo.Server $sqlserver
                try { $server.ConnectionContext.Connect() } catch { Write-Warning "Can't connect to $sqlserver or access denied. Moving on."; continue }
                $servicePack = $server.ProductLevel

                switch ($server.VersionMajor) {
                    9 {
                        $sqlversion = "SQL Server 2005 $servicePack"
                        $findkeys = $reg.OpenSubKey("$basepath\90\ProductID", $false)
                        foreach ($findkey in $findkeys.GetValueNames()) {
                            if ($findkey -like "DigitalProductID*") { $key = "$basepath\90\ProductID\$findkey"}
                        }
                    }
                    10 {
                        $sqlversion = "SQL Server 2008 $servicePack"
                        $key = "$basepath\MSSQL10"
                        if ($server.VersionMinor -eq 50) { $key += "_50"; $sqlversion = "SQL Server 2008 R2 $servicePack" }
                        $key += ".$instance\Setup\DigitalProductID"
                    }
                    11 { $key = "$basepath\110\Tools\Setup\DigitalProductID"; $sqlversion = "SQL Server 2012 $servicePack" }
                    12 { $key = "$basepath\120\Tools\Setup\DigitalProductID"; $sqlversion = "SQL Server 2014 $servicePack" }
                    13 { $key = "$basepath\130\Tools\ClientSetup\DigitalProductID"; $sqlversion = "SQL Server 2016 $servicePack" }
                    14 { $key = "$basepath\140\Tools\ClientSetup\DigitalProductID"; $sqlversion = "SQL Server 2017 $servicePack" }


                    default { Write-Warning "SQL version not currently supported."; continue }
                }
                if ($server.Edition -notlike "*Express*") {
                    try {
                        $subkey = Split-Path $key; $binaryvalue = Split-Path $key -leaf
                        $binarykey = $($reg.OpenSubKey($subkey)).GetValue($binaryvalue)
                    }
                    catch {$sqlkey = "Could not connect." }
                    $sqlkey = Unlock-SQLServerKey $binarykey $server.VersionMajor
                }
                else { $sqlkey = "SQL Server Express Edition"}
                $server.ConnectionContext.Disconnect()

                $object = New-Object PSObject -Property @{
                    "SQL Instance" = $sqlserver
                    "SQL Version"  = $sqlversion
                    "SQL Edition"  = $server.Edition
                    "Product Key"  = $sqlkey
                }
                $objectCollection += $object
            }
            $reg.Close()
        }
        $objectCollection | Select-Object "SQL Instance", "SQL Version", "SQL Edition", "Product Key"
    }

    END {
        #Write-Host "Script completed" -ForegroundColor Green
    }
}
$DesktopPath = [Environment]::GetFolderPath("Desktop")
Get-SqlServerKeys localhost | Out-File "$DesktopPath\SQLKeys.txt"