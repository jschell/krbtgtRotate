function Get-KrbtgtPasswordMinimumAge 
{
<#
.SYNOPSIS
Gets the minimum age of the krbtgt account password.

.DESCRIPTION
Returns the minimum age of the krbtgt account password that will not cause service 
impact. Minimum age is determined by finding the Kerboros ticket lifetime in the 
default domain policy ( GUID:31B2F340-016D-11D2-945F-00C04FB984F9 ) as well as 
the maximum clock skew. Ticket lifetime plus twice the clock skew determines the 
minimum age of the krbtgt account password. GroupPolicy module is required.

.EXAMPLE
PS > Get-KrbtgtPasswordMinimumAge

Days              : 0
Hours             : 10
Minutes           : 10
Seconds           : 0
Milliseconds      : 0
Ticks             : 366000000000
TotalDays         : 0.423611111111111
TotalHours        : 10.1666666666667
TotalMinutes      : 610
TotalSeconds      : 36600
TotalMilliseconds : 36600000

Description
-----------
The object returned is a 'TimeSpan' type, showing the value of Kerboros ticket 
lifetime plus twice the allowed clock skew.

.EXAMPLE
PS > (Get-KrbtgtPasswordMinimumAge).totalMinutes

610

Description
--------
The returned object is the value of the property 'totalMinutes' of the Kerboros 
ticket lifetime plus twice the allowed clock skew.

.INPUTS
None

.OUTPUTS
System.TimeSpan

.NOTES

#### Name:      Get-KrbtgtPasswordMinimumAge
#### Author:    J Schell
#### Version:   0.3.0
#### License:   MIT License

### ChangeLog

##### 2017-01-23::0.3.0
- filling out comment based help
- moving open brace to next line (style)

##### 2016-09-21::0.2.0
- rework of several pieces, bumping to v0.2.0 for module
    
##### 2016-07-07::0.1.1
- adding central logging 

##### 2016-06-28::0.1.0 
- initial creation
#>


    [CmdletBinding()]
    [OutputType([TimeSpan])]
    Param( )
    
    Begin 
    {
        Try 
        {
            [xml]$DefaultAccountPolicy = Get-GPOReport -Guid '{31B2F340-016D-11D2-945F-00C04FB984F9}' -ReportType Xml
            $DefaultAccountPolicySecurity = $DefaultAccountPolicy.gpo.Computer.ExtensionData.Where( {$_.name -eq 'Security'} ).Extension.ChildNodes
            [int]$MaxTgtLifetimeHrs = $DefaultAccountPolicySecurity.Where( {$_.Name -eq 'MaxTicketAge'} ).SettingNumber
            [int]$MaxClockSkewMins  = $DefaultAccountPolicySecurity.Where( {$_.Name -eq 'MaxClockSkew'} ).SettingNumber
        }
        Catch 
        {
            $msgDefaultPolicyNotFound = "Could not resolve Default Account Policy, using " +
                "default out-of-the-box values. TGT Lifetime 10 hours, Clock Skew 5 minutes."
            Write-LogMessage -Message $msgDefaultPolicyNotFound -Caller "Get-KrbtgtPasswordMinimumAge" -Category Warning @paramWriteLog
            Write-Warning $msgDefaultPolicyNotFound
            [int]$MaxTgtLifetimeHrs = 10
            [int]$MaxClockSkewMins = 5
        }
        if( !($MaxTgtLifetimeHrs -ge 1) )
        {
            [int]$MaxTgtLifetimeHrs = 10
            $msgValidTGTLifetimeHrsAbsent = "Could not find valid TGT Lifetime, using default value of 10 hours."
            Write-LogMessage -Message $msgValidTGTLifetimeHrsAbsent -Caller "Get-KrbtgtPasswordMinimumAge" -Category Warning @paramWriteLog
            Write-Warning $msgValidTGTLifetimeHrsAbsent
        }
        if( !($MaxClockSkewMins -ge 1) )
        {
            [int]$MaxClockSkewMins = 5
            $msgValidClockSkewMinsAbsent = "Could not find valid Clock Skew, using default value of 5 minutes."
            Write-LogMessage -Message $msgValidClockSkewMinsAbsent -Caller "Get-KrbtgtPasswordMinimumAge" -Category Warning @paramWriteLog
            Write-Warning $msgValidClockSkewMinsAbsent
        }
    }

    Process
    {
        $tgtLifetimeAsTimespan = New-TimeSpan -Hours $MaxTgtLifetimeHrs
        $clockSkewAsTimespan = New-TimeSpan -Minutes $MaxClockSkewMins
        $clockSkewDoubleAsTimeSpan = $clockSkewAsTimespan + $clockSkewAsTimespan
        
        $msgTgtLifetime = "TGT Lifetime: $($tgtLifetimeAsTimespan.toString())"
        $msgClockSkewDouble = "Clock skew doubled: $($clockSkewDoubleAsTimeSpan.toString())"
        Write-LogMessage -Message $msgTgtLifetime -Caller "Get-KrbtgtPasswordMinimumAge" @paramWriteLog
        Write-LogMessage -Message $msgClockSkewDouble -Caller "Get-KrbtgtPasswordMinimumAge" @paramWriteLog
        
        $timeBetweenRotate = $tgtLifetimeAsTimespan + $clockSkewDoubleAsTimeSpan
        $msgTgtLifeAndSkewDbl = "Total minimum time between password rotations: $($timeBetweenRotate.toString())"
        Write-LogMessage -Message $msgTgtLifeAndSkewDbl -Caller "Get-KrbtgtPasswordMinimumAge" @paramWriteLog
        
        Return $timeBetweenRotate
    }
}