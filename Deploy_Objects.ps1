Import-Module sqlps 
#$ErrorActionPreference = Stop
cls
$VerbosePreference = "SilentlyContinue"
$VerbosePreference = "continue"

$Global:ScriptName = $PSCommandPath 
$Global:ScriptName | write-verbose
$Global:FilePath = Split-Path  $ScriptName  
$Global:FilePath | Write-Verbose

Set-StrictMode -Version 2.0

#=========================================================================================
#LOAD SNAP INS
#-------------------------------------------------

#[System.Reflection.Assembly]::LoadWithPartialName("System.Data") | Out-Null
#[System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.SqlServer.Smo”) | Out-Null
#[System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.SqlServer.SmoExtended”)| Out-Null

#=========================================================================================

#----------------------------------------------------------------------------------------------------
#CREATED:    2017-11-01 > Deploy files in the folder to a specific fodler
#PURPOSE:    Run the SQL files in the list Sub-folders (Tables, Views, Procs) against the indicated Database
#----------------------------------------------------------------------------------------------------
    FUNCTION DEPLOY-TODB
    {
        [cmdletbinding()]
        Param(	[String]$pServerName, [String]$pDatabaseName )

        [string]$errMsg = ""
        TRY
        {
                #-----------------------------------------------------------------
                #Process Folders in Order
                #-----------------------------------------------------------------
                    $FOLDERS = ("STEP 001 - TABLES", "STEP 002 - DATA", "STEP 003 - VIEWS", "STEP 004 - STOREDPROCS")
                    $i = 0
                    While ($i -lt $FOLDERS.count)
                    {
                    
                        [String]$Folder = $Folders[$i]
                        $TempFolder = $Global:FilePath, $Folder -join "\"
                        #--------------------------------------------
                        #Output the List of Files in Each folder
                        #--------------------------------------------
                            if (Test-path $tempFolder)
                            {
                                $ListOfFiles = Get-ChildItem -path $TempFolder -Filter "*.sql" | Sort-Object NAME
                                #gci . | ? { $_.PSIsContainer } | sort CreationTime | select name
                                forEach ($item in $ListOfFiles)
                                {
                                   $FullFileName = $TempFolder,$item.name -join "\"
                                   "------------------" | Write-Verbose
                                   $pDatabaseName, $pServerName -join " - " | Write-Verbose
                                   $FullFileName | Write-Verbose
                                   $item.name    | Write-Verbose
                                   "------------------" | Write-Verbose
                                   $CmdResult = Invoke-Sqlcmd -ServerInstance $pServerName -Database $pDatabaseName -InputFile $FullFileName 
                                }
                            }
                        $i++
                    }
    
    
        }
        CATCH 
        {
	        $errMsg = $PSitem.exception.message
            $errMsg = "<BR>GET Clients Failed: <BR>$errMsg"
            THROW $errMsg
	    }
				
    }

#------------------------------
#  __  __   _   ___ _  _ 
# |  \/  | /_\ |_ _| \| |
# | |\/| |/ _ \ | || .` |
# |_|  |_/_/ \_\___|_|\_|
#------------------------------

TRY
{

#-------------------------------------------------------
#Prompt the User  ***********************
#-------------------------------------------------------
    "You will be Prompted to Enter the SERVER-DATABASES:" | Write-Warning
    $ListOfServerAndDBs = Read-Host -Prompt "Please Enter List of Server-Databases (comma de-limited) to deploy to (i.e. Server, Database)?"  	

#-------------------------------------------------------
#Split the List of Databases into a Clean Array and Load 
#-------------------------------------------------------    
    $ListArray = $ListOfServerAndDBs.Split([environment]::NewLine)
    [string]$server = ""
    [string]$database = ""
    [string]$msg = ""
    

    cls
    forEach ($a in $ListArray)
    {
        
        
        $SingleItem = $a.Split(",")
        $server = $SingleItem[0]
        $database= $SingleItem[1]
        $server = $server.trim()
        $database = $database.trim()

        #-----------------------------
        #VERIFY DATA WAS ENTERED
        #-----------------------------
                IF ($server   -eq $NULL) 
                {
                        $msg = "ServerName missing"   
                        #BREAK
                }
                IF ($server   -eq ""   ) 
                {
                        $msg = "ServerName Empy"    
                        #BREAK
                }
                IF ($database -eq $NULL) 
                {
                        $msg = "Database   missing" 
                        #BREAK
                }
                IF ($database -eq ""   ) 
                {
                        $msg = "Database   Empty"   
                        #BREAK
                }

        #-----------------------------
        #ACTUAL DEPLOY
        #-----------------------------
               if (($server.Contains("DS-")) -or ($server.Contains("DC-")))
               {
                $server,$database -join " - "      | Write-Verbose
                DEPLOY-TODB -pServerName $server -pDatabaseName $database 
                }
                   
     
       }

 
#-------------------------------------------------------
#Concatenate Sub Folder to Directory
#-------------------------------------------------------
    
    
}
CATCH
{
    "*******CATCH STATEMENT******" | Write-Verbose
    if ($psitem.exception -ne $null){$errMsg = $PSitem.exception.message}
    if ($errMsg -ne $null)          {$errMsg      | Write-Warning }
    if ($Folder -ne $null)          {$Folder      | Write-Warning }
    if ($TempFolder -ne $null)      {$TempFolder  | Write-Warning }
    if ($server -ne $null)          {$Server      | write-warning }
    if ($server -ne $null)          {$database    | Write-Warning }
    if ($fullFileName -ne $null)    {$fullFileName| Write-Warning }
    "*******CATCH STATEMENT******" | Write-Verbose


}

#cls