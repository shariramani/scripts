$HowOld = 45

#Path to the folder where script will look and delete older files
#Note script will also look in all subfolders 
$Path1 = "C:\Program Files\xMS\tmp\backup"
$Path2 = "C:\Program Files\xMS\tmp\reports"

$Logfile = "C:\Program Files\xMS\tmp\cleanup_$(gc env:computername).log"
function WriteLog
{
    Param ([string]$LogString)
   # $LogFile = "C:\$(gc env:computername).log"
    $DateTime = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    $LogMessage = "$Datetime $LogString"a
    Add-content $Logfile -value $LogMessage
}a



# Defines the 'x days old' (today's date minus x)
$age = (Get-Date).AddDays(-$HowOld)



# Get all the files in the folder and subfolders | foreach file
Get-ChildItem $Path1,$Path2 -Recurse -File | foreach{
    # if creationtime is 'le' (less or equal) than x days
    if ($_.CreationTime -le $age){
        WriteLog "Remove: Older than $HowOld days - $($_.fullname)"
        # remove the item (suffix -whatif to just check and no action done) 
        Remove-Item $_.fullname -Force -Verbose
    }else{
        Write-Output "Less than $HowOld days old - $($_.fullname)"
        # Do stuff
    }
}