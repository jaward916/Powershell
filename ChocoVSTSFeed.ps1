<#
This script will automatically elevate as admin, check to see if chcolatey is installed, 
if not it will install, if it is then it will just upgrade (i.e. only downloads choco install script if not in place to save time & effort)
after that it will download the latest version of your vsts packaged "app" from your VSTS feed
This is based on the fact you have packaged your app with a "nuget pack" and "nuget push" to feed, there are plenty of MS and othe rtutorials out there for this
You will need:
-A VSTS personal Access Token setup with at least Package Read rights
-A VSTS Package Feed which you get if you enable/purchase the Pakaging tools in VSTS
-A build definition with nuget pack and push commands based on a .nuspec file in your code
#>

#Assign Variables from your VSTS account
$myNugetPkg = "myPackage" # Get the Package name from VSTS feed
$myVSTSFeed = "https://mysite.pkgs.visualstudio.com/_packaging/FeedName/nuget/v2" #v2 feed address for nuget packages in vsts, replace MySite and FeedName
$vstsUser = "myUser" # this shouldn't matter if using PAT
$myPAT = "abcdef1234567890xyzagfs" # the PAT from vsts with Read Package authorisation
#Elevate if not running as admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

#Check if Choco installed, if not get latest, if it does upgrade to latest
$chocopath = 'C:\programdata\chocolatey\lib'
$ChocoExists = $null
While ($ChocoExists -ne 'Y') {
    If (!(test-path $chocopath)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        $ChocoExists = 'N'
    }
    else {
        choco upgrade chocolatey
        $ChocoExists = 'Y'
    }
}

#Get Latest Install Tool from VSTS Feed
choco upgrade $myNugetPkg -s $myVSTSFeed -u $vstsUser -p $myPAT -Force