---
external help file: krbtgtRotate-help.xml
online version: https://technet.microsoft.com/en-us/library/cc786468.aspx
schema: 2.0.0
---

# Test-ComplexPassword
## SYNOPSIS
This function tests if a given string will meet the complexity requirements specified.

## SYNTAX

```
Test-ComplexPassword [-Password] <String> [[-User] <String>] [[-MinPasswordLength] <Int32>]
 [[-ComplexityEnabled] <Boolean>] [[-CharTypeMinimum] <Int32>]
```

## DESCRIPTION
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

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

	PS > Test-ComplexPassword -Password 'krbtgtPasswordSecret!1' -User krbtgt
	
	WARNING: Password matches SamAccountName, not allowed when complexity enabled.
	False

Description
-----------
Testing if the supplied password would be complex for the specified user, received
a warning and 'False' (failing) status returned.
The failed status was because the
password had a match for the SamAccountName of the account specified.

### -------------------------- EXAMPLE 2 --------------------------

	PS > Test-ComplexPassword -Password 'adminPasswordSecret!1' -User krbtgt
	
	True

Description
--------
Testing if the supplied password would be complex for the specified user, result
was 'True' (passing).
Because the password does not contain the SamAccountName and
matches 3 of the 5 character sets, result is passing.

## PARAMETERS

### -Password
Specifies the password to test for complexity.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: 
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -User
Specifies the user (account) where the password will be set - evaluation of matching
characters in the password and SamAccountName.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: 
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -MinPasswordLength
Specifies the minimum password length, typically gathered from the current 
working domain.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: 0
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ComplexityEnabled
Specifies if complexity is enabled for passwords, typically gathered from the 
current working domain.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
Default value: False
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -CharTypeMinimum
Specifies the minimum number of different types of characters that must be present 
in the password under test.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: 

Required: False
Position: 5
Default value: 0
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

### System.Int32, System.String, System.Bool

## OUTPUTS

### System.Bool

## NOTES
#### Name:       Test-ComplexPassword
#### Author:     Jim Schell
#### Version:    0.2.2
#### License:    MIT

### Change Log

##### 2017-03-23::0.2.2
- parameter 'ComplexityTypeMinimum' is now 'CharTypeMinimum'
- moved evaluation of default domain policy out of parameter section into 'begin'
- now evaluating *all* the rules for complexity - displayName matching rules now
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

## RELATED LINKS

[https://technet.microsoft.com/en-us/library/cc786468.aspx](https://technet.microsoft.com/en-us/library/cc786468.aspx)

[https://technet.microsoft.com/en-us/library/hh994562.aspx](https://technet.microsoft.com/en-us/library/hh994562.aspx)

[https://msdn.microsoft.com/en-us/library/cc875839.aspx](https://msdn.microsoft.com/en-us/library/cc875839.aspx)

