#original script written by dotps1 at https://github.com/dotps1/PSFunctions
#added extra check to validate local machine credentials if domain part matches current hostname or a dot e.g. .\admin
 Function Test-Credential {
    [OutputType([Bool])]
    
    Param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias(
            'PSCredential'
        )]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [String]
        $Domain = $Credential.GetNetworkCredential().Domain
    )

    Begin {
        [System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.AccountManagement") |
            Out-Null
        if ($Domain -ne $env:COMPUTERNAME -or $Domain -ne ".") {
        $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
            [System.DirectoryServices.AccountManagement.ContextType]::Domain, $Domain
        )
        }
        Else{
        $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
            [System.DirectoryServices.AccountManagement.ContextType]::machine, $env:COMPUTERNAME
         )
        }
    }

    Process {
        foreach ($item in $Credential) {
            $networkCredential = $Credential.GetNetworkCredential()
            
            Write-Output -InputObject $(
                $principalContext.ValidateCredentials(
                    $networkCredential.UserName, $networkCredential.Password
                )
            )
        }
    }

    End {
        $principalContext.Dispose()
    }
}
$cred = get-credential
test-credential($cred)
#write-host $cred.UserName
#write-host $cred.Password
#write-host $cred.GetNetworkCredential().Domain