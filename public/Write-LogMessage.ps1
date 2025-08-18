function Write-LogMessage {
<#
.SYNOPSIS
Brief description of the function

.DESCRIPTION
Detailed description of the function

.PARAMETER Message
Specifies the message content to be written. 

.PARAMETER Caller
Specifies the source of the message.

.PARAMETER Category
Specifies the category of the message; can be Info, Verbose, Warning, Error or Debug.

.PARAMETER OutPath
Specifies the folder where the log file should be written.

.PARAMETER FileName
Specifies the name of the file for the log.

.PARAMETER PassThru
Switch parameter, specifies that the same content to be written to the log should 
be sent to the default out view. 

.EXAMPLE
PS > $paramMessage = @{
    Message = "Simple test message"
    Caller = "ExampleCaller"
    Category = "Verbose"
    PassThru = $True
}
PS > Write-LogMessage @paramMessage

[ 2000-05-10T20:15:03.0000000-07:00 ]  [ ExampleCaller ] [ Verbose ]
Simple test message

PS > dir $env:Temp

    Directory: C:\Users\jdoe\AppData\Local\Temp

Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----       2000-05-10     15:03             96 c624ff78aa7e41a3ac43973d774dc267.txt

Description
-----------
The message is formatted and written to the log, created by default in the 'Temp' folder.

.INPUTS
System.String

.OUTPUTS
System.String

.LINK
about_comment_based_help

.Notes

#### Name:      Write-LogMessage
#### Author:    J Schell
#### Version:   0.2.2
#### License:   MIT License

### ChangeLog

#### 2017-03-21::0.2.2
- proper help added

##### 2016-09-22::0.2.1
-changing msgLogPath to show only during debug (reduce the noise in verbose)

##### 2016-09-21::0.2.0
-rework of several pieces, bumping to v0.2.0 for module

##### 2016-07-07::0.1.2
-updated param w/ alias
-added basic error handling for outPath not exist, not able to write to log
-added 'category' param to differentiate messages being received

##### 2016-07-06::0.1.1
-removed 'outHost' switch, created duplicate output if 'outHost' and 'passThru' invoked @interactive console

##### 2016-07-05::0.1.0
-initial creation
#>


    [CmdletBinding()]
    [OutputType([String[]])]
    Param
    (
        [Parameter( Mandatory = $True,
            ValueFromPipeline = $True )]
        [ValidateNotNullOrEmpty()]
        [Alias("Content")]
        $Message,
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [ValidateNotNullOrEmpty()]
        [Alias("Source")]
        [String]
        $Caller,
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [ValidateSet("Info", "Verbose", "Warning", "Error", "Debug")]
        [Alias("Condition")]
        [String]
        $Category = "Info",
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [ValidateNotNullOrEmpty()]
        [Alias("Path")]
        [String]
        $OutPath = $env:Temp,
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [ValidateNotNullOrEmpty()]
        [Alias("Name", "Log")]
        [String]
        $FileName = "$([Guid]::NewGuid().ToString("n")).txt",
        
        [Parameter( Mandatory = $False )]
        [Switch]
        $PassThru
    )
    
    Begin 
    {
        if( !(Test-Path $OutPath) )
        {
            $msgOutPathNotExist = "OutPath `'$($OutPath)`' does not exist, using `$env:TEMP"
            Write-Warning $msgOutPathNotExist
            $OutPath = $env:TEMP
        }
        $LogPath = Join-Path $OutPath $FileName
        $msgLogPath = "Path for log will be: `'$($LogPath)`'"
        Write-Debug $msgLogPath
    }
    Process 
    {
        $FormatParams = @{
            Message = $Message
            Category = $Category
        }
        if($Caller)
        {
            $FormatParams += @{ Caller = $Caller }
        }
        $MessageFormatted = Format-LogMessage @FormatParams

        if($PassThru)
        {
            $MessageFormatted
        }
        
        try 
        {
            $OutParams = @{
                InputObject = $MessageFormatted
                FilePath = $LogPath
                Encoding = "UTF8"
                Append = $True
            }
            Out-File @OutParams
        }
        catch 
        {
            $msgErrorWhileWritingLog = "Error while writing the log, sending to `$env:Temp. Error: $_"
            Write-Warning $msgErrorWhileWritingLog
            
            try 
            {
                $OutParams = @{
                    InputObject = $MessageFormatted
                    FilePath = (Join-Path $env:TEMP $FileName)
                    Encoding = "UTF8"
                    Append = $True
                    }
                Out-File @OutParams
            }
            catch 
            {
                $msgErrorWhileWritingTempLog = "Things are going badly. Review output and resolve error: $_"
                Write-Error $msgErrorWhileWritingTempLog
                break
            }
        }
    }
}