#Requires -modules ActiveDirectory
function Test-ComplexPassword {
<#

.SYNOPSIS
This function tests if a given string will meet the complexity requirements specified.

.DESCRIPTION
This function tests if the supplied string (password) will meet the password 
requirements of the current domain.

-Required modules
    ActiveDirectory 

-Required functions

-PS Script Analyzer exceptions 
    -PSAvoidUsingPlainTextForPassword - In order to evaluate the password for 
    complexity and pattern matching, it must be in plain text.
    -PSAvoidUsingUserNameAndPassWordParams - Because both the user object and 
    password are being evaluated (complexity check), using descriptive parameters
    is better than using compliant albeit vague or misleading names.

.PARAMETER Password
Specifies the password to test for complexity.

.PARAMETER User
Specifies the user (account) where the password will be set - evaluation of matching
characters in the password and SamAccountName.

.PARAMETER MinPasswordLength
Specifies the minimum password length, typically gathered from the current 
working domain.

.PARAMETER ComplexityEnabled
Specifies if complexity is enabled for passwords, typically gathered from the 
current working domain.

.PARAMETER CharTypeMinimum
Specifies the minimum number of different types of characters that must be present 
in the password under test.

.EXAMPLE
PS > Test-ComplexPassword -Password 'krbtgtPasswordSecret!1' -User krbtgt

WARNING: Password matches SamAccountName, not allowed when complexity enabled.
False

Description
-----------
Testing if the supplied password would be complex for the specified user, received
a warning and 'False' (failing) status returned. The failed status was because the
password had a match for the SamAccountName of the account specified.

.EXAMPLE
PS > Test-ComplexPassword -Password 'adminPasswordSecret!1' -User krbtgt

True

Description
--------
Testing if the supplied password would be complex for the specified user, result
was 'True' (passing). Because the password does not contain the SamAccountName and
matches 3 of the 5 character sets, result is passing.

.INPUTS
System.Int32, System.String, System.Bool

.OUTPUTS
System.Bool

.LINK
https://technet.microsoft.com/en-us/library/cc786468.aspx

.LINK
https://technet.microsoft.com/en-us/library/hh994562.aspx

.LINK
https://msdn.microsoft.com/en-us/library/cc875839.aspx

.Notes

#### Name:       Test-ComplexPassword
#### Author:     J Schell
#### Version:    0.2.1
#### License:    MIT

### Change Log

##### 2017-03-23::0.2.2
-parameter 'ComplexityTypeMinimum' is now 'CharTypeMinimum'
-moved evaluation of default domain policy out of parameter section into 'begin'
-now evaluating *all* the rules for complexity - displayName matching rules now
tested.

##### 2017-03-21::0.2.1
- proper help added
- added exception to PSScriptAnalyzer rules 

##### 2016-09-21::0.2.0
- rework of several pieces, bumping to v0.2.0 for module

##### 2016-09-20::0.1.2
- update verbose message returned

##### 2016-07-05::0.1.1
- updated to allow minPasswordLength, complexityEnabled, and CharTypeMinimum from pipeline

##### 2016-06-29::0.1.0
- initial creation

#>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "")]
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter( Mandatory = $True,
            ValueFromPipeline = $True )]
        [string] 
        $Password,
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [string]
        [Microsoft.ActiveDirectory.Management.ADUser]
        $User,
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [int]
        $MinPasswordLength,
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [Bool]
        $ComplexityEnabled,
        
        [Parameter( Mandatory = $False, 
            ValueFromPipeline = $True )]
        [ValidateRange(1,5)]
        [int]
        $CharTypeMinimum
    )
    
    Begin 
    {
        $asciiUpper = '[A-Z]'
        $asciiLower = '[a-z]'
        $baseTen = '[0-9]'
        $topRow = '[\~!@#$%^&*_\-+=`|\\(){}\[\]:;"\''<>,.?/]'
        $unicodeCatchAll = '[\u0128-\uFFFF]'
               
        $delimiterChar = @(
            [char]44
            [char]46
            [char]45
            [char]8208
            [char]8209
            [char]8210
            [char]8211
            [char]8212
            [char]95
            [char]32
            [char]35
            [char]9
        )

        $defaultPolicy = Get-ADDefaultDomainPasswordPolicy -Identity $env:USERDOMAIN
        if( !($MinPasswordLength) )
        {
            $MinPasswordLength = $defaultPolicy.minPasswordLength
        }
        if( !($ComplexityEnabled) )
        {
            $ComplexityEnabled = $defaultPolicy.complexityEnabled
        }

        if($User)
        {
            try 
            {
                $UserObject = Get-AdUser $User -Properties DisplayName
            }
            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] 
            {
                $msgUserNotFound = "No matches found for $($User)"
                Write-Warning $msgUserNotFound
                return $False
            }            
        }
        
        if( ($ComplexityEnabled) -AND !($CharTypeMinimum) )
        {
            $CharTypeMinimum = 3
        }
    }   
    Process 
    {
        $PasswordEvalComplex = $True
        
        if($UserObject)
        {
            if($UserObject.SamAccountName.length -ge 3)
            {
                if( $Password -match $UserObject.SamAccountName)
                {
                    $PasswordEvalComplex = $False
                    $msgPasswordMatchSam = "Password matches SamAccountName, not allowed when complexity enabled."
                    Write-Warning $msgPasswordMatchSam
                    Return $PasswordEvalComplex
                }
            }
            $userDisplayNamePieces =  @( $($UserObject.DisplayName).Split($delimiterChar,[System.StringSplitOptions]::RemoveEmptyEntries) )
            foreach($subsection in $userDisplayNamePieces)
            {
                if( $subsection.length -ge 2 )
                {
                    $ComplexCheck = $Password -match $subsection
                }
                if( $ComplexCheck )
                {
                    $PasswordEvalComplex = $False
                    Write-Warning "Failed complexity check on `'$($subsection)`' against `'$($Password)`'"
                    Return $PasswordEvalComplex
                }
            }
        }
        
        if($Password.length -lt $minPasswordLength)
        {
            $PasswordEvalComplex = $False
            $msgPasswordTooShort = "Password length less than minimum of $($minPasswordLength) characters."
            Write-Warning $msgPasswordTooShort
            Return $PasswordEvalComplex
        }
        
        $CharacterTypes = 0
        if( $Password -cmatch $asciiLower)
        {
            $CharacterTypes++
        }
        if( $Password -cmatch $asciiUpper)
        {
            $CharacterTypes++
        }
        if( $Password -match $baseTen )
        {
            $CharacterTypes++
        }
        if( $Password -match $topRow )
        {
            $CharacterTypes++
        }
        if( ($Password -notmatch $asciiLower) -AND 
            ($Password -notmatch $asciiUpper) -AND
            ($Password -notmatch $baseTen) -AND
            ($Password -notmatch $topRow) -AND
            ($Password -match $unicodeCatchAll) )
        {
            $CharacterTypes++
        }
        Write-Verbose "$($CharacterTypes) CharacterTypes found"
    
        if($CharacterTypes -lt $CharTypeMinimum)
        {
            $PasswordEvalComplex = $False
            $msgPasswordNeedMoreCharType = "Password must have $($CharTypeMinimum) " +
                "out of the 5 approved character types, $($CharacterTypes) found."
            Write-Warning $msgPasswordNeedMoreCharType
            Return $PasswordEvalComplex
        }
    
        Return $PasswordEvalComplex
    }
}
