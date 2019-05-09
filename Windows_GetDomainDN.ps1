$Root = [ADSI]"LDAP://RootDSE"
$Domain = $Root.Get("rootDomainNamingContext")
$Domain