
#-------------------------------------------------------------------------------------------------------------------------
#STEP 1 - Copy-Paste EVL-FUNCTIONS path and parameters at the start, and MANUAL UPDATE dates and parameters
#-------------------------------------------------------------------------------------------------------------------------

#-------------------------------------------------
#Global Logging Variables (added XXXX-XX-XX)
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
[String]$EVL_ErrMsg       = ""                                          #Error Message to be appended to initial "NOTE" when the Error Handling is encountered


#-------------------------------------------------------------------------------------------------------------------------
#STEP 2 - Put Process (Or Event) Start & End logic in current TRY-CATCH block, like below:
#-------------------------------------------------------------------------------------------------------------------------
#trap { "Error trapped: $_"; return}
TRY {

    EVL-PROCESS_START -pTargetServer $EVL_TargetServer -pProcessCode $EVL_ProcessName -pServer $EVL_ActionDBSvr -pCompanyId $EVL_CompanyID -pProcessLOBCode $EVL_ProcessLOB -pNote $EVL_Note -pDBName $EVL_ActionDBName -pObjectName $EVL_ActionObj -pProcessLogId ([ref]$EVL_ProcessLogId)  -pTimeOut 30 

	# Real work being done by powershell here...

    EVL-PROCESS_END -pTargetServer $EVL_TargetServer -pProcessLogId $EVL_ProcessLogId -pNote "" -pCompletionStatus "S" -pTimeOut 30    #Leave the Note Blank unless you want to overRide the original value


} #End Try
catch {                

    $EVL_ErrMsg = $PSitem.Exception.Message
    [String]$EVL_ErrMessage = "$EVL_Note - $EVL_ErrMsg"  
    EVL-LogError -pTargetServer $EVL_TargetServer -pProcessLogId $EVL_ProcessLogId -pEventLogId $EVL_EventLogId -pErrMsg $EVL_ErrMessage  -pTimeOut 30      #2018-05-21 New Centralized Logging

    # Original Error handling and logging code...
        
        
}