


#$ErrorActionPreference = Stop
#$VerbosePreference = "SilentlyContinue"
cls

$VerbosePreference = "continue"
Set-StrictMode -Version 2.0
Set-Location c: 


#=========================================================================================
#LOAD SNAP INS
#-------------------------------------------------

#[System.Reflection.Assembly]::LoadWithPartialName("System.Data") | Out-Null
#[System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.SqlServer.Smo”) | Out-Null
#[System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.SqlServer.SmoExtended”)| Out-Null
Import-Module sqlps
#=========================================================================================


#=========================================================================================
#Variables to Hold Location of Master Configuration (list of clients that have the ACE UI Set-Up)
#-----------------------------------------------------------------------------------------
[String]$MasterConfigDatabase	= "GlobalHC"   #switched from Global 2017-11-22
#[String]$MasterConfigView		= "v_ACEUI_Config"
#[String]$MasterConfigSQL		= "Select [Client], [ACE_DB], [SERVER_DEV],[SERVER_PROD] from $MasterConfigView Where 1 = 1 "#'AND CLIENT like  'Cent%'"
#[String]$MasterConfigConnString = "integrated security=SSPI;data source=$MasterConfigServer;initial catalog=$MasterConfigDatabase;"
[String]$Global:LastStep        = ""

#=========================================================================================

#--------------------------------------------------------
#  ___ _   _ _  _  ___ _____ ___ ___  _  _ ___ 
# | __| | | | \| |/ __|_   _|_ _/ _ \| \| / __|
# | _|| |_| | .` | (__  | |  | | (_) | .` \__ \
# |_|  \___/|_|\_|\___| |_| |___\___/|_|\_|___/
#---------------------------------------------------------  

