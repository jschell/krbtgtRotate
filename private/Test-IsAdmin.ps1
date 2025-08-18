function Test-IsAdmin {
<#
.SYNOPSIS
Test if the current session is elevated.

.DESCRIPTION
Test if the current session is elevated.

.EXAMPLE
PS > Test-IsAdmin

$True

Description
-----------
Returns value of 'True' because the session is an elevated session.

.EXAMPLE
PS > Test-IsAdmin

$False

Description
-----------
Returns value of 'False' because the session is not an elevated session.

.INPUTS
None

.OUTPUTS
System.Bool

.LINK
about_comment_based_help

.NOTES

#### Name:     Test-IsAdmin
#### Author:   J Schell
#### Version:  0.3.0
#### License:  MIT License

### Change Log

##### 2017-11-15::0.3.0
- updated to use well known SID rather than locale-specific (en-US) name
##### 2017-03-21::0.2.0
-proper help added

##### 2016-09-22::0.1.0
-initial create
-to validate session context for down level (pre-PSv4) systems
#>


    [CmdletBinding()]
    [OutputType([Bool])]
    Param()
    
    Process
    {
    
        $CurrentStatus = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
        # ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole( [Security.Principal.WindowsBuiltInRole] "Administrator")
        $CurrentStatus
    }
}
