function Register-KrbtgtEventLog 
{
<#
.SYNOPSIS
This function registers the krbtgtRotate module with the specified event log, to
be used while the krbtgt account password is being rotated.

.DESCRIPTION
In addition to on disk logging, the use of event logs allows for downstream 
consumers (SCOM, OMS, etc...) to parse and take action if necessary. Registering
as a source allows for capturing the state of the operation as it progresses.

-Required modules
    None

-Required functions
    Write-LogMessage

-PS Script Analyzer exceptions 
    -PSAvoidGlobalVars - krbtgtRotate uses global variables to track the status of
    environmental conditions/ findings that will block success. This will be a 
    goal to remove in future iterations.


.PARAMETER LogName
Specifies the name of the event log to register against.

.PARAMETER SourceName
Specifies the name of the source that will be registered with the event log.

.PARAMETER ComputerName
Specifies the name of the computer where the event log resides. Use caution when
specifying *other* than localhost.

.EXAMPLE
PS > Register-KrbtgtEventLog -LogName "Directory Service" -SourceName krbtgtRotation -ComputerName $env:ComputerName

True

Description
-----------
The event log 'Directory Service' will now accept new events from the source 'krbtgtRotation' 
on the localhost.

.EXAMPLE
PS > Register-KrbtgtEventLog

True

Description
-----------
Using the default parameter values, the event log 'Directory Service' will now
accept new events from the source 'krbtgtRotation' on the localhost.

.INPUTS
System.String

.OUTPUTS
System.Boolean

.NOTES

#### Name:      Register-KrbtgtEventLog
#### Author:    J Schell
#### Version:   0.3.1
#### License:   MIT License

### ChangeLog

##### 2017-03-23::0.3.1
-PSSA rule exceptions

##### 2017-01-24::0.3.0
- filling out comment based help
- moving open brace to next line (style)
- trim dead sections (commented out)

##### 2016-09-21::0.2.0
- rework of several pieces, bumping to v0.2.0 for module
- log update
    was: 'Microsoft-Windows-Kerberos/Operational'
    now: 'Directory Service'
- pull section that sets event log size, if it isn't there/ wrong size, do it external
- update with increment haltingErrorCount

##### 2016-07-11::0.1.4
- updated to include 'write-logMessage'
- updated to support 'shouldProcess' and 'confirmImpact'

##### 2016-07-07::0.1.3
- dropped 'get-eventLog' from query, 'get-winEvent' works for classic and current
- added status checks for if log exist, if source registered
- updated default log to kerb/ops
- updated verb to 'register' from 'new'

##### 2016-07-06::0.1.2
- allow new style event logs (ETW) to be used, query uses 'get-winEvent' vs. 'get-eventLog'
- add computerName param
- handle access denied during eventLog enum

##### 2016-07-05::0.1.1
- logic around restart required (or not) for new event log

##### 2016-07-05::0.1.0
- initial creation
- pulling out as separate function from rest of logic

#>    


    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
    [CmdletBinding( SupportsShouldProcess = $True,
        ConfirmImpact = "Medium" )]
    [OutputType([Bool])]
    Param
    (
        [Parameter( Mandatory = $False, 
            ValueFromPipeline = $True )]
        [Alias("Name","Log")]
        [String]
        $LogName = "Directory Service",
        
        [Parameter( Mandatory = $False, 
            ValueFromPipeline = $True )]
        [Alias("Source")]
        [String]
        $SourceName = "krbtgtRotation",
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [String]
        $ComputerName = $env:ComputerName
    )
    
    Begin 
    {
        $paramFindLog = @{
            ListLog = "*"
            ComputerName = $ComputerName
            ErrorAction = "SilentlyContinue"
        }
    
        if( (Get-WinEvent @paramFindLog ).Where({$_.logName -eq $LogName}) )
        {
            $EventLogExist = $True
            $msgEventLogExists = "$($LogName) exists"
            Write-LogMessage -Message $msgEventLogExists -Caller "Register-KrbtgtEventLog" -Category Verbose @paramWriteLog
            Write-Verbose $msgEventLogExists
        }
        else 
        {
            $global:HaltingErrorCount++
            $EventLogExist = $False
            $msgEventLogDoesNotExist = "$($LogName) does not yet exist, system will " +
                "require restart after log is created for events to be properly logged."
            Write-LogMessage -Message $msgEventLogDoesNotExist -Caller "Register-KrbtgtEventLog" -Category Error @paramWriteLog
            Write-Error $msgEventLogDoesNotExist
        }
    }
    
    Process 
    {
        Try 
        {
            New-EventLog -LogName $LogName -Source $SourceName -ComputerName $ComputerName -ErrorAction SilentlyContinue
            $EventSourceRegistered = $True
        }
        Catch [System.Exception] 
        {
            if( $_.Exception.Message -like "*source is already registered on the*")
            {
                $EventSourceRegistered = $True
                $msgAlreadyRegistered = "$($LogName) Log and $($SourceName) Source already configured."
                Write-LogMessage -Message $msgAlreadyRegistered -Caller "Register-KrbtgtEventLog" -Category Verbose @paramWriteLog
                Write-Verbose $msgAlreadyRegistered
            }
            if( $_.FullyQualifiedErrorID -like "*AccessIsDenied*" )
            {
                $global:HaltingErrorCount++
                $EventSourceRegistered = $False
                $msgNotRunningAsAdmin = "Must be run from elevated session."
                Write-LogMessage -Message $msgNotRunningAsAdmin -Caller "Register-KrbtgtEventLog" -Category Error @paramWriteLog
                Write-Error $msgNotRunningAsAdmin
                Return $False
            }
            else 
            {
                $exceptionCatch = $_ | Format-List * -Force | Out-String
                $global:HaltingErrorCount++
                $msgExceptionOther = "Exception encountered." +
                " `n$_ " + " `n $($exceptionCatch)"
                $EventSourceRegistered = $False
                Write-LogMessage -Message $msgExceptionOther -Caller "Register-KrbtgtEventLog" -Category Error @paramWriteLog
                Write-Error $msgExceptionOther
                Return $False
            }
        }
        Catch 
        {
            $global:HaltingErrorCount++
            $EventSourceRegistered = $False
            $msgErrorOther = "Unhandled exception caught. `n$_"
            Write-LogMessage -Message $msgErrorOther -Caller "Register-KrbtgtEventLog" -Category Error @paramWriteLog
            Write-Error $msgErrorOther
            Return $False
        }
        
        if( (Get-WinEvent @paramFindLog).Where({$_.logName -eq $LogName}) -AND 
            ($EventSourceRegistered) )
        {
            Return $True
        }
        else 
        {
            Return $False
        }
    }  
}