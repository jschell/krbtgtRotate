#Requires -modules ActiveDirectory
function Set-KrbtgtPassword {
<#
.SYNOPSIS
Set the password for the krbtgt user.

.DESCRIPTION
Sets the password for the krbtgt user temporarily, the system will automatically 
rotate this password on change. This function exists only to trigger the change 
and to meet the domain environment requirements.

-Required modules
    ActiveDirectory 

-Required functions
    Write-LogMessage

-PS Script Analyzer exceptions 
    -PSAvoidUsingPlainTextForPassword - In order to evaluate the password for 
    complexity and pattern matching, it must be in plain text.
    -PSAvoidUsingConvertToSecureStringWithPlainText - In order to use the password
    which has been evaluated for complexity, length and overall compliance with
    domain policy, plain text (which must be changed to a secure string) is used.
    -PSAvoidUsingUserNameAndPassWordParams - Because both the user object and 
    password are being evaluated (complexity check), using descriptive parameters
    is better than using compliant albeit vague or misleading names.
    -PSUseShouldProcessForStateChangingFunctions - There is a 'ShouldProcess' 
    gate at the meta function (Invoke-KrbtgtRotate) that calls this function.

.PARAMETER Password
Specifies the string to be used for setting the krbtgt account password.

.PARAMETER User
Specifies the user account to where the password will be changed; default is 'krbtgt'.

.PARAMETER Server
Specifies the domain controller that should be the target for setting the password.
Default is the PDCEmulator.

.PARAMETER Credential
Specifies the credentials to use when setting the password; optional.

.EXAMPLE
PS > Set-KrbtgtPassword -Password "SuperComplex!Password1" -User krbtgt -Server DC01.contoso.com

True

Description
-----------
The boolean value returned indicates the success (or failure) of the action. 
In the example above, the rotation succeeded.

.EXAMPLE
PS > Set-KrbtgtPassword -Password "SuperComplex!Password1"

True

Description
-----------
The boolean value returned indicates the success (or failure) of the action. 
In the example above, the rotation succeeded. Using the default parameter values
for 'User' and 'Server'.

.INPUTS
System.String, System.Management.Automation.PSCredential

.OUTPUTS
System.Bool

.LINK
about_comment_based_help

.Notes

#### Name:      Set-KrbtgtPassword
#### Author:    J Schell
#### Version:   0.2.3
#### License:   MIT License

### ChangeLog

##### 2017-03-23::0.2.3
-description for PSSA rule exceptions

##### 2017-03-22::0.2.2
-more suppressed PSSA rules
-silly attribute games on 'Credential' parameter to satisfy PSSA 

##### 2017-03-21::0.2.1
-proper help added
-added exception to PSScriptAnalyzer rules 

##### 2016-09-21::0.2.0
-rework of several pieces, bumping to v0.2.0 for module

##### 2016-07-05::0.1.0
-initial creation
#>


    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPasswordParams", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter( Mandatory = $True )]
        [string]
        $Password,
        
        [Parameter( Mandatory = $False )]
        [string]
        $User = "krbtgt",
        
        [Parameter( Mandatory = $False )]
        [string]
        $Server = (Get-ADDomain).PDCEmulator,
        
        [Parameter( Mandatory = $False )]
        [PSCredential] 
        [System.Management.Automation.Credential()]
        $Credential
    )
    
    Begin 
    {
        Try 
        {
            $UserObject = Get-AdUser $User
        }
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] 
        {
            $msgUserNotFound = "No matches found for $($User)"
            Write-LogMessage -Message $msgUserNotFound -Caller "Set-KrbtgtPassword" -Category Error @paramWriteLog
            Write-Warning $msgUserNotFound
            Return $False
        }
        Try 
        {
            $ServerObject = get-adDomainController $Server
        }
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] 
        {
            $msgServerNotFound = "No matches found for $($Server) (as a domain controller)."
            Write-LogMessage -Message $msgServerNotFound -Caller "Set-KrbtgtPassword" -Category Error @paramWriteLog
            Write-Warning $msgServerNotFound
            Return $False
        }
        $PasswordAsSecureString = ConvertTo-SecureString $Password -AsPlainText -Force
        $rotatePasswordParam = @{
            Identity = $UserObject
            Server = $ServerObject
            Reset = $True
            NewPassword = $PasswordAsSecureString
        }
        if($Credential)
        {
            $rotatePasswordParam += @{ Credential = $Credential }
        }
    }
    Process 
    {
        Try 
        {
            Set-ADAccountPassword @rotatePasswordParam
        }
        Catch [System.UnauthorizedAccessException] 
        {
            if( $_.CategoryInfo -like "*PermissionDenied*" )
            {
                $msgPermissionDenied = "Failed to reset password for $($User). Insufficient permissions."
                Write-LogMessage -Message $msgPermissionDenied -Caller "Set-KrbtgtPassword" -Category Error @paramWriteLog
                Write-Warning $msgPermissionDenied
                Return $False
            }
            else 
            {
                $msgUnauthorizedOther = "Failed to reset password for $($User). Unauthorized Access (other). $_"
                Write-LogMessage -Message $msgUnauthorizedOther -Caller "Set-KrbtgtPassword" -Category Error @paramWriteLog
                Write-Warning $msgUnauthorizedOther
                Return $False
            }
        }
        Catch 
        {
            $msgFailureCatchAll = "Failed to reset password for $($User). Failure caught: $_"
            Write-LogMessage -Message $msgFailureCatchAll -Caller "Set-KrbtgtPassword" -Category Error @paramWriteLog
            Write-Warning $msgFailureCatchAll
            Return $False
        }    
        Return $True
    }
}