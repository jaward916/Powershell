<#PSScriptInfo 
.DESCRIPTION 
    Simulates an Authentication Request in a Domain envrionment using a PSCredential Object. Returns $true if both Username and Password pair are valid. 
.VERSION 
    1.3
.GUID 
    6a18515f-73d3-4fb4-884f-412395aa5054 
.AUTHOR 
    Thomas Malkewitz @dotps1 
.TAGS 
    PSCredential, Credential
.RELEASENOTES 
    Updated $Domain default value to $Credential.GetNetworkCredential().Domain.
    Added support for multipul credential objects to be passed into $Credential.
.PROJECTURI
    http://dotps1.github.io
 #>
 #JAW EDIT - Added in test local if "domain" is equal to computername environment variable 09/05/2018

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
        if ($Domain -ne $env:COMPUTERNAME) {
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