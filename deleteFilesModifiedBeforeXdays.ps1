$HowOld = 10

#Path to the folder
$Path = "C:\Program Files\xMS\tmp\TCL_test"

$Logfile = "C:\Program Files\xMS\tmp\cleanup_$(gc env:computername).log"
function WriteLog
{
    Param ([string]$LogString)
   # $LogFile = "C:\$(gc env:computername).log"
    $DateTime = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    $LogMessage = "$Datetime $LogString"
    Add-content $Logfile -value $LogMessage
}



# Defines the 'x days old' (today's date minus x)
$age = (Get-Date).AddDays(-$HowOld)



# Get all the files in the folder and subfolders | foreach file
Get-ChildItem $Path -Recurse -File | foreach{
    # if creationtime is 'le' (less or equal) than x days
    if ($_.LastWriteTime -le $age){
        WriteLog "Remove: Older than $HowOld days - $($_.name)"
        # remove the item
        Remove-Item $_.fullname -Force -Verbose
    }else{
        Write-Output "Less than $HowOld days old - $($_.name)"
        # Do stuff
    }
}