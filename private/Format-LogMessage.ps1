function Format-LogMessage {
<#
.SYNOPSIS
This will format messages in a consistent manner, with dateTime included.

.DESCRIPTION
Format messages in a consistent manner for including in logs - eventLog or 
application specific.

.PARAMETER Message
Specifies the message to be formated for logging.

.PARAMETER Caller
Specifies the source of the message.

.PARAMETER Category
Specifies the category of the message; can use Info, Verbose, Warning, Error or Debug.

.EXAMPLE
PS > Format-LogMessage -Message "Fizz Buzz" -Caller "Example" -Category Verbose

[ 2000-05-10T20:15:03.0000000-07:00 ]  [ Example ] [ Verbose ]
Fizz Buzz

Description
-----------
The function takes the supplied message, caller and category and formats the content
for being added to a log.

.EXAMPLE
PS > $multiLineMessage = @"
This message is multi-line
    This will show how the format style works for multi-line scenarios
"@

PS > Format-LogMessage -Message $multiLineMessage -Caller "ExampleCaller" -Category Warning

[ 2000-05-10T20:15:03.0000000-07:00 ]  [ ExampleCaller ] [ Warning ]
This message is multi-line
    This will show how the format style works for multi-line scenarios

Description
-----------
The function takes the supplied multi-line message and formats the content.

.EXAMPLE
PS > $messageWithAttributes = New-Object -TypeName PsObject -Property ([ordered]@{
    name = "exampleMessage"
    data = "data from the message to be stored"
    id = 1
    verbose = "more details go here"
})

PS > Format-LogMessage -Message $messageWithAttributes -Caller "ExampleCaller"

[ 2000-05-10T20:15:03.0000000-07:00 ]  [ ExampleCaller ] [ Info ]

name           data                               id verbose
----           ----                               -- -------
exampleMessage data from the message to be stored  1 more details go here


Description
-----------
The function takes the supplied object with attributes and formats the content.

.INPUTS
System.String

.OUTPUTS
System.String, System.Object[]

.LINK
about_comment_based_help

.Notes

#### Name:      Format-LogMessage
#### Author:    J Schell
#### Version:   0.2.1
#### License:   MIT License

### ChangeLog

#### 2017-03-21::0.2.1
- proper help added

#### 2016-09-21::0.2.0
- rework of several pieces, bumping to v0.2.0 for module
    
#### 2016-07-07::0.1.2
- added 'category' param to differentiate messages being received

#### 2016-07-07::0.1.1
- future idea (not included now): log levels, with different levels of information gathered. Not worth implementing partial spec
- updated param w/ alias

#### 2016-07-05::0.1.0
-initial creation
#>


    [CmdletBinding()]
    [OutputType([String[]])]
    [OutputType([System.Object[]])]
    Param(
        [Parameter( Mandatory = $True,
            ValueFromPipeline = $True )]
        [ValidateNotNullOrEmpty()]
        [Alias("Content")]
        $Message,
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [Alias("Source")]
        [String]
        $Caller,
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [ValidateSet("Info", "Verbose", "Warning", "Error", "Debug")]
        [Alias("Condition")]
        [String]
        $Category = "Info"
    )
    
    Begin {
        $dateFormat = "o"
        $Header = "[ $([datetime]::now.ToString($($dateFormat))) ] "
        $Message = $Message | Out-String
    }
    Process {
        if($Caller){
            $MessageReturn = @("$($Header) [ $($Caller) ] [ $($Category) ]")
            $MessageReturn += @($Message)
        }
        else {
            $MessageReturn = @("$($Header) [ $($Category) ]")
            $MessageReturn += @($Message)
        }
        $MessageReturn
    }
}
