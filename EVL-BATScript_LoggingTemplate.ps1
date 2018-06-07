#-------------------------------------------------
#PUT BAT FILE PATH HERE
#-------------------------------------------------
[string]$lsBatFilePath = "\\ccaintranet.com\dfs-dc-01\Data\FS02-V\Healthcare\Product\DataTeam\philip\Central Logging Test\PS1 Templates\Test.bat"

#-------------------------------------------------
#Global Logging Variables (added 2018-05-22)
#-------------------------------------------------

[string]$EVLUtil      = "\\ccaintranet.com\dfs-dc-01\Data\FS02-V\Healthcare\Product\DataTeam\CentralLog\EVL-FUNCTIONS.ps1"        #added 2018-05-21 Location of Centralized Functions
.$EVLUtil
[int]$EVL_ProcessLogId    = 0                     #Used to Keep Track of a new instance of a Process
[int]$EVL_EventLogID      = 0                     #Only needed if additional Event loggins is implemented

#--------------------------------
#--------------------------------
#Manual Update
#--------------------------------
[int]$EVL_CompanyId       = 9999                                        #CompanyId being logged > use 9999 as default for General/All
[string]$EVL_ProcessName  = "SchedTask"                                 #Indicates that a Scheduled Task is begin run
[string]$EVL_Note         = "XXXX_PUT_PROCESS_NAME_HERE_XXXX"           #Short Description of Process
[String]$EVL_TargetServer = "XXXX_SERVER_NAME_XXXX"                     #(Optional) Server On Which to Log the Process (Not what is being logged)
[String]$EVL_ScriptName   = $MyInvocation.MyCommand.Definition          #Log the Name & Location of the script. This may already exist in the script you are updating
[String]$EVL_ActionDBSvr  = ""                                          #(OpCotivititional) Server on which Action is taken
[String]$EVL_ActionDBName = ""                                          #(Optional) Database on which action is taken 
[String]$EVL_ActionObj    = $EVL_ScriptName                             #Log the Script location in case it needs to be triaged
[String]$EVL_ProcessLOB   = "General"                                   #(Optional) Not realy needed for Scheduled Tasks
[String]$EVL_ErrMsg       = ""                                     #Error Message to be appended to initial "NOTE" when the Error Handling is encountered

EVL-PROCESS_START -pTargetServer $EVL_TargetServer -pProcessCode $EVL_ProcessName -pServer $EVL_ActionDBSvr -pCompanyId $EVL_CompanyID -pProcessLOBCode $EVL_ProcessLOB -pNote $EVL_Note -pDBName $EVL_ActionDBName -pObjectName $EVL_ActionObj -pProcessLogId ([ref]$EVL_ProcessLogId)  -pTimeOut 30 
    
# Use CMD to run the bat file
# cmd.exe /c $lsBatFilePath
# Start-Process -FilePath $lsBatFilePath

$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = $lsBatFilePath
$pinfo.RedirectStandardError = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false
$pinfo.Arguments = "localhost"

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
$stdExitCode = $p.ExitCode
[int]$stderrLen = $stderr.Length
#Write-Host "stdout: $stdout"
#Write-Host "stderr: $stderr"
#Write-Host "stderr Len: $stderrLen"
#Write-Host "exit code: " + $stdExitCode

TRY {

    if ($stdExitCode -eq 0 -and $stderrLen -eq 0) {

        # Process ends successfully with both ExitCode = 0 and no Error output. We put normal ProcessEnd here to mark it 'S'
        EVL-PROCESS_END -pTargetServer $EVL_TargetServer -pProcessLogId $EVL_ProcessLogId -pNote "" -pCompletionStatus "S" -pTimeOut 30    #Leave the Note Blank unless you want to overRide the original value

    } elseif ($stdExitCode -eq 1 -and $stderrLen -eq 0) {
    
        # This specifies a SQLCMD execution exception, we need to output $stdout as SQL error to EVL.ProcessLog [Note] column
        $EVL_ErrMsg = $stdout
        [String]$EVL_ErrMessage = "$EVL_Note - $EVL_ErrMsg"  #Capture any additional info here
        EVL-LogError -pTargetServer $EVL_TargetServer -pProcessLogId $EVL_ProcessLogId -pEventLogId $EVL_EventLogId -pErrMsg $EVL_ErrMessage  -pTimeOut 30      #2018-05-21 New Centralized Logging

    } else {

        # Other errors are either a syntax error which has $stderr.length > 0, or ExitCode > 0. We handle them in this block
        $EVL_ErrMsg = $stderr
        [String]$EVL_ErrMessage = "$EVL_Note - $EVL_ErrMsg"  #Capture any additional info here
        EVL-LogError -pTargetServer $EVL_TargetServer -pProcessLogId $EVL_ProcessLogId -pEventLogId $EVL_EventLogId -pErrMsg $EVL_ErrMessage  -pTimeOut 30      #2018-05-21 New Centralized Logging

    }       

} CATCH {

    # CATCH block is to catch error which occurs within ps1 code itself
    $EVL_ErrMsg = $_.Exception.Message
    [String]$EVL_ErrMessage = "$EVL_Note - $EVL_ErrMsg"  
    EVL-LogError -pTargetServer $EVL_TargetServer -pProcessLogId $EVL_ProcessLogId -pEventLogId $EVL_EventLogId -pErrMsg $EVL_ErrMessage  -pTimeOut 30      #2018-05-21 New Centralized Logging

} FINALLY {

    $p.close()

}






    
