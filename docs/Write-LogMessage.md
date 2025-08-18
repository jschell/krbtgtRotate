---
external help file: krbtgtRotate-help.xml
online version: 
schema: 2.0.0
---

# Write-LogMessage
## SYNOPSIS
Brief description of the function

## SYNTAX

```
Write-LogMessage [-Message] <Object> [[-Caller] <String>] [[-Category] <String>] [[-OutPath] <String>]
 [[-FileName] <String>] [-PassThru]
```

## DESCRIPTION
Detailed description of the function

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

	PS > $paramMessage = @{
	Message = "Simple test message"
	    Caller = "ExampleCaller"
	    Category = "Verbose"
	    PassThru = $True
	}
	PS > Write-LogMessage @paramMessage
	
	[ 2000-05-10T20:15:03.0000000-07:00 ] [ ExampleCaller ] [ Verbose ]
	Simple test message
	
	PS > dir $env:Temp
	
	    Directory: C:\Users\jdoe\AppData\Local\Temp
	
	Mode                LastWriteTime         Length Name
	----                -------------         ------ ----
	-a----       2000-05-10     15:03             96 c624ff78aa7e41a3ac43973d774dc267.txt

Description
-----------
The message is formatted and written to the log, created by default in the 'Temp' folder.

## PARAMETERS

### -Message
Specifies the message content to be written.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: Content

Required: True
Position: 1
Default value: 
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Caller
Specifies the source of the message.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Source

Required: False
Position: 2
Default value: 
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Category
Specifies the category of the message; can be Info, Verbose, Warning, Error or Debug.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Condition

Required: False
Position: 3
Default value: Info
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -OutPath
Specifies the folder where the log file should be written.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: False
Position: 4
Default value: $env:Temp
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -FileName
Specifies the name of the file for the log.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name, Log

Required: False
Position: 5
Default value: "$([Guid]::NewGuid().ToString("n")).txt"
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PassThru
Switch parameter, specifies that the same content to be written to the log should 
be sent to the default out view.

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

## INPUTS

### System.String

## OUTPUTS

### System.String

## NOTES
#### Name:      Write-LogMessage
#### Author:    J Schell
#### Version:   0.2.2
#### License:   MIT License

### ChangeLog

#### 2017-03-21::0.2.2
- proper help added

##### 2016-09-22::0.2.1
- changing msgLogPath to show only during debug (reduce the noise in verbose)

##### 2016-09-21::0.2.0
- rework of several pieces, bumping to v0.2.0 for module

##### 2016-07-07::0.1.2
- updated param w/ alias
- added basic error handling for outPath not exist, not able to write to log
- added 'category' param to differentiate messages being received

##### 2016-07-06::0.1.1
- removed 'outHost' switch, created duplicate output if 'outHost' and 'passThru' invoked @interactive console

##### 2016-07-05::0.1.0
- initial creation

## RELATED LINKS

[about_comment_based_help]()

