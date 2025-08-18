---
external help file: krbtgtRotate-help.xml
online version: 
schema: 2.0.0
---

# Write-KrbtgtEventLog
## SYNOPSIS
Brief description of the function

## SYNTAX

```
Write-KrbtgtEventLog [[-LogName] <String>] [[-SourceName] <String>] [[-ComputerName] <String>]
 [-Message] <String[]> [-Category] <String> [-MessageType] <String>
```

## DESCRIPTION
Detailed description of the function
#----
# events for krbtgt rotation

(byte arr for 'krbtgt') 107 + 114 + 98 + 116 + 103 + 116 = 654 
(byte arr for 'krbtgt rodc') 107 + 114 + 98 + 116 + 103 + 116 + 32 + 114 + 111 +100 +99 = 1110
(byte arr for 'sync') 115 + 121 + 110 + 99 = 445
(byte arr for 'online') 111 + 110 + 108 + 105 + 110 + 101 = 645
(byte arr for 'krbtgtsinglereset') 107 + 114 + 98 + 116 + 103 + 116 + 115 + 105 + 110 + 103 + 108 + 101 + 114 + 101 + 115 + 101 + 116 = 1843


info krbtgt - last set pwd
warning krbtgt - within change window
info krbtgt - DFL greater than 2008
error krbtgt - DFL less than 2008
successAudit krbtgt - changed pwd
failureAudit krbtgt - could not change pwd

(same for krbtgt rodc)

info online - per RWDC available
warning online - per RWDC not available
error online - per RWDC could not reach over x iterations

info sync - # of RWDC to sync
info sync - per RWDC sync
successAudit sync - when complete
warning sync - could not sync one RWDC
failureAudit sync - could not sync one RWDC over x iterations
error sync - one or more RWDC could not sync

successAudit krbtgtsinglereset - single reset of krbtgt completed
failureAudit krbtgtsinglereset - could not complete single reset of krbtgt

information
256
warning
512
error
1024
successAudit
2048
failureAudit
4096

#----

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Verb-Noun -ParameterA 'someValue' -ParameterB 42
```

##Results

Description
-----------
First is the simplest example, showing the effect of the cmdlet with only the required parameters.

### -------------------------- EXAMPLE 2 --------------------------
```
Verb-Noun 'someValue' 42
```

##Results

Description
-----------
Final example shows real world scenario, and effects.

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

