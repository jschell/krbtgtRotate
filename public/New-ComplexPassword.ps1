function New-ComplexPassword 
{
<#
.SYNOPSIS
Create a new, complex password.

.DESCRIPTION
Creates a new, complex password, to be tested with the 'Test-ComplexPassword' 
function. Password can be defined as a specific character length or a range (with
minimum and maximum). If the 'user' parameter is provided, the password will also
be tested for matching the username (generally prohibited). Requires the 
'Test-ComplexPassword' function to be loaded and/or available. Specific characters
are defined in the 'Begin' portion that have been found to be problematic to use 
and have been excluded from being returned.

-Required modules
    ActiveDirectory 

-Required functions
    Test-ComplexPassword

-PS Script Analyzer exceptions 
    -PSAvoidUsingUserNameAndPassWordParams - Because both the user object and 
    password are being evaluated (complexity check), using descriptive parameters
    is better than using compliant albeit vague or misleading names.
    -PSUseShouldProcessForStateChangingFunctions - Rule is evaluating that a 
    state change is taking place (incorrectly). Electing to add the rule 
    exception rather than add 'ShouldProcess' to the function.

.PARAMETER PasswordLength
Specifies a set character length for the password.

.PARAMETER MinimumLength
Specifies the minimum length of the password; used in conjunction with 'MaximumLength'.

.PARAMETER MaximumLength
Specifies the maximum length of the password; used in conjunction with 'MinimumLength'.

.PARAMETER User
Specifies the user name of the account. Used to validate the password does not 
contain the username string.

.EXAMPLE
PS > New-ComplexPassword -PasswordLength 20 -User krbtgt

@2;^QAHO)e+tJ~}|f>h\

Description
-----------
Returns a password (string) that is 20 characters long, complex, and does not 
contain the username within the returned value.

.EXAMPLE
PS > New-ComplexPassword -MinimumLength 10 -MaximumLength 30

70H-5!y89^h*TO}|\ub3Wp

Description
---------
Returns a password (string) that is between 10 and 30 characters long and complex.

.EXAMPLE
PS > New-ComplexPassword -User jdoe

Uyq}3IE!gplrH4>{.2sv,f<5+

Description
---------
Returns a password (string) that is 25 characters long (default), complex, and 
does not contain the username within the returned value.

.INPUTS
System.Int32,System.String

.OUTPUTS
System.String

.NOTES

#### Name:       New-ComplexPassword
#### Author:     J Schell
#### Version:    0.3.1
#### License:    MIT License

### ChangeLog

##### 2017-03-23::0.3.1
-PSSA rule exceptions/ compliance
-User param now accepts ADUser object 

##### 2017-01-23::0.3.0
- filling out comment based help
- moving open brace to next line (style)

##### 2016-09-21::0.2.0
- rework of several pieces, bumping to v0.2.0 for module

##### 2016-09-20::0.1.1
- add user param, update testcomplex to accept user if present

##### 2016-06-29::0.1.0
- initial creation

#>


    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "")]
    [CmdletBinding( DefaultParameterSetName = "SpecificLength" )]
    [OutputType([String])]
    Param
    (
        [Parameter( Mandatory = $False, 
            ValueFromPipeline = $True,
            ParameterSetName = "SpecificLength" )]
        [ValidateRange(6,127)]
        [int]
        $PasswordLength = 25,
        
        [Parameter( Mandatory = $True, 
            ValueFromPipeline = $True,
            ParameterSetName = "VariableLength" )]
        [ValidateRange(6,126)]
        [int]
        $MinimumLength,
        
        [Parameter( Mandatory = $True,
            ValueFromPipeline = $True,
            ParameterSetName = "VariableLength" )]
        [ValidateRange(8,127)]
        [int]
        $MaximumLength,
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True,
            ParameterSetName = "SpecificLength" )]
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True,
            ParameterSetName = "VariableLength" )]
        [string]
        [Microsoft.ActiveDirectory.Management.ADUser]
        $User
    )
    
    Begin 
    {
        <# Excluded Characters
        [char]34 = "
        [char]39 = '
        [char]47 = /
        [char]96 = `
        #>
        $ExcludedCharacters = @(34, 39, 47, 96)
        $CharacterSet = (33..126).Where({ ($_ -NotIn $ExcludedCharacters) })  
    }
    
    Process 
    {
        if( ($MaximumLength) -AND ($MinimumLength))
        {
            $PasswordLength = Get-Random -Maximum $MaximumLength -Minimum $MinimumLength
        }
        
        $PasswordGenerationCount = 0
        Do 
        {
            $PasswordGenerationCount++
            $PasswordInput = @()
            for( $charCount = 0; $charCount -lt $PasswordLength; $charCount++)
            {
                $PasswordInput += @( Get-Random -inputObject $CharacterSet )
            }
            
            $Password = ([char[]]$PasswordInput) -join ''
            
            $paramTestComplex = @{
                password = $Password
            }
            if($User)
            {
                $paramTestComplex += @{ user = $User }
            }
            
            if($PasswordGenerationCount -gt 20)
            {
                $msgPasswordGenerationNotComplex = "Failed to generate " +
                    "password meeting complexity requirements after 20 iterations."
                Write-LogMessage -Message $msgPasswordGenerationNotComplex -Caller "New-ComplexPassword" -Category Error @paramWriteLog
                Write-Warning $msgWarnPasswordGenerationNotComplex
            }
        }
        While( !(Test-ComplexPassword @paramTestComplex) -AND ($PasswordGenerationCount -le 20) )
        
        $Password
    }
}