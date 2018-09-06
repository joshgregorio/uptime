# read a group of servers from a file, figure out which domain they are on, 
# ask user for credentials, and check to see if server has been up for less then 24 hours. 

Function Parse-Servers {
    param(
        [string[]]$servers
    )
	# replace DC1 and DC2 with domain names. 
    $DC1 = @()
    $DC2 = @()
    $both = @()

    foreach($server in $servers) {
        
        try {
            $tmp = [Net.DNS]::GetHostEntry($server)
            $domain = $tmp.HostName.split('.')
        }
        Catch {
            Write-Error "$server No DNS Entry"
        }
        if($domain[1] -eq 'DC1') {
            $DC1 += $server
        }
        elseif($domain[1] -eq 'DC2') {
            $DC2 += $server 
        }
        else{
            Write-Error "$server Could not locate domain"
        }
    } # end foreach 

    $both += ,$DC2
    $both += ,$DC1
    Return $both
 
} # end function Parse-Servers

function Get-Uptime {

    param( 
        [String[]]$ComputerName,
        [PSCredential]$creds)

    $yesterday = ([DateTime]"23:59:00").AddDays(-1)
    
    foreach($computer in $ComputerName) {
        Try {
            $os = Get-WmiObject -Class win32_operatingsystem `
            -ComputerName $computer -Credential $creds -ErrorAction Stop
        }

        Catch { #really need to add a catch block to catch invalid cred errors...
            Write-Output "$Computer UNABLE TO CONNECT TO SERVER" | Out-File $tmpOutFile -Append
            Continue
        }

        $upTime = ($os.ConvertToDateTime($os.lastbootuptime))
        $span = $yesterday - $upTime # returns a timespan, we can check if the time between uptime and midnight the previous day is less than 1 day, this is probably buggy 

        if($span.Days -lt 1.0) {
            Write-Output "Server $computer has been up for less than 24 hours" | Out-File $tmpOutFile -Append
        }
        else {
            Write-Output "$computer up since $upTime" | Out-File $tmpOutFile -Append
        }
    }

    

} #end function Get-Uptime


Try{

    $comps = Get-Content $args[0] -ErrorAction Stop
}
Catch {
    Write-Host "Please specify a valid file with list of computers to check." -ForegroundColor Red
    Write-Host "usage: Get-Uptime.ps1 <serverlist.txt>" -ForegroundColor Green
}

$tmpOutFile = "Uptime-$(Get-Date -f yyyy-MM-dd).txt"
Write-Host "Please enter your DC1 admin creds (DC1\adminXX): "
$DC1Creds = Get-Credential
Write-Host "Please enter your DC2 Creds (DC2\xxxxxx): "
$DC2Creds = Get-Credential

$allServers = Parse-Servers $comps
$DC2Servers = $allServers[0]
$DC1Servers = $allServers[1]
Get-Uptime $DC1servers $DC1Creds
Get-Uptime $DC2Servers $DC2Creds

c:\windows\system32\notepad ./$tmpOutfile 