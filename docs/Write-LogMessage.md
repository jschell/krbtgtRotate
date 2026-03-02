---
external help file: krbtgtRotate-help.xml
online version: 
schema: 2.0.0
---

# Write-LogMessage
## SYNOPSIS
Writes a timestamped, categorized message to a log file on disk.

## SYNTAX

```
Write-LogMessage [-Message] <Object> [[-Caller] <String>] [[-Category] <String>] [[-OutPath] <String>]
 [[-FileName] <String>] [-PassThru]
```

## DESCRIPTION
Write-LogMessage appends a formatted, timestamped entry to a log file on disk. Each entry
includes the ISO 8601 timestamp, the calling function name, the category
(Info, Verbose, Warning, Error, Debug), and the message body.

When called from Invoke-KrbtgtPasswordRotate, the FileName and OutPath are set by the
caller so all rotation events land in the same file. The default FileName is a new GUID
(e.g., 'c624ff78aa7e41a3ac43973d774dc267.txt') written to $env:Temp.

To locate a log file written with default settings:
    dir $env:Temp\*.txt | Sort-Object LastWriteTime -Descending | Select-Object -First 1

Each log line follows this format:
    [ <ISO8601 timestamp> ] [ <CallerName> ] [ <Category> ]
    <message body>

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

### -------------------------- EXAMPLE 2 --------------------------

	PS > Write-LogMessage -Message "Halting error encountered on DC01" `
	        -Caller "Invoke-KrbtgtPasswordRotate" `
	        -Category "Error" `
	        -OutPath "C:\logs\krbtgtRotate" `
	        -FileName "2026-03-01T14.30.00-krbtgtRotate.txt"

Description
-----------
Appends an Error-category entry to a named log file in the specified path. If OutPath does
not exist or is not writable, the log falls back to $env:Temp with a warning. Use a
consistent FileName across multiple Write-LogMessage calls to collect all events for a
single rotation run in one file.

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

