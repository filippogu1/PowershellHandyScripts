#-------------------------------------------------
#PUT BAT FILE PATH HERE
#-------------------------------------------------
[string]$lsVBScriptPath = "\\ccaintranet.com\dfs-dc-01\Data\FS02-V\Healthcare\Product\DataTeam\FQDNServerCheck\CheckFQDNServer_FromScheduledJob_writeTotxt.vbs"

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

TRY {

    EVL-PROCESS_START -pTargetServer $EVL_TargetServer -pProcessCode $EVL_ProcessName -pServer $EVL_ActionDBSvr -pCompanyId $EVL_CompanyID -pProcessLOBCode $EVL_ProcessLOB -pNote $EVL_Note -pDBName $EVL_ActionDBName -pObjectName $EVL_ActionObj -pProcessLogId ([ref]$EVL_ProcessLogId)  -pTimeOut 30 

    # -FileName is the application we run to start the process, -Arguments is the actual vbs script being run.
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = 'C:\Windows\system32\cscript.exe'
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $lsVBScriptPath
    
    # Create a Process Object to track ExitCode and StdErr, and catching errors accordingly
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()      # $stdout here always print "Microsoft (R) Windows Script Host Version 5.8", real error message is in $stderr
    $stderr = $p.StandardError.ReadToEnd()       # if vbs fails, syntax error, SQL connection & execution error will be contained in here. 
    $stdExitCode = $p.ExitCode                   # ExitCode will always be 0 if vbs executed successfully, it has to be one of the criteria proving that
    [int]$stderrLen = $stderr.Length
    #Write-Host "stdout: $stdout"
    #Write-Host "stderr: $stderr"
    #Write-Host "stderr Len: $stderrLen"
    #Write-Host "exit code: " + $stdExitCode

    if ($stdExitCode -eq 0 -and $stderrLen -eq 0) {

        # Process ends successfully with both ExitCode = 0 and no Error output. We put normal ProcessEnd here to mark it 'S'
        EVL-PROCESS_END -pTargetServer $EVL_TargetServer -pProcessLogId $EVL_ProcessLogId -pNote "" -pCompletionStatus "S" -pTimeOut 30    #Leave the Note Blank unless you want to overRide the original value

    } else {

        # Other errors are either a syntax error which has $stderr.length > 0, or ExitCode > 0. We handle them in this block
        $EVL_ErrMsg = $stderr
        [String]$EVL_ErrMessage = "$EVL_Note - $EVL_ErrMsg"  #Capture any additional info here
        EVL-LogError -pTargetServer $EVL_TargetServer -pProcessLogId $EVL_ProcessLogId -pEventLogId $EVL_EventLogId -pErrMsg $EVL_ErrMessage  -pTimeOut 30      #2018-05-21 New Centralized Logging

    }       

} CATCH {

    # CATCH block is to catch error which occurs within ps1 code itself
    $EVL_ErrMsg = $PSItem.Exception.Message
    [String]$EVL_ErrMessage = "$EVL_Note - $EVL_ErrMsg" 
    EVL-LogError -pTargetServer $EVL_TargetServer -pProcessLogId $EVL_ProcessLogId -pEventLogId $EVL_EventLogId -pErrMsg $EVL_ErrMessage  -pTimeOut 30      #2018-05-21 New Centralized Logging

} 
FINALLY {

    $p.close()

}






    


