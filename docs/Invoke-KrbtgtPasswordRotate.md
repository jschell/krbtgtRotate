---
external help file: krbtgtRotate-help.xml
online version: 
schema: 2.0.0
---

# Invoke-KrbtgtPasswordRotate
## SYNOPSIS
Invoke-KrbtgtPasswordRotate is the controller function that orchestrates rotating
the krbtgt password in a safe manner.

## SYNTAX

```
Invoke-KrbtgtPasswordRotate [[-krbtgtSamAccountName] <String>] [[-ComputerName] <String>] [[-LogPath] <String>]
 [[-LogName] <String>] [[-SourceName] <String>] [-Force] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Invoke-KrbtgtPasswordRotate manages the orchestration of the validation, sync,
rotation and logging of rotating the krbtgt account password.
The primary goal of
the function is to rotate the password without impacting existing kerberos ticket
holders.
This is accomplished by waiting between rotations a minimum amount of time,
equal or greater than the lifetime of the kerberos ticket plus twice the allowed 
clock skew. 
The krbtgt account is aware of the current and one prior password, using the current
password to generate the TGT.
A ticket issued under password\`0 would be valid for
one rotation - password\`1.
If the password was to be rotated again (to password\`2) 
while tickets issued under password\`0 were still valid, the tickets issued under 
password\`0 would no longer be accepted.
The krbtgt account would only recognize 
tickets issued by the current (password\`2) and prior (password\`1).
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
    environmental conditions/ findings that will block success.
This will be a 
    goal to remove in future iterations.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

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

### -------------------------- EXAMPLE 2 --------------------------

	PS > Invoke-KrbtgtPasswordRotate -Force


Description
-----------
The command will attempt to rotate the krbtgt user object password once using the
default parameter values.

## PARAMETERS

### -krbtgtSamAccountName
Specifies samAccountName of the krbtgt account.
Will be 'krbtgt', unless operating
against RODC.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: Krbtgt
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ComputerName
Specifies the Computer to operate against.
Default will be PDCe, future versions 
will allow for targeting RODC.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: (Get-ADDomain).PDCEmulator
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -LogPath
Specifies path to the directory where the log will be created on disk.

```yaml
Type: String
Parameter Sets: (All)
Aliases: OutPath

Required: False
Position: 3
Default value: $PWD
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -LogName
Specifies the event log that will be used to journal the progress of the rotation.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name, Log

Required: False
Position: 4
Default value: Directory Service
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SourceName
Specifies the source name that will be registered (if not already done) for the event log.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Source

Required: False
Position: 5
Default value: KrbtgtRotation
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Force
Switch parameter, allows bypass of confirm.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs without performing the actual rotation.
Prerequisite validation (elevated session, domain functional level, PDC Emulator
reachability, krbtgt account lookup, and password minimum age check) still executes.
Use this to confirm all preconditions are met before committing to a live rotation.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts for confirmation before executing the password change. Because ConfirmImpact
is set to High, PowerShell will prompt automatically when $ConfirmPreference is set
to High or lower. Use -Force to suppress the confirmation prompt.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### System.String

## OUTPUTS

### None

## NOTES
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
- initial creation, inspired by technet script \[link\]

## RELATED LINKS

[about_comment_based_help]()