#==============================================================
#001:      PROCESS - START PROCESS
#==============================================================
FUNCTION EVL-PROCESS_START
		{	
            [cmdletbinding()]
            Param( [String]$pTargetServer
                    ,[String]$pServer
                    ,[String]$pProcessCode
                    ,[int]$pCompanyId
                    ,[String]$pProcessLOBCode
                    ,[String]$pNote
                    ,[String]$pDBName
                    ,[String]$pObjectName
                    ,[ref]$pProcessLogId
                    ,[Int]$pTimeOut	
                    )
           
		
			TRY
			{
         
                #------------------------------------------------
                #SET UP CONNECTION
                #------------------------------------------------
                    "001***********" |Write-Verbose
                    $sqlCn = new-object System.Data.SqlClient.SqlConnection
                    $sqlCn.ConnectionString = "integrated security=SSPI;data source=$pTargetServer;initial catalog='GlobalHC';"
                    $sqlCn.Open()
  
                #------------------------------------------------
                #SET UP Command to Pull Data from DEV
                #------------------------------------------------
                    $sqlCmd = new-object System.Data.SqlClient.SqlCommand
				    $sqlCmd.connection = $sqlCn
				    $SqlCmd.commandText = "EVL.uspProcessStart"
                    $sqlCmd.commandType = [System.Data.CommandType]'StoredProcedure'
                    $sqlCmd.CommandTimeout = $pTimeOut
                
                    #------------------------------
                    #(001) - ProcessCode Parameter
                    #------------------------------
                        $parProcessCode               = new-object System.Data.SqlClient.SqlParameter
                        $parProcessCode.ParameterName = "@pProcessCode"
                        $parProcessCode.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parProcessCode.Size          = 200
                        $parProcessCode.Direction     = [System.Data.ParameterDirection]'input'
                        $parProcessCode.Value         = $pProcessCode
                        $sqlCmd.Parameters.add($parProcessCode) 
                
                    #------------------------------
                    #(002) - COMPANY ID
                    #------------------------------
                        $parCompanyId               = new-object System.Data.SqlClient.SqlParameter
                        $parCompanyId.ParameterName = "@pCompanyId"
                        $parCompanyId.SqlDbType     = [System.Data.SqlDbType]'int'
                        $parCompanyId.Direction     = [System.Data.ParameterDirection]'input'
                        $parCompanyId.Value         = $pCompanyId
                        $sqlCmd.Parameters.add($parCompanyId) 
                    
                    #------------------------------
                    #(003) - ProcessCode Parameter
                    #------------------------------
                        $parLOBCode               = new-object System.Data.SqlClient.SqlParameter
                        $parLOBCode.ParameterName = "@pProcessLobCode"
                        $parLOBCode.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parLOBCode.Size          = 50
                        $parLOBCode.Direction     = [System.Data.ParameterDirection]'input'
                        $parLOBCode.Value         = $pProcessLOBCode
                        $sqlCmd.Parameters.add($parLOBCode) 

                    #------------------------------
                    #(004) - NOTE Parameter
                    #------------------------------
                        $parNote               = new-object System.Data.SqlClient.SqlParameter
                        $parNote.ParameterName = "@pNote"
                        $parNote.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parNote.Size          = 500
                        $parNote.Direction     = [System.Data.ParameterDirection]'input'
                        $parNote.Value         = $pNote
                        $sqlCmd.Parameters.add($parNote) 
                    #------------------------------
                    #(004) - Database SERVER Where Process Occurred
                    #------------------------------
                        $parPDBServer               = new-object System.Data.SqlClient.SqlParameter
                        $parPDBServer.ParameterName = "@pDBServer"
                        $parPDBServer.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parPDBServer.Size          = 255
                        $parPDBServer.Direction     = [System.Data.ParameterDirection]'input'
                        $parPDBServer.Value         = $pServer
                        $sqlCmd.Parameters.add($parPDBServer) 
                    #------------------------------
                    #(005) - Database Name where Process Occurred
                    #------------------------------
                        $parPDBName               = new-object System.Data.SqlClient.SqlParameter
                        $parPDBName.ParameterName = "@pDbName"
                        $parPDBName.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parPDBName.Size          = 255
                        $parPDBName.Direction     = [System.Data.ParameterDirection]'input'
                        $parPDBName.Value         = $pDbName
                        $sqlCmd.Parameters.add($parPDBName) 
                    #------------------------------
                    #(006) - Object Name where Process Occurred
                    #------------------------------
                        $parObjName               = new-object System.Data.SqlClient.SqlParameter
                        $parObjName.ParameterName = "@pObjectName"
                        $parObjName.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parObjName.Size          = 255
                        $parObjName.Direction     = [System.Data.ParameterDirection]'input'
                        $parObjName.Value         = $pObjectName
                        $sqlCmd.Parameters.add($parObjName) 
                    #------------------------------
                    #(007) - PROCESS ID created
                    #------------------------------
                        $parProcID               = new-object System.Data.SqlClient.SqlParameter
                        $parProcID.ParameterName = "@pProcessLogID"
                        $parProcID.SqlDbType     = [System.Data.SqlDbType]'bigint'
                        $parProcID.Direction     = [System.Data.ParameterDirection]'inputOutput'
                        $parProcId.Value         = 0
                        $sqlCmd.Parameters.add($parProcID) 

                #------------------------------------------------
                #EXECUTE Pull Data from DEV
                #------------------------------------------------
                        $sqlCmd.ExecuteNonQuery()
                        $sqlcn.close()
                        write-host "--------------------------"
                        write-host $parProcID.Value 
                        write-host "--------------------------"
                        $pProcessLogId.Value = $parProcID.Value 

        }
        CATCH {
                    $errMsg = $PSitem.exception.message
                    $errMsg = "<BR>PROCESS START FAILED: <BR>$errMsg"
                    write-host $errMsg
                    #THROW $errMsg
                }
        
        }



