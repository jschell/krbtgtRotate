---
external help file: krbtgtRotate-help.xml
online version: 
schema: 2.0.0
---

# Write-KrbtgtEventLog
## SYNOPSIS
Writes a structured event to the Windows Event Log during krbtgt password rotation.

## SYNTAX

```
Write-KrbtgtEventLog [[-LogName] <String>] [[-SourceName] <String>] [[-ComputerName] <String>]
 [-Message] <String[]> [-Category] <String> [-MessageType] <String>
```

## DESCRIPTION
Write-KrbtgtEventLog writes a Windows Event Log entry using a structured EventID and
Category scheme derived from the rotation phase and message severity. The EventID is
computed as the sum of the MessageType base value and the Category byte-sum value,
allowing log consumers to filter by both rotation phase and severity simultaneously.

MessageType base values: Information=256, Warning=512, Error=1024, SuccessAudit=2048, FailureAudit=4096

Category byte-sum values (ASCII byte sum of the category string):
- krbtgt = 654
- online = 645
- sync = 445
- krbtgtsinglereset = 1843

Example: an Information event for the krbtgt category has EventID 910 (256 + 654).

Called internally by Invoke-KrbtgtPasswordRotate at each significant step of the rotation
process. Can also be used standalone to write custom audit events to the same structured log.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
PS > Write-KrbtgtEventLog -Message "krbtgt password rotation started" `
        -Category "krbtgt" -MessageType "Information"
```

##Results

Description
-----------
Writes an Information event to the 'Directory Service' log using the default source name
'krbtgtRotation' on the local computer. EventID = 910 (Information 256 + krbtgt 654).

### -------------------------- EXAMPLE 2 --------------------------
```
PS > Write-KrbtgtEventLog -Message "Sync failed for DC01.contoso.com" `
        -Category "sync" -MessageType "Warning" `
        -LogName "Directory Service" -SourceName "krbtgtRotation" `
        -ComputerName "DC01.contoso.com"
```

##Results

Description
-----------
Writes a Warning event to a remote computer's event log. EventID = 957 (Warning 512 + sync 445).
Use this to record per-DC sync failures during a rotation.

## PARAMETERS

### -LogName
Specifies the name of the log to be written.

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
Specifies the source of the content (for the event log).

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
Specifies the computer where the event log will be written.

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

### -Message
Specifies the content of the message in the event log.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Content

Required: True
Position: 4
Default value: 
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Category
Specifies the category of the message.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 5
Default value: 
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -MessageType
Specifies the event type.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Type

Required: True
Position: 6
Default value: 
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

### System.String

## OUTPUTS

### None

## NOTES
#### Name:      Write-KrbtgtEventLog
#### Author:    J Schell
#### Version:   0.2.1
#### License:   MIT License

### ChangeLog

##### 2017-03-21::0.2.1
- proper help (started)

##### 2016-09-21::0.2.0
- rework of several pieces, bumping to v0.2.0 for module

##### 2016-07-07::0.1.1
- moved logic of category, message type, eventID to be inside function (vs.
acting as low value proxy for write-eventLog)
- rework value calc for category and eventID, less artisanal, more consistent

##### 2016-07-06::0.1.0
- initial creation
- pulling functionality out of previously globbed together bits...

## RELATED LINKS

[about_comment_based_help]()

