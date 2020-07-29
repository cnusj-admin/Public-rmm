###This will create Datto sites to match Control entries, and install agents, for any agents in a group 'Servers'
###This is easily adjustable. on line 38

### ADJUST THESE AS NEEDED ####
install-module DattoRmm

#Datto settings
$DattoURL = "https://concord-api.centrastage.net" # adjust as needed
$DattoKey = "" #API key
$DattoSky = "" #Api Secret Key 
import-module DattoRmm
Set-DrmmApiParameters -url $DattoUrl -Key $DattoKey -SecretKey $DattoSky
$siteslist = Get-DrmmAccountSites 

#CWControl server info. 
$Server = 'https://<YourUrl>.screenconnect.com' # Will work with on-prem
$Credentials = Get-Credential
$CWCInfo = @{
        Server = $Server;    
        Credentials = $Credentials;
    }
#Import CWPosh
irm 'https://bit.ly/controlposh' | iex

#Setup the script block, currently does not handle errors. 
$CWCCommandRunner ={
    param($Server,$Creds,$AgentUrl)
    $CWCInfo = @{
        Server = $Server;    
        Credentials = $Credentials;
    }
    $command = "(New-Object System.Net.WebClient).DownloadFile('$AgentUrl','c:\windows\temp\dattormm.exe') "
    #Downloads the .exe to temp
    $result=Invoke-CWCCommand @CWCInfo -GUID $comp.SessionID -powershell -command $command -timeout 50000
    #Runs it in a seperate command. 
    $result=Invoke-CWCCommand @CWCInfo -GUID $comp.SessionID -command 'c:\windows\temp\dattormm.exe' -timeout 500000
}

#Gets All Computers in a given group and cycles through them.
$Computers = Get-CWCSessions @CWCInfo -Type Access -group Servers
if (!$Computers) { return "Computer not found" }

foreach ($comp in $Computers) {
    $sitename=$comp.CustomPropertyValues[0] 
    write-host "Computer name: " $comp.name "@" $sitename
    $notfound = $true
    foreach ($site in $siteslist) {
        if ($site.name -eq $sitename) {
            $notfound = $false
            $siteID = $Site.uid
        }
    }
    if ($notfound) {
        write-host "Creating Site $siteName"
        $site = New-DrmmSite -siteName $sitename      
        $siteID = $Site.uid
        $siteslist = Get-DrmmAccountSites #refresh the site list for next loop. 
    }
    $agenturl = "$DattoURL/csm/profile/downloadAgent/$siteid"        
    Start-Job -scriptblock $CWCCommandRunner  -name "CWCCommandRunner" -ArgumentList $Server, $agenturl, $Powershell, $Credentials
    }