#==============================================================
#002:      PROCESS - END PROCESS
#==============================================================
FUNCTION EVL-PROCESS_END
		{	
            [cmdletbinding()]
            Param( [String]$pTargetServer
                    ,[int]$pProcessLogId
                    ,[String]$pNote
                    ,[String]$pCompletionStatus
                    ,[Int]$pTimeOut	
                    )
			TRY
			{
         
                #------------------------------------------------
                #SET UP CONNECTION
                #------------------------------------------------
                    
                    $sqlCn = new-object System.Data.SqlClient.SqlConnection
                    $sqlCn.ConnectionString = "integrated security=SSPI;data source=$pTargetServer;initial catalog='GlobalHC';"
                    $sqlCn.Open()
  
                #------------------------------------------------
                #SET UP Command to Pull Data from DEV
                #------------------------------------------------
                    $sqlCmd = new-object System.Data.SqlClient.SqlCommand
				    $sqlCmd.connection = $sqlCn
				    $SqlCmd.commandText = "EVL.uspProcessEnd"
                    $sqlCmd.commandType = [System.Data.CommandType]'StoredProcedure'
                    $sqlCmd.CommandTimeout = $pTimeOut
                
                    #------------------------------
                    #(000) - ProcessCode Parameter
                    #------------------------------
                        $parReturnCode               = new-object System.Data.SqlClient.SqlParameter
                        $parReturnCode.ParameterName = "@returnCode"
                        $parReturnCode.SqlDbType     = [System.Data.SqlDbType]'int'
                        $parReturnCode.Direction     = [System.Data.ParameterDirection]'returnvalue'
                        $parReturnCode.Value         = 0
                        $sqlCmd.Parameters.add($parReturnCode) 
                    #------------------------------
                    #(001) - ProcessCode Parameter
                    #------------------------------
                        $parProcessLogId               = new-object System.Data.SqlClient.SqlParameter
                        $parProcessLogId.ParameterName = "@pProcessLogId"
                        $parProcessLogId.SqlDbType     = [System.Data.SqlDbType]'int'
                        $parProcessLogId.Direction     = [System.Data.ParameterDirection]'input'
                        $parProcessLogId.Value         = $pProcessLogId
                        $sqlCmd.Parameters.add($parProcessLogId) 
                    #------------------------------
                    #(002) - NOTE Parameter
                    #------------------------------
                        $parNote               = new-object System.Data.SqlClient.SqlParameter
                        $parNote.ParameterName = "@pNote"
                        $parNote.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parNote.Size          = 500
                        $parNote.Direction     = [System.Data.ParameterDirection]'input'
                        $parNote.Value         = $pNote
                        $sqlCmd.Parameters.add($parNote) 
                    #------------------------------
                    #(003) - COMPLETEION STATUS Parameter (Success/Failure/Uknown)
                    #------------------------------
                        $parStatus               = new-object System.Data.SqlClient.SqlParameter
                        $parStatus.ParameterName = "@pCompletionStatus"
                        $parStatus.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parStatus.Size          = 30
                        $parStatus.Direction     = [System.Data.ParameterDirection]'input'
                        $parStatus.Value         = $pCompletionStatus
                        $sqlCmd.Parameters.add($parStatus) 
                        
                #------------------------------------------------
                #EXECUTE Pull Data from DEV
                #------------------------------------------------
                        $sqlCmd.ExecuteNonQuery()
                        
                        write-host $sqlcmd.Parameters[0].value
                        
                        $sqlcn.close()
                        

                        


        }
        CATCH {
                    $errMsg = $PSitem.exception.message
                    $errMsg = "<BR>PROCESS END FAILED: <BR>$errMsg"
                    write-host $errMsg
                    #THROW $errMsg
                }
        
        }



