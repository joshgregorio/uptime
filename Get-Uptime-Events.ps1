# quick and dirty script to read a list of computers and check uptime plus parse event logs for 
# common error messages. 

function Get-Uptime {

    param( 
        [String[]]$ComputerName)

    $midnight = ([DateTime]"23:59:00").AddDays(-1)
    $EventsNotFound = 0

    foreach($computer in $ComputerName) {
        Try {
            $os = Get-WmiObject -Class win32_operatingsystem `
            -ComputerName $computer -ErrorAction Stop
        }

        Catch {
            Write-Output "$Computer UNABLE TO CONNECT TO SERVER"
            Continue
        }
        $upTime = ($os.ConvertToDateTime($os.lastbootuptime))
        $daysUp = $midnight - $upTime # returns a timespan
        

        if ($daysUp.TotalDays -lt 1.0){ #this entire section needs complete re-write; please don't do this I was in a hurry. 
            
            Try{
                $evnt = get-winevent -Computername $computer -FilterHashtable @{Logname='System';ID=1074}  -MaxEvents 1 -ErrorAction Stop
                $span = $midnight - $evnt.TimeCreated
                $DAYS = $span.TotalDays
           }
            
            Catch {
                $DAYS = 2
            }           
            if ($DAYS -le 1.0){

                Write-Output "$computer " $evnt.TimeCreated $evnt.Message "`n"
            }

            elseif ($DAYS -gt 1){
                Try{
                    $evnt2 = get-winevent -Computername $computer -FilterHashtable @{Logname='System';ID=41 }  -MaxEvents 1 -ErrorAction Stop
                    $span2 = $midnight - $evnt2.TimeCreated
                    if ($span2.TotalDays -le 1.0) {
                        Write-Output "$computer Event 41 Kernel power" "`n"
                    }
                }
                Catch{
                    $EventsNotFound = 9999
                }
            }
            if($EventsNotFound -eq 9999) {
                Write-Output "$computer No cause for  shutdown found please check further"
            }

        }
        
        
        else {
            $data = "$computer up since " + $upTime
            Write-Output "$data" "`n"
          
        }
        
      
    }

}

Try{

    $comps = Get-Content $args[0] -ErrorAction Stop
}
Catch {
    Write-Host "Please specify a valid file with list of computers to check." -ForegroundColor Red
    Write-Host "usage: Get-Uptime.ps1 <serverlist.txt>" -ForegroundColor Green
}
Get-Uptime $comps

