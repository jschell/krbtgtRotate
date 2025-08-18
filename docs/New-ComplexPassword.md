---
external help file: krbtgtRotate-help.xml
online version: 
schema: 2.0.0
---

# New-ComplexPassword
## SYNOPSIS
Create a new, complex password.

## SYNTAX

### SpecificLength (Default)
```
New-ComplexPassword [-PasswordLength <Int32>] [-User <String>]
```

### VariableLength
```
New-ComplexPassword -MinimumLength <Int32> -MaximumLength <Int32> [-User <String>]
```

## DESCRIPTION
Creates a new, complex password, to be tested with the 'Test-ComplexPassword' 
function.
Password can be defined as a specific character length or a range (with
minimum and maximum).
If the 'user' parameter is provided, the password will also
be tested for matching the username (generally prohibited).
Requires the 
'Test-ComplexPassword' function to be loaded and/or available.
Specific characters
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
    state change is taking place (incorrectly).
Electing to add the rule 
    exception rather than add 'ShouldProcess' to the function.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

	PS > New-ComplexPassword -PasswordLength 20 -User krbtgt
	
	@2;^QAHO)e+tJ~}|f\>h\

Description
-----------
Returns a password (string) that is 20 characters long, complex, and does not 
contain the username within the returned value.

### -------------------------- EXAMPLE 2 --------------------------

	PS > New-ComplexPassword -MinimumLength 10 -MaximumLength 30
	
	70H-5!y89^h*TO}|\ub3Wp

Description
---------
Returns a password (string) that is between 10 and 30 characters long and complex.

### -------------------------- EXAMPLE 3 --------------------------

	PS > New-ComplexPassword -User jdoe
	
	Uyq}3IE!gplrH4\>{.2sv,f\<5+

Description
---------
Returns a password (string) that is 25 characters long (default), complex, and 
does not contain the username within the returned value.

## PARAMETERS

### -PasswordLength
Specifies a set character length for the password.

```yaml
Type: Int32
Parameter Sets: SpecificLength
Aliases: 

Required: False
Position: Named
Default value: 25
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -MinimumLength
Specifies the minimum length of the password; used in conjunction with 'MaximumLength'.

```yaml
Type: Int32
Parameter Sets: VariableLength
Aliases: 

Required: True
Position: Named
Default value: 0
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -MaximumLength
Specifies the maximum length of the password; used in conjunction with 'MinimumLength'.

```yaml
Type: Int32
Parameter Sets: VariableLength
Aliases: 

Required: True
Position: Named
Default value: 0
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -User
Specifies the user name of the account.
Used to validate the password does not 
contain the username string.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: 
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

### System.Int32,System.String

## OUTPUTS

### System.String

## NOTES
#### Name:       New-ComplexPassword
#### Author:     Jim Schell
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

## RELATED LINKS

