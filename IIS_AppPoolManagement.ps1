#recycle started app pools
& $env:windir\system32\inetsrv\appcmd list apppools /state:Started /xml | & $env:windir\system32\inetsrv\appcmd recycle apppools /in
#start stopped app pools
& $env:windir\system32\inetsrv\appcmd list apppools /state:Stopped /xml | & $env:windir\system32\inetsrv\appcmd start apppools /in
#stop started app pools
& $env:windir\system32\inetsrv\appcmd list apppools /state:Started /xml | & $env:windir\system32\inetsrv\appcmd stop apppools /in