#==============================================================
#001:      PROCESS - START PROCESS
#==============================================================
FUNCTION EVL-EVENT_START
		{	
            [cmdletbinding()]
            Param( [String]$pTargetServer
                    ,[int]$pProcessLogId
                    ,[String]$pEventTaskCode
                    ,[String]$pNote
                    ,[ref]$pEventLogId
                    ,[String]$pServerName
                    ,[String]$pDbName
                    ,[String]$pObjectName
                    ,[Int]$pTimeOut	
                    )
           
		
			TRY
			{
         
                #------------------------------------------------
                #SET UP CONNECTION
                #------------------------------------------------
                    $sqlCn = new-object System.Data.SqlClient.SqlConnection
                    $sqlCn.ConnectionString = "integrated security=SSPI;data source=$pTargetServer;initial catalog='GlobalHC';"
                    $sqlCn.Open()
  
                #------------------------------------------------
                #SET UP Command to Pull Data from DEV
                #------------------------------------------------
                    $sqlCmd = new-object System.Data.SqlClient.SqlCommand
				    $sqlCmd.connection = $sqlCn
				    $SqlCmd.commandText = "EVL.uspEventStart"
                    $sqlCmd.commandType = [System.Data.CommandType]'StoredProcedure'
                    $sqlCmd.CommandTimeout = $pTimeOut
                
                    #------------------------------
                    #(001) - Process Log Id 
                    #------------------------------
                        $parProcessLogId               = new-object System.Data.SqlClient.SqlParameter
                        $parProcessLogId.ParameterName = "@pProcessLogId"
                        $parProcessLogId.SqlDbType     = [System.Data.SqlDbType]'int'
                        $parProcessLogId.Direction     = [System.Data.ParameterDirection]'input'
                        $parProcessLogId.Value         = $pProcessLogId
                        $sqlCmd.Parameters.add($parProcessLogId) 
                
                    #------------------------------
                    #(002) - EVENT TASK CODE
                    #------------------------------
                        $parEventTask               = new-object System.Data.SqlClient.SqlParameter
                        $parEventTask.ParameterName = "@pEventTaskCode"
                        $parEventTask.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parEventTask.Size          = 50
                        $parEventTask.Direction     = [System.Data.ParameterDirection]'input'
                        $parEventTask.Value         = $pEventTaskCode
                        $sqlCmd.Parameters.add($parEventTask) 
                    
                    #------------------------------
                    #(003) - NOTE PARAMETER
                    #------------------------------
                        $parNote               = new-object System.Data.SqlClient.SqlParameter
                        $parNote.ParameterName = "@pNote"
                        $parNote.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parNote.Size          = 500
                        $parNote.Direction     = [System.Data.ParameterDirection]'input'
                        $parNote.Value         = $pNote
                        $sqlCmd.Parameters.add($parNote) 

                    #------------------------------
                    #(004) - EVENT LOG ID
                    #------------------------------
                        $parEventLogId               = new-object System.Data.SqlClient.SqlParameter
                        $parEventLogId.ParameterName = "@pEventLogId"
                        $parEventLogId.SqlDbType     = [System.Data.SqlDbType]'bigint'
                        $parEventLogId.Direction     = [System.Data.ParameterDirection]'inputoutput'
                        $parEventLogId.Value         = 0
                        $sqlCmd.Parameters.add($parEventLogId) 
                    
                    #------------------------------
                    #(005) - Database SERVER Where Process Occurred
                    #------------------------------
                        $parPDBServer               = new-object System.Data.SqlClient.SqlParameter
                        $parPDBServer.ParameterName = "@pDBServer"
                        $parPDBServer.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parPDBServer.Size          = 255
                        $parPDBServer.Direction     = [System.Data.ParameterDirection]'input'
                        $parPDBServer.Value         = $pServerName
                        $sqlCmd.Parameters.add($parPDBServer) 
                    #------------------------------
                    #(006) - Database Name where Process Occurred
                    #------------------------------
                        $parPDBName               = new-object System.Data.SqlClient.SqlParameter
                        $parPDBName.ParameterName = "@pDbName"
                        $parPDBName.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parPDBName.Size          = 255
                        $parPDBName.Direction     = [System.Data.ParameterDirection]'input'
                        $parPDBName.Value         = $pDbName
                        $sqlCmd.Parameters.add($parPDBName) 
                    #------------------------------
                    #(007) - Object Name where Process Occurred
                    #------------------------------
                        $parObjName               = new-object System.Data.SqlClient.SqlParameter
                        $parObjName.ParameterName = "@pObjectName"
                        $parObjName.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parObjName.Size          = 255
                        $parObjName.Direction     = [System.Data.ParameterDirection]'input'
                        $parObjName.Value         = $pObjectName
                        $sqlCmd.Parameters.add($parObjName) 
                #------------------------------------------------
                #EXECUTE Pull Data from DEV
                #------------------------------------------------
                        $sqlCmd.ExecuteNonQuery()
                        $sqlcn.close()
                        $pEventLogId.Value = $parEventLogId.Value

        }
        CATCH {
                    $errMsg = $PSitem.exception.message
                    $errMsg = "<BR>EVENT START FAILED: <BR>$errMsg"
                    write-host $errMsg
                    #THROW $errMsg
                }
        
        }

