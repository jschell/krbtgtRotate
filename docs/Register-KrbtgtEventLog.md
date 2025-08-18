---
external help file: krbtgtRotate-help.xml
online version: 
schema: 2.0.0
---

# Register-KrbtgtEventLog
## SYNOPSIS
This function registers the krbtgtRotate module with the specified event log, to
be used while the krbtgt account password is being rotated.

## SYNTAX

```
Register-KrbtgtEventLog [[-LogName] <String>] [[-SourceName] <String>] [[-ComputerName] <String>] [-WhatIf]
 [-Confirm]
```

## DESCRIPTION
In addition to on disk logging, the use of event logs allows for downstream 
consumers (SCOM, OMS, etc...) to parse and take action if necessary.
Registering
as a source allows for capturing the state of the operation as it progresses.

-Required modules
    None

-Required functions
    Write-LogMessage

-PS Script Analyzer exceptions 
    -PSAvoidGlobalVars - krbtgtRotate uses global variables to track the status of
    environmental conditions/ findings that will block success.
This will be a 
    goal to remove in future iterations.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

	PS > Register-KrbtgtEventLog -LogName "Directory Service" -SourceName krbtgtRotation -ComputerName $env:ComputerName
	
	True

Description
-----------
The event log 'Directory Service' will now accept new events from the source 'krbtgtRotation' 
on the localhost.

### -------------------------- EXAMPLE 2 --------------------------

	PS > Register-KrbtgtEventLog
	
	True

Description
-----------
Using the default parameter values, the event log 'Directory Service' will now
accept new events from the source 'krbtgtRotation' on the localhost.

## PARAMETERS

### -LogName
Specifies the name of the event log to register against.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name, Log

Required: False
Position: 1
Default value: Directory Service
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SourceName
Specifies the name of the source that will be registered with the event log.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Source

Required: False
Position: 2
Default value: KrbtgtRotation
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ComputerName
Specifies the name of the computer where the event log resides.
Use caution when
specifying *other* than localhost.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: $env:ComputerName
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -WhatIf
{{Fill WhatIf Description}}

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
{{Fill Confirm Description}}

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

### System.Boolean

## NOTES
#### Name:      Register-KrbtgtEventLog
#### Author:    Jim Schell
#### Version:   0.3.1
#### License:   MIT License

### ChangeLog

##### 2017-03-23::0.3.1
- PSSA rule exceptions

##### 2017-01-24::0.3.0
- filling out comment based help
- moving open brace to next line (style)
- trim dead sections (commented out)

##### 2016-09-21::0.2.0
- rework of several pieces, bumping to v0.2.0 for module
- log update
    was: 'Microsoft-Windows-Kerberos/Operational'
    now: 'Directory Service'
- pull section that sets event log size, if it isn't there/ wrong size, do it external
- update with increment haltingErrorCount

##### 2016-07-11::0.1.4
- updated to include 'write-logMessage'
- updated to support 'shouldProcess' and 'confirmImpact'

##### 2016-07-07::0.1.3
- dropped 'get-eventLog' from query, 'get-winEvent' works for classic and current
- added status checks for if log exist, if source registered
- updated default log to kerb/ops
- updated verb to 'register' from 'new'

##### 2016-07-06::0.1.2
- allow new style event logs (ETW) to be used, query uses 'get-winEvent' vs.
'get-eventLog'
- add computerName param
- handle access denied during eventLog enum

##### 2016-07-05::0.1.1
- logic around restart required (or not) for new event log

##### 2016-07-05::0.1.0
- initial creation
- pulling out as separate function from rest of logic

## RELATED LINKS

