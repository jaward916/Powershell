   
   #source via: https://social.technet.microsoft.com/Forums/windowsserver/en-US/79958c6e-4763-4bd7-8b23-2c8dc5457131/sample-code-required-for-invokerestmethod-using-https-and-basic-authorisation?forum=winserverpowershell&forum=winserverpowershell
   #place at top of any powershell scripts which invoke https urls with self signed certs
   ##NEW SELF CERT HACK##
    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    
    public class IDontCarePolicy : ICertificatePolicy {
        public IDontCarePolicy() {}
        public bool CheckValidationResult(
            ServicePoint sPoint, X509Certificate cert,
            WebRequest wRequest, int certProb) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy 
###END SELF CERT HACK