#==============================================================
#004:      EVENT - END EVENT
#==============================================================
FUNCTION EVL-EVENT_END
		{	
            [cmdletbinding()]
            Param( [String]$pTargetServer
                    ,[int]$pEventLogId
                    ,[String]$pNote
                    ,[String]$pCompletionStatus
                    ,[Int]$pTimeOut	
                    )
			TRY
			{
         
                #------------------------------------------------
                #SET UP CONNECTION
                #------------------------------------------------
                    
                    $sqlCn = new-object System.Data.SqlClient.SqlConnection
                    $sqlCn.ConnectionString = "integrated security=SSPI;data source=$pTargetServer;initial catalog='GlobalHC';"
                    $sqlCn.Open()
  
                #------------------------------------------------
                #SET UP Command to Pull Data from DEV
                #------------------------------------------------
                    $sqlCmd = new-object System.Data.SqlClient.SqlCommand
				    $sqlCmd.connection = $sqlCn
				    $SqlCmd.commandText = "EVL.uspEventEnd"
                    $sqlCmd.commandType = [System.Data.CommandType]'StoredProcedure'
                    $sqlCmd.CommandTimeout = $pTimeOut
                
                    #------------------------------
                    #(000) - ProcessCode Parameter
                    #------------------------------
                        $parReturnCode               = new-object System.Data.SqlClient.SqlParameter
                        $parReturnCode.ParameterName = "@returnCode"
                        $parReturnCode.SqlDbType     = [System.Data.SqlDbType]'int'
                        $parReturnCode.Direction     = [System.Data.ParameterDirection]'returnvalue'
                        $parReturnCode.Value         = 0
                        $sqlCmd.Parameters.add($parReturnCode) 
                    #------------------------------
                    #(001) - ProcessCode Parameter
                    #------------------------------
                        $parEventLogId               = new-object System.Data.SqlClient.SqlParameter
                        $parEventLogId.ParameterName = "@pEventLogId"
                        $parEventLogId.SqlDbType     = [System.Data.SqlDbType]'bigint'
                        $parEventLogId.Direction     = [System.Data.ParameterDirection]'input'
                        $parEventLogId.Value         = $pEventLogId
                        $sqlCmd.Parameters.add($parEventLogId) 
                    #------------------------------
                    #(002) - NOTE Parameter
                    #------------------------------
                        $parNote               = new-object System.Data.SqlClient.SqlParameter
                        $parNote.ParameterName = "@pNote"
                        $parNote.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parNote.Size          = 500
                        $parNote.Direction     = [System.Data.ParameterDirection]'input'
                        $parNote.Value         = $pNote
                        $sqlCmd.Parameters.add($parNote) 
                    #------------------------------
                    #(003) - COMPLETEION STATUS Parameter (Success/Failure/Uknown)
                    #------------------------------
                        $parStatus               = new-object System.Data.SqlClient.SqlParameter
                        $parStatus.ParameterName = "@pCompletionStatus"
                        $parStatus.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parStatus.Size          = 30
                        $parStatus.Direction     = [System.Data.ParameterDirection]'input'
                        $parStatus.Value         = $pCompletionStatus
                        $sqlCmd.Parameters.add($parStatus) 
                        
                #------------------------------------------------
                #EXECUTE Pull Data from DEV
                #------------------------------------------------
                        $sqlCmd.ExecuteNonQuery()
                        $sqlcn.close()

        }
        CATCH {
                    $errMsg = $PSitem.exception.message
                    $errMsg = "<BR>PROCESS END FAILED: <BR>$errMsg"
                    write-host $errMsg
                    #THROW $errMsg
                }
        
        }

