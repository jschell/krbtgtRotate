function Invoke-KrbtgtPasswordRotate 
{
<#
.SYNOPSIS
Invoke-KrbtgtPasswordRotate is the controller function that orchestrates rotating
the krbtgt password in a safe manner.

.DESCRIPTION
Invoke-KrbtgtPasswordRotate manages the orchestration of the validation, sync,
rotation and logging of rotating the krbtgt account password. The primary goal of
the function is to rotate the password without impacting existing kerberos ticket
holders. This is accomplished by waiting between rotations a minimum amount of time,
equal or greater than the lifetime of the kerberos ticket plus twice the allowed 
clock skew. 
The krbtgt account is aware of the current and one prior password, using the current
password to generate the TGT. A ticket issued under password`0 would be valid for
one rotation - password`1. If the password was to be rotated again (to password`2) 
while tickets issued under password`0 were still valid, the tickets issued under 
password`0 would no longer be accepted. The krbtgt account would only recognize 
tickets issued by the current (password`2) and prior (password`1).
By waiting for the ticket lifetime (default 10 hours) to expire, and allowing for
maximum clock skew at both the begining and end of the ticket lifetime period, the
krbtgt account password can be rotated in a manner that does not invalidate existing
tickets.

-Required modules
    ActiveDirectory 
    GroupPolicy

-Required functions
    (All public/ private functions in module)

-PS Script Analyzer exceptions 
    -PSAvoidGlobalVars - krbtgtRotate uses global variables to track the status of
    environmental conditions/ findings that will block success. This will be a 
    goal to remove in future iterations.

.PARAMETER krbtgtSamAccountName
Specifies samAccountName of the krbtgt account. Will be 'krbtgt', unless operating
against RODC.

.PARAMETER ComputerName
Specifies the Computer to operate against. Default will be PDCe, future versions 
will allow for targeting RODC.

.PARAMETER LogPath
Specifies path to the directory where the log will be created on disk.

.PARAMETER LogName
Specifies the event log that will be used to journal the progress of the rotation.

.PARAMETER SourceName
Specifies the source name that will be registered (if not already done) for the event log.

.PARAMETER Force
Switch parameter, allows bypass of confirm.

.EXAMPLE
PS > $paramKrbtgtInvokeExample = @{
    krbtgtSamAccountName = "krbtgt"
    computerName = "myPDC.contoso.com" 
    LogPath = "c:\logfiles\krbtgtRotate" 
    LogName = "Directory Service" 
    SourceName = "krbtgtRotate" 
    Force = $True
}
PS > Invoke-KrbtgtPasswordRotate @paramKrbtgtInvokeExample

Description
-----------
The invocation above will attempt to rotate the krbtgt user object password once, 
logging the results to the specified folder and the 'Directory Service' event log.

.EXAMPLE
PS > Invoke-KrbtgtPasswordRotate -Force

Description
-----------
The command will attempt to rotate the krbtgt user object password once using the
default parameter values.

.INPUTS
System.String

.OUTPUTS
None

.LINK
about_comment_based_help

.NOTES

#### Name:      Invoke-KrbtgtPasswordRotate
#### Author:    J Schell
#### Version:   0.3.1
#### License:   MIT License

### ChangeLog

##### 2017-03-23::0.3.1
- script analyzer fixes
- updated description with required modules, functions, reason for PSSA exceptions

##### 2017-01-23::0.3.0
- filling out comment based help
- moving open brace to next line (style)

##### 2016-09-21::0.2.0
- rework of several pieces, bumping to v0.2.0 for module
- log update
    was:Microsoft-Windows-Kerberos/Operational
    now:Directory Service
- remove ad,gp module check - module will not load w/o, redundant
- update global var to properly ref global status
- insert eventLog hooks
- todo: sync logic needs to be shifted out to separate function, repeating work for pre/post

#### 2016-07-11::0.1.2
- added confirmImpact, accommodate if pre-PSv4 (use net.sockets test-port version)

#### 2016-07-05::0.1.1
- flesh out helper scripts

#### 2016-06-28::0.1.0
- initial creation, inspired by technet script [link]

#>


    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
    [CmdletBinding( SupportsShouldProcess = $True,
        ConfirmImpact = "High" )]
    param
    (
        [Parameter( Mandatory = $False, 
            ValueFromPipeline = $True )]
        [String]
        $krbtgtSamAccountName = "krbtgt",
        
        [Parameter( Mandatory = $False, 
            ValueFromPipeline = $True )]
        [String]
        $ComputerName = (Get-ADDomain).PDCEmulator,
        
        [Parameter( Mandatory = $False, 
            ValueFromPipeline = $True )]
        [Alias("OutPath")]
        [String]
        $LogPath = $PWD,
        
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
        
        # [switch]$skipOnlineCheck,
        [switch]
        $Force
    )

    Begin 
    {    
        # $detailTime = [dateTime]::Now.ToString("o")
        $shortTime = [dateTime]::Now.ToString("s")
        $shortTimeFileFriendly = $shortTime.Replace(':','.')
        
        $InvocationStart = Get-Date
        New-Variable -Name "HaltingErrorCount" -Value 0 -Scope Global -Force
        # Global var to assist in logging
        
        New-Variable -Name "paramWriteLog" -Scope Global -Force
        $global:paramWriteLog = @{
            OutPath = $LogPath
            FileName = "$($shortTimeFileFriendly)-krbtgtRotate.txt"
            PassThru = $False
        }
        New-Variable -Name "paramWriteEvent" -Scope Global -Force
        $global:paramWriteEvent = @{
            LogName = $LogName
            SourceName = $SourceName
            ComputerName = $env:ComputerName
        }
        
        $PreReqCheck = New-Object -typeName PsObject ([ordered]@{
            InvocationStart = $InvocationStart
            EventLogStatus = ''
            Domain = ''
            DNSRoot = ''
            DFL = ''
            PDCEmulator = ''
            PDCEmulatorStatus = ''
            RWDCCount = ''
            KrbtgtPasswordLastSet = ''
            MinimumPasswordAge = ''
            KrbtgtPasswordCanRotate = ''
            InvokeAsAdmin = ''
        })
        
        $PreReqCheck.InvokeAsAdmin = Test-IsAdmin
        if( $($PreReqCheck.InvokeAsAdmin) -ne $True )
        {
            $msgInvokeAsAdminFalse = "The powershell session must be run in an elevated context. Current session is not running in an elevated context."
            Write-LogMessage -Message $msgInvokeAsAdminFalse -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
            Write-Error $msgInvokeAsAdminFalse
            $global:HaltingErrorCount++
        }
        
        # Register the module as event source
        $EventLogStatus = Register-KrbtgtEventLog -LogName $LogName -SourceName $SourceName -ComputerName $env:ComputerName
        $PreReqCheck.EventLogStatus = $EventLogStatus
        
        # Use Net.Sockets if Test-NetConnection not available
        if($PSVersionTable.PSVersion.Major -lt 4)
        {
            Set-Alias -name "Test-Port" -value "Test-PortTCP" -scope Global
            $msgUsingSocketsForPreV4PS = "Using Net.Sockets Test-Port invocation for pre-PSv4 supportability."
            Write-LogMessage -Message $msgUsingSocketsForPreV4PS -Caller "Invoke-KrbtgtPasswordRotate" @paramWriteLog
            Write-Verbose $msgUsingSocketsForPreV4PS
        }
        
        # Domain information
        $Domain = Get-ADDomain
        $DomainDNSName = $Domain.DNSRoot
        $DomainFunctionalLevel = $Domain.domainMode
        $PDCEmulator = $Domain.PDCEmulator
        $PreReqCheck.Domain = $($Domain.Name)
        $PreReqCheck.DNSRoot = $DomainDNSName
        $PreReqCheck.DFL = $DomainFunctionalLevel
        $PreReqCheck.PDCEmulator = $PDCEmulator
        
        if( ($DomainFunctionalLevel -match "windows2000") -OR 
            ($DomainFunctionalLevel -match "windows2003"))
        {
            $msgDFLTooOld = "Need to be DFL Windows2008 or later, DFL is `'$($DomainFunctionalLevel)`'"
            Write-LogMessage -Message $msgDFLTooOld -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
            Write-Error $msgDFLTooOld
            Write-KrbtgtEventLog -Message $msgDFLTooOld -Category "krbtgt" -MessageType "Error" @paramWriteEvent
            $global:HaltingErrorCount++
        }
        else 
        {
            $msgDomainDetails = @("Domain: $($Domain.Name) ")
            $msgDomainDetails += @("DNS root: $($DomainDNSName) ")
            $msgDomainDetails += @("PDCEmulator: $($PDCEmulator) ")
            $msgDomainDetails += @("DFL: $($DomainFunctionalLevel) ")
            Write-LogMessage -Message $msgDomainDetails -Caller "Invoke-KrbtgtPasswordRotate" @paramWriteLog
            Write-KrbtgtEventLog -Message $msgDomainDetails -Category "krbtgt" -MessageType "Information" @paramWriteEvent
        }

        # Validate PDCEmulator and ComputerName are the same
        if($PDCEmulator -notmatch $ComputerName)
        {
            $msgPDCEAndComputerNotMatch = "`'$($ComputerName)`' is not the PDCEmulator for $($DomainDNSName)."
            Write-LogMessage -Message $msgPDCEAndComputerNotMatch -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
            Write-Error $msgPDCEAndComputerNotMatch
            Write-KrbtgtEventLog -Message $msgPDCEAndComputerNotMatch -Category "online" -MessageType "Error" @paramWriteEvent
            $global:HaltingErrorCount++
        }
        
        # Validate PDCEmulator available
        if( !(Test-Port -ComputerName $PDCEmulator -CommonPort RPC,LDAP,ADWS -InfoVariable PDCEStatus) )
        {
            $PreReqCheck.PDCEmulatorStatus = $False
            $msgPDCEmulatorNotReachable = @("Could not reach the PDCEmulator on RPC, LDAP and ADWS ports.")
            $msgPDCEmulatorNotReachable += @( $($PDCEStatus.Tests) )
            Write-LogMessage -Message $msgPDCEmulatorNotReachable -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
            Write-Error $msgPDCEmulatorNotReachable
            Write-KrbtgtEventLog -Message $msgPDCEmulatorNotReachable -Category "online" -MessageType "warning" @paramWriteEvent
            $global:HaltingErrorCount++
        }
        else
        {
            $PreReqCheck.PDCEmulatorStatus = $True
            $msgPDCEmulatorStatus = @("PDCEmulator responded to connection tests.")
            $msgPDCEmulatorStatus += @( $($PDCEStatus.Tests) )
            Write-LogMessage -Message $msgPDCEmulatorStatus -Caller "Invoke-KrbtgtPasswordRotate" @paramWriteLog
            Write-Verbose ($msgPDCEmulatorStatus | Out-String)
            Write-KrbtgtEventLog -Message $msgPDCEmulatorStatus -Category "online" -MessageType "Information" @paramWriteEvent
        }
        
        # Writable domain controller enumeration
        $RWDC = @(($Domain.ReplicaDirectoryServers).Where({$_ -notlike "$PDCEmulator"}) | Sort-Object)
        if($RWDC.Count -lt 1)
        {
            $msgNoRWDCFoundInDomain = "No writable domain controllers found in addition to PDCEmulator."
            Write-LogMessage -Message $msgNoRWDCFoundInDomain -Caller "Invoke-KrbtgtPasswordRotate" -Category Warning @paramWriteLog
            Write-Warning $msgNoRWDCFoundInDomain
            # ? just rotate the pwd on pdcE
            $PDCEmulatorOnlyNoRWDC = $True
            $PreReqCheck.RWDCCount = 0
        }
        else 
        {
            $PreReqCheck.RWDCCount = $($RWDC.Count)
            $PDCEmulatorOnlyNoRWDC = $False
        }
        $msgRWDCCountToSync = "Found `'$($PreReqCheck.RWDCCount)`' Read Write Domain Controllers (not including the PDCEmulator)"
        Write-KrbtgtEventLog -Message $msgRWDCCountToSync -Category "sync" -MessageType "Information" @paramWriteEvent
        
        # Find krbtgt user object 
        $paramKrbtgtUser = @{
            Filter = "SamAccountName -eq `"$($krbtgtSamAccountName)`" "
            Property = "PasswordLastSet"
            Server = $ComputerName
        }
        $krbtgt = @(Get-ADUser @paramKrbtgtUser)
        if($krbtgt.count -ne 1)
        {
            $msgKrbtgtUserIssue = "Could not find expected krbtgt user: " +
                "`'$($krbtgtSamAccountName)`'. Validate samAccountName is correct."
            Write-LogMessage -Message $msgKrbtgtUserIssue -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
            Write-Error $msgKrbtgtUserIssue
            Write-KrbtgtEventLog -Message $msgKrbtgtUserIssue -Category "krbtgt" -MessageType "Error" @paramWriteEvent
            $global:HaltingErrorCount++
        }
        
        $krbtgtDN = $krbtgt.DistinguishedName
        $krbtgtPasswordLastSet = $krbtgt.PasswordLastSet
        $msgKrbtgtPasswordLastSet = "$($krbtgt.SamAccountName) password was last set: $($krbtgtPasswordLastSet.ToString())"
        Write-LogMessage -Message $msgKrbtgtPasswordLastSet -Caller "Invoke-KrbtgtPasswordRotate" @paramWriteLog
        Write-Verbose $msgKrbtgtPasswordLastSet
        Write-KrbtgtEventLog -Message $msgKrbtgtPasswordLastSet -Category "krbtgt" -MessageType "Information" @paramWriteEvent
        
        $PreReqCheck.KrbtgtPasswordLastSet = $krbtgtPasswordLastSet
        
        # Get TGT lifetime + skew (doubled)
        $tgtLifeAndSkewDbl = Get-KrbtgtPasswordMinimumAge
        $PreReqCheck.MinimumPasswordAge = $tgtLifeAndSkewDbl
        
        if( $krbtgtPasswordLastSet -lt ($InvocationStart - $tgtLifeAndSkewDbl) )
        {
            $msgKrbtgtPasswordAgeOK = "`'$($krbtgt.SamAccountName)`' password was set before $($tgtLifeAndSkewDbl.ToString()) ago."
            Write-LogMessage -Message $msgKrbtgtPasswordAgeOK -Caller "Invoke-KrbtgtPasswordRotate" @paramWriteLog
            Write-Verbose $msgKrbtgtPasswordAgeOK
            $PreReqCheck.KrbtgtPasswordCanRotate = $True
            Write-KrbtgtEventLog -Message $msgKrbtgtPasswordAgeOK -Category "krbtgt" -MessageType "Information" @paramWriteEvent    
        }
        else
        {
            $timeRemaining = ($krbtgtPasswordLastSet - ($InvocationStart - $tgtLifeAndSkewDbl)).toString()
            $msgKrbtgtPasswordAgeTooNew = "`'$($krbtgt.SamAccountName)`' password needs to age: $($timeRemaining)."
            Write-LogMessage -Message $msgKrbtgtPasswordAgeTooNew -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
            Write-Warning "Not enough time between last rotation! Time remaining: $($timeRemaining)"
            Write-KrbtgtEventLog -Message $msgKrbtgtPasswordAgeTooNew -Category "krbtgt" -MessageType "Warning" @paramWriteEvent
            $global:HaltingErrorCount++
            $PreReqCheck.KrbtgtPasswordCanRotate = $False
        }
        
        $GeneralStatus = New-Object -typeName PsObject ([ordered]@{
            InvocationStart = $InvocationStart
            Domain = $($Domain.Name)
            DFL = $DomainFunctionalLevel
            PDCEmulator = $PDCEmulator
            RWDCCount = $PreReqCheck.RWDCCount
            KrbtgtPasswordLastSet = $krbtgtPasswordLastSet
            PreRotateSyncComplete = $False
            PreRotateSyncCompleteTime = $null
            PreRotateSyncCompleteElapsed = $null
            KrbtgtPasswordRotate = $False
            PostRotateSyncComplete = $False
            PostRotateSyncCompleteTime = $null
            PostRotateSyncCompleteElapsed = $null
        })
        
        $msgHaltingErrorCount = "Number of Halting Errors: $($HaltingErrorCount)"
        Write-LogMessage -Message $msgHaltingErrorCount -Caller "Invoke-KrbtgtPasswordRotate" -Category Verbose @paramWriteLog
        Write-Verbose $msgHaltingErrorCount
        Write-LogMessage -Message $PreReqCheck -Caller "Invoke-KrbtgtPasswordRotate PreReqCheck" -Category Verbose @paramWriteLog
        Write-KrbtgtEventLog -Message ($PreReqCheck | Out-String ) -Category "krbtgt" -MessageType "Information" @paramWriteEvent
        
    }#EndOfBegin
    Process 
    {
        if($global:HaltingErrorCount -gt 0)
        {
            $msgTooManyError = "Halting error(s) have been observed. Please review log and correct before running again."
            Write-LogMessage -Message $msgTooManyError -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
            Write-KrbtgtEventLog -Message $msgTooManyError -Category "krbtgt" -MessageType "Error" @paramWriteEvent
            Throw $msgTooManyError
        }
        
        $RWDCCollection = @()
        
        # If there are one or more (non-pdcE) RWDC, run the section below
        if( !($PDCEmulatorOnlyNoRWDC) )
        {
            # RWDC - Connection test, validate RPC, LDAP and ADWS ports are open
            foreach($domainController in $RWDC)
            {
                $RWDCMember = New-Object -typeName PsObject -property ([ordered]@{
                    ComputerName = $domainController
                    ComputerNameShort = $domainController.Split('.')[0]
                    Online = $False
                    ConnectionTest = $null
                    PreRotateSync = $False
                    PreRotateSyncAttemptNumber = $null
                    PreRotateSyncTime = $null
                    PostRotateSync = $False
                    PostRotateSyncAttemptNumber = $null
                    PostRotateSyncTime = $null
                })
                
                # Validate connectivity, attempt up to 60 times (5min)
                $ConnectionTestAttempt = 0
                Do 
                {
                    $ConnectionTestAttempt++
                    $ConnectionTestStatus = $null
                    $DCCheck = Test-Port -ComputerName $DomainController -CommonPort RPC,LDAP,ADWS -InfoVariable DCStatus
                    Start-Sleep -Seconds 5
                    if($ConnectionTestAttempt -ge 60) 
                    {
                        $msgConnectionTestAttemptFailure = "$($DomainController) not available within alloted time."
                        Write-LogMessage -Message $msgConnectionTestAttemptFailure -Caller "Invoke-KrbtgtPasswordRotate Test-Port" -Category Error @paramWriteLog
                        Write-Error $msgConnectionTestAttemptFailure
                        Write-KrbtgtEventLog -Message $msgConnectionTestAttemptFailure -Category "online" -MessageType "warning" @paramWriteEvent
                        $ConnectionTestStatus = $False
                    }
                }
                While( ($DCCheck -ne $True) -AND ($ConnectionTestStatus -ne $False) )
                
                $msgConnectTestSuccess = "$($DomainController) responded to port checks for RPC, LDAP, ADWS."
                Write-KrbtgtEventLog -Message $msgConnectTestSuccess -Category "online" -MessageType "Information" @paramWriteEvent
                $RWDCMember.Online = $DCCheck
                $RWDCMember.ConnectionTest = $DCStatus.Tests
                $RWDCCollection += @( $RWDCMember )
            }
            
            if($RWDCCollection.Value.Online -contains $False)
            {
                $global:HaltingErrorCount++
                $msgConnectionTestFailure = "One or more domain controllers could not be validated as online."
                Write-LogMessage -Message $msgConnectionTestFailure -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
                Write-Error $msgConnectionTestFailure
            }
            if($global:HaltingErrorCount -gt 0)
            {
                $msgTooManyError = "Halting error(s) have been observed. Please review log and correct before running again."
                Write-LogMessage -Message $msgTooManyError -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
                Throw $msgTooManyError
            }    
            
            # RWDC - Pre-Rotate Sync
            foreach($domainController in $RWDC)
            {
                $RWDCMember = $RWDCCollection | Where-Object {$_.ComputerName -eq $domainController}
                $InvocationSyncTime = Get-Date
                
                $PreRotateSyncAttemptMaximum = 20
                $PreRotateSyncAttemptNumber = 0
                Do 
                {
                    $PreRotateSyncAttemptNumber++
                    Try 
                    {
                        Sync-ADObject -Object $krbtgtDN -Source $PDCEmulator -Destination $domainController
                        $PreRotateSync = $True
                        $msgPreRotateSyncSuccess = "Successful sync of $($krbtgtDN) from $($PDCEmulator) to $($domainController)"
                        Write-KrbtgtEventLog -Message $msgPreRotateSyncSuccess -Category "sync" -MessageType "Information" @paramWriteEvent
                    }
                    Catch [Microsoft.ActiveDirectory.Management.AdException] 
                    {
                        if($_.fullyQualifiedErrorId -like "*8344*") 
                        {
                            $msgSyncInsufficientRights = "Insufficient access rights to perform operation."
                            Write-LogMessage -Message $msgSyncInsufficientRights -Caller "Invoke-KrbtgtPasswordRotate Pre-Rotate Sync" -Category Warning @paramWriteLog
                            Write-Warning $msgSyncInsufficientRights
                            $PreRotateSync = $False
                        }
                        else 
                        {
                            $msgSyncOtherError = "Other AD module error encountered..." + "$_"
                            Write-LogMessage -Message $msgSyncOtherError -Caller "Invoke-KrbtgtPasswordRotate Pre-Rotate Sync" -Category Warning @paramWriteLog
                            Write-Warning $msgSyncOtherError
                            $PreRotateSync = $False
                        }
                    }
                    Catch 
                    {
                        $msgSyncGeneralError = "Other error encountered on sync..." + "$_"
                        Write-LogMessage -Message $msgSyncGeneralError -Caller "Invoke-KrbtgtPasswordRotate Pre-Rotate Sync" -Category Warning @paramWriteLog
                        Write-Warning $msgSyncGeneralError
                        $PreRotateSync = $False
                    }
                    Start-Sleep -Seconds 5
                    if($PreRotateSyncAttemptNumber -ge $PreRotateSyncAttemptMaximum)
                    {
                        $msgSyncAttemptFailure = "$($DomainController) did not sync in alloted time."
                        Write-LogMessage -Message $msgSyncAttemptFailure -Caller "Invoke-KrbtgtPasswordRotate Pre-Rotate Sync" -Category Error @paramWriteLog
                        Write-Error $msgSyncAttemptFailure
                        Write-KrbtgtEventLog -Message $msgSyncAttemptFailure -Category "sync" -MessageType "Warning" @paramWriteEvent
                        $PreRotateSync = $False
                    }
                }
                While( ($PreRotateSync -eq $False) -AND ($PreRotateSyncAttemptNumber -le $PreRotateSyncAttemptMaximum) ) 
                
                $RWDCMember.PreRotateSync = $PreRotateSync
                $RWDCMember.PreRotateSyncAttemptNumber = $PreRotateSyncAttemptNumber
                $RWDCMember.PreRotateSyncTime = $InvocationSyncTime
            }
            
            if($RWDCCollection.Value.PreRotateSync -contains $False)
            {
                $global:HaltingErrorCount++
                $msgPreRotateSyncFailure = "One or more domain controllers could not sync before the password rotation."
                Write-LogMessage -Message $msgPreRotateSyncFailure -Caller "Invoke-KrbtgtPasswordRotate Pre-Rotate Sync" -Category Error @paramWriteLog
                Write-Error $msgPreRotateSyncFailure
                Write-KrbtgtEventLog -Message $msgPreRotateSyncFailure -Category "sync" -MessageType "Error" @paramWriteEvent
            }
            else 
            {
                $PreRotateSyncCompleteTime = Get-Date
                $GeneralStatus.PreRotateSyncComplete = $True
                $GeneralStatus.PreRotateSyncCompleteTime = $PreRotateSyncCompleteTime
                $FirstPreRotateSync = $RWDCCollection.PreRotateSyncTime | 
                    Sort-Object | Select-Object -First 1
                $GeneralStatus.PreRotateSyncCompleteElapsed = $PreRotateSyncCompleteTime - $FirstPreRotateSync
                $msgPreRotateSyncComplete = "Pre-Rotate sync completed in $($GeneralStatus.PreRotateSyncCompleteElapsed.ToString())"
                Write-KrbtgtEventLog -Message $msgPreRotateSyncComplete -Category "sync" -MessageType "SuccessAudit" @paramWriteEvent
            }
            if($global:HaltingErrorCount -gt 0)
            {
                $msgTooManyError = "Halting error(s) have been observed. Please review log and correct before running again."
                Write-LogMessage -Message $msgTooManyError -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
                Throw $msgTooManyError
            }
        }
        
        # Actual rotation of krbtgt password
        if($Force -OR $psCmdlet.ShouldProcess("$($krbtgtDN)", "Set-KrbtgtPassword") ) {
            $TempKrbtgtPassword = New-ComplexPassword -PasswordLength 30 -User $($krbtgt.SamAccountName)
            $RotateKrbtgt = Set-KrbtgtPassword -Password $TempKrbtgtPassword -User $krbtgtDN -Server $PDCEmulator
            if( !($RotateKrbtgt) )
            {
                $msgKrbtgtPasswordRotatedFailure = "Failed to set the password for $($krbtgtDN)"
                Write-KrbtgtEventLog -Message $msgKrbtgtPasswordRotatedFailure -Category "krbtgtsinglereset" -MessageType "FailureAudit" @paramWriteEvent
                $global:HaltingErrorCount++
            }
            else 
            {
                $GeneralStatus.KrbtgtPasswordRotate = $True
                $msgKrbtgtPasswordRotatedSuccess = "Successfully rotated the password for $($krbtgt.SamAccountName)."
                Write-LogMessage -Message $msgKrbtgtPasswordRotatedSuccess -Caller "Invoke-KrbtgtPasswordRotate Rotated" -Category Verbose @paramWriteLog
                Write-Verbose $msgKrbtgtPasswordRotatedSuccess
                Write-KrbtgtEventLog -Message $msgKrbtgtPasswordRotatedSuccess -Category "krbtgtsinglereset" -MessageType "SuccessAudit" @paramWriteEvent
            }
            if($global:HaltingErrorCount -gt 0)
            {
                $msgTooManyError = "Halting error(s) have been observed. Please review log and correct before running again."
                Write-LogMessage -Message $msgTooManyError -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
                Throw $msgTooManyError
            }
        }
        
        # Start the post-rotation sync only if Krbtgt has been rotated (skip if only -WhatIf)
        if( !($PDCEmulatorOnlyNoRWDC) -AND ($RotateKrbtgt) )
        {
            # RWDC - Post-Rotate Sync
            foreach($domainController in $RWDC)
            {
                $RWDCMember = $RWDCCollection | Where-Object {$_.ComputerName -eq $domainController}
                $InvocationSyncTime = Get-Date
                
                $PostRotateSyncAttemptMaximum = 60
                $PostRotateSyncAttemptNumber = 0
                Do 
                {
                    $PostRotateSyncAttemptNumber++
                    Try 
                    {
                        Sync-ADObject -Object $krbtgtDN -Source $PDCEmulator -Destination $domainController
                        $PostRotateSync = $True
                        $msgPostRotateSyncSuccess = "Successful sync of $($krbtgtDN) from $($PDCEmulator) to $($domainController)"
                        Write-KrbtgtEventLog -Message $msgPostRotateSyncSuccess -Category "sync" -MessageType "Information" @paramWriteEvent
                    }
                    Catch [Microsoft.ActiveDirectory.Management.AdException] 
                    {
                        if($_.fullyQualifiedErrorId -like "*8344*") 
                        {
                            $msgSyncInsufficientRights = "Insufficient access rights to perform operation."
                            Write-LogMessage -Message $msgSyncInsufficientRights -Caller "Invoke-KrbtgtPasswordRotate Post-Rotate Sync" -Category Warning @paramWriteLog
                            Write-Warning $msgSyncInsufficientRights
                            $PostRotateSync = $False
                        }
                        else 
                        {
                            $msgSyncOtherError = "Other AD module error encountered..." + "$_"
                            Write-LogMessage -Message $msgSyncOtherError -Caller "Invoke-KrbtgtPasswordRotate Post-Rotate Sync" -Category Warning @paramWriteLog
                            Write-Warning $msgSyncOtherError
                            $PostRotateSync = $False
                        }
                    }
                    Catch 
                    {
                        $msgSyncGeneralError = "Other error encountered on sync..." + "$_"
                        Write-LogMessage -Message $msgSyncGeneralError -Caller "Invoke-KrbtgtPasswordRotate Post-Rotate Sync" -Category Warning @paramWriteLog
                        Write-Warning $msgSyncGeneralError
                        $PostRotateSync = $False
                    }
                    Start-Sleep -Seconds 5
                    if($PostRotateSyncAttemptNumber -ge $PostRotateSyncAttemptMaximum)
                    {
                        $msgSyncAttemptFailure = "$($DomainController) did not sync in alloted time."
                        Write-LogMessage -Message $msgSyncAttemptFailure -Caller "Invoke-KrbtgtPasswordRotate Post-Rotate Sync" -Category Error @paramWriteLog
                        Write-Error $msgSyncAttemptFailure
                        Write-KrbtgtEventLog -Message $msgSyncAttemptFailure -Category "sync" -MessageType "Warning" @paramWriteEvent
                        $PostRotateSync = $False
                    }
                }
                While( ($PostRotateSync -eq $False) -AND ($PostRotateSyncAttemptNumber -le $PostRotateSyncAttemptMaximum) ) 
                
                $RWDCMember.PostRotateSync = $PostRotateSync
                $RWDCMember.PostRotateSyncAttemptNumber = $PostRotateSyncAttemptNumber
                $RWDCMember.PostRotateSyncTime = $InvocationSyncTime
            }
            
            if($RWDCCollection.PostRotateSync -contains $False)
            {
                $global:HaltingErrorCount++
                $msgPostRotateSyncFailure = "One or more domain controllers could not sync before the password rotation."
                Write-LogMessage -Message $msgPostRotateSyncFailure -Caller "Invoke-KrbtgtPasswordRotate Post-Rotate Sync" -Category Error @paramWriteLog
                Write-Error $msgPostRotateSyncFailure
            }
            else 
            {
                $PostRotateSyncCompleteTime = Get-Date
                $GeneralStatus.PostRotateSyncComplete = $True
                $GeneralStatus.PostRotateSyncCompleteTime = $PostRotateSyncCompleteTime
                $FirstPostRotateSync = $RWDCCollection.PostRotateSyncTime | Sort-Object | Select-Object -First 1
                $GeneralStatus.PostRotateSyncCompleteElapsed = $PostRotateSyncCompleteTime - $FirstPostRotateSync
                $msgPostRotateSyncComplete = "Post-Rotate sync completed in $($GeneralStatus.PostRotateSyncCompleteElapsed.ToString())"
                Write-KrbtgtEventLog -Message $msgPostRotateSyncComplete -Category "sync" -MessageType "SuccessAudit" @paramWriteEvent
            }
            if($global:HaltingErrorCount -gt 0)
            {
                $msgTooManyError = "Halting error(s) have been observed. Please review log and correct before running again."
                Write-LogMessage -Message $msgTooManyError -Caller "Invoke-KrbtgtPasswordRotate" -Category Error @paramWriteLog
                Throw $msgTooManyError
            }
        }
        $msgInvokeKrbtgtPasswordRotateComplete = "Password rotation completed!"
        Write-LogMessage -Message $msgInvokeKrbtgtPasswordRotateComplete -Caller "Invoke-KrbtgtPasswordRotate Complete" -Category Verbose @paramWriteLog
        Write-Verbose $msgInvokeKrbtgtPasswordRotateComplete
        Write-LogMessage -Message $GeneralStatus -Caller "Invoke-KrbtgtPasswordRotate GeneralStatus" @paramWriteLog
        Write-KrbtgtEventLog -Message ($GeneralStatus | Out-String ) -Category "krbtgt" -MessageType "SuccessAudit" @paramWriteEvent
    }#EndOfProcess

}