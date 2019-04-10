# Please run this tool to install Server Prerequisites for Server 2016
# Always Run As Administrator
###
#The below will install all required Roles and Features, this may require a reboot
Install-WindowsFeature FileAndStorage-Services,File-Services,FS-FileServer,FS-DFS-Replication,Storage-Services,Web-Server,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Static-Content,Web-Health,Web-Http-Logging,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Basic-Auth,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-AppInit,Web-Asp-Net,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Web-Lgcy-Scripting,Web-WMI,Web-Scripting-Tools,NET-Framework-Features,NET-Framework-Core,NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-Framework-45-Features,NET-Framework-45-Core,NET-Framework-45-ASPNET,NET-WCF-Services45,NET-WCF-HTTP-Activation45,NET-WCF-TCP-Activation45,NET-WCF-TCP-PortSharing45,RSAT,RSAT-Role-Tools,RSAT-File-Services,RSAT-DFS-Mgmt-Con,FS-SMB1,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Search-Service,WoW64-Support
###
#this will set Windows Search service to start automatically, required for Epicor Help
Set-Service -Name "WSearch" -StartupType "Auto"