#==============================================================
#004:      EVENT - END EVENT
#==============================================================
FUNCTION EVL-LogError
		{	
            [cmdletbinding()]
            Param( [String]$pTargetServer
                    ,[int]$pProcessLogId
                    ,[int]$pEventLogId
                    ,[String]$pErrMsg
                    ,[Int]$pTimeOut	
                    )
			TRY
			{
         
                #------------------------------------------------
                #SET UP CONNECTION
                #------------------------------------------------
                    
                    $sqlCn = new-object System.Data.SqlClient.SqlConnection
                    $sqlCn.ConnectionString = "integrated security=SSPI;data source=$pTargetServer;initial catalog='GlobalHC';"
                    $sqlCn.Open()
  
                #------------------------------------------------
                #SET UP Command to Pull Data from DEV
                #------------------------------------------------
                    $sqlCmd = new-object System.Data.SqlClient.SqlCommand
				    $sqlCmd.connection = $sqlCn
				    $SqlCmd.commandText = "EVL.uspLogError"
                    $sqlCmd.commandType = [System.Data.CommandType]'StoredProcedure'
                    $sqlCmd.CommandTimeout = $pTimeOut
                
                    #------------------------------
                    #(000) - ProcessCode Parameter
                    #------------------------------
                        $parReturnCode               = new-object System.Data.SqlClient.SqlParameter
                        $parReturnCode.ParameterName = "@returnCode"
                        $parReturnCode.SqlDbType     = [System.Data.SqlDbType]'int'
                        $parReturnCode.Direction     = [System.Data.ParameterDirection]'returnvalue'
                        $parReturnCode.Value         = 0
                        $sqlCmd.Parameters.add($parReturnCode) 
                    #------------------------------
                    #(001) - ProcessCode Parameter
                    #------------------------------
                        $parProcessLogId               = new-object System.Data.SqlClient.SqlParameter
                        $parProcessLogId.ParameterName = "@pProcessLogId"
                        $parProcessLogId.SqlDbType     = [System.Data.SqlDbType]'bigint'
                        $parProcessLogId.Direction     = [System.Data.ParameterDirection]'input'
                        $parProcessLogId.Value         = $pProcessLogId
                        $sqlCmd.Parameters.add($parProcessLogId) 
                    #------------------------------
                    #(002) - ProcessCode Parameter
                    #------------------------------
                        $parEventLogId               = new-object System.Data.SqlClient.SqlParameter
                        $parEventLogId.ParameterName = "@pEventLogId"
                        $parEventLogId.SqlDbType     = [System.Data.SqlDbType]'bigint'
                        $parEventLogId.Direction     = [System.Data.ParameterDirection]'input'
                        $parEventLogId.Value         = $pEventLogId
                        $sqlCmd.Parameters.add($parEventLogId) 
                    
                    #------------------------------
                    #(002) - NOTE Parameter
                    #------------------------------
                        $parErrMsg               = new-object System.Data.SqlClient.SqlParameter
                        $parErrMsg.ParameterName = "@pErrMsg"
                        $parErrMsg.SqlDbType     = [System.Data.SqlDbType]'varchar'
                        $parErrMsg.Size          = 8000
                        $parErrMsg.Direction     = [System.Data.ParameterDirection]'input'
                        $parErrMsg.Value         = $pErrMsg
                        $sqlCmd.Parameters.add($parErrMsg) 
                    
                        
                #------------------------------------------------
                #EXECUTE Pull Data from DEV
                #------------------------------------------------
                        $sqlCmd.ExecuteNonQuery()
                        $sqlcn.close()

        }
        CATCH {
                    $errMsg = $PSitem.exception.message
                    $errMsg = "<BR>LOG ERROR FAILED: <BR>$errMsg"
                    write-host $errMsg
                    #THROW $errMsg
                }
        
        }
#--------------------------------------------
#  __  __   _   ___ _  _ 
# |  \/  | /_\ |_ _| \| |
# | |\/| |/ _ \ | || .` |
# |_|  |_/_/ \_\___|_|\_|
#--------------------------------------------


#[int]$ProcessLogId =  0
#[int]$EventLogId =  3
#EVL-PROCESS_START -pTargetServer "DC-PICO" -pProcessCode "TEST" -pServer "DS-FLD-003" -pCompanyId 9999 -pProcessLOBCode "General" -pNote "TEST NOTE" -pDBName "testDb" -pObjectName "powershellScript" -pProcessLogId ([ref]$ProcessLogId)  -pTimeOut 30 

cls
#[int]$ProcessLogId =  6
#EVL-PROCESS_END -pTargetServer "DC-PICO" -pProcessLogId $ProcessLogId -pNote "" -pCompletionStatus "S" -pTimeOut 30 

#EVL-EVENT_START -pTargetServer "DC-PICO" -pProcessLogId $ProcessLogId -pEventTaskCode "GENERAL" -pNote "Test Event Note" -pEventLogId ([ref]$EventLogId) -pServerName "DS-FLD-003" -pDbName "testDB" -pObjectName "thisPSScript" -pTimeOut 30 


#EVL-EVENT_END -pTargetServer "DC-PICO" -PEVENTLOGID $EventLogId -pNote "" -pCompletionStatus "S" -pTimeOut 30 
#EVL_Ev -pTargetServer "DC-PICO" -pProcessLogId $ProcessLogId -pNote "" -pCompletionStatus "S" -pTimeOut 30 

#EVL-LogError -pTargetServer "DC-PICO" -pProcessLogId $ProcessLogId -pEventLogId $EventLogId -pErrMsg "Arbitrary Failure Test" -pTimeOut 30 