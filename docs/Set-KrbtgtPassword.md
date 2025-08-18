---
external help file: krbtgtRotate-help.xml
online version: 
schema: 2.0.0
---

# Set-KrbtgtPassword
## SYNOPSIS
Set the password for the krbtgt user.

## SYNTAX

```
Set-KrbtgtPassword [-Password] <String> [[-User] <String>] [[-Server] <String>] [[-Credential] <PSCredential>]
```

## DESCRIPTION
Sets the password for the krbtgt user temporarily, the system will automatically 
rotate this password on change.
This function exists only to trigger the change 
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

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

	PS > Set-KrbtgtPassword -Password "SuperComplex!Password1" -User krbtgt -Server DC01.contoso.com
	
	True

Description
-----------
The boolean value returned indicates the success (or failure) of the action. 
In the example above, the rotation succeeded.

### -------------------------- EXAMPLE 2 --------------------------

	PS > Set-KrbtgtPassword -Password "SuperComplex!Password1"
	
	True

Description
-----------
The boolean value returned indicates the success (or failure) of the action. 
In the example above, the rotation succeeded.
Using the default parameter values
for 'User' and 'Server'.

## PARAMETERS

### -Password
Specifies the string to be used for setting the krbtgt account password.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -User
Specifies the user account to where the password will be changed; default is 'krbtgt'.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: Krbtgt
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
Specifies the domain controller that should be the target for setting the password.
Default is the PDCEmulator.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: (Get-ADDomain).PDCEmulator
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Specifies the credentials to use when setting the password; optional.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### System.String, System.Management.Automation.PSCredential

## OUTPUTS

### System.Bool

## NOTES
#### Name:      Set-KrbtgtPassword
#### Author:    Jim Schell
#### Version:   0.2.3
#### License:   MIT License

### ChangeLog

##### 2017-03-23::0.2.3
- description for PSSA rule exceptions

##### 2017-03-22::0.2.2
- more suppressed PSSA rules
- silly attribute games on 'Credential' parameter to satisfy PSSA 

##### 2017-03-21::0.2.1
- proper help added
- added exception to PSScriptAnalyzer rules 

##### 2016-09-21::0.2.0
- rework of several pieces, bumping to v0.2.0 for module

##### 2016-07-05::0.1.0
- initial creation

## RELATED LINKS

[about_comment_based_help]()

