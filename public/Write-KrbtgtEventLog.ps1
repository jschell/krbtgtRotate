function Write-KrbtgtEventLog {
<#
.SYNOPSIS
Brief description of the function

.DESCRIPTION
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
.PARAMETER LogName
Specifies the name of the log to be written.

.PARAMETER SourceName
Specifies the source of the content (for the event log).

.PARAMETER ComputerName
Specifies the computer where the event log will be written.

.PARAMETER Message
Specifies the content of the message in the event log.

.PARAMETER Category
Specifies the category of the message.

.PARAMETER MessageType
Specifies the event type.

.EXAMPLE
PS > Verb-Noun -ParameterA 'someValue' -ParameterB 42
##Results

Description
-----------
First is the simplest example, showing the effect of the cmdlet with only the required parameters.

.EXAMPLE
PS > Verb-Noun 'someValue' 42
##Results

Description
-----------
Final example shows real world scenario, and effects.

.INPUTS
System.String

.OUTPUTS
None

.LINK
about_comment_based_help

.Notes

#### Name:      Write-KrbtgtEventLog
#### Author:    J Schell
#### Version:   0.2.1
#### License:   MIT License

### ChangeLog

##### 2017-03-21::0.2.1
-proper help (started)

##### 2016-09-21::0.2.0
-rework of several pieces, bumping to v0.2.0 for module

##### 2016-07-07::0.1.1
-moved logic of category, message type, eventID to be inside function (vs. acting as low value proxy for write-eventLog)
-rework value calc for category and eventID, less artisanal, more consistent

##### 2016-07-06::0.1.0
-initial creation
-pulling functionality out of previously globbed together bits...
#>


    [CmdletBinding()]
    Param(
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [Alias("Name","Log")]
        [String]
        $LogName = "Directory Service", 
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [Alias("Source")]
        [String]
        $SourceName = "krbtgtRotation",
        
        [Parameter( Mandatory = $False,
            ValueFromPipeline = $True )]
        [String]
        $ComputerName = $env:ComputerName,
        
        [Parameter( Mandatory = $True,
            ValueFromPipeline = $True )]
        [Alias("Content")]
        [String[]]
        $Message,
        
        [Parameter( Mandatory = $True,
            ValueFromPipeline = $True )]
        [ValidateSet("krbtgt","sync","online","krbtgtsinglereset")]
        [String]
        $Category,
        
        [Parameter( Mandatory = $True,
            ValueFromPipeline = $True )]
        [ValidateSet("Information", "Warning", "Error", "SuccessAudit", "FailureAudit")]
        [Alias("Type")]
        [String]
        $MessageType
    )
    
    Begin 
    {
        switch( $MessageType )
        {
            "Information" 
            {
                $EventID = 256
            }
            "Warning" 
            {
                $EventID = 512
            }
            "Error" 
            {
                $EventID = 1024
            }
            "SuccessAudit" 
            {
                $EventID = 2048
            }
            "FailureAudit" 
            {
                $EventID = 4096
            }
            default {}
        }
        switch( $Category )
        {
            "krbtgt" 
            {
                $EventID += 654
                $CategoryInt = 654
            }
            "online" 
            {
                $EventID += 645
                $CategoryInt = 645
            }
            "sync" 
            {
                $EventID += 445
                $CategoryInt = 445
            }
            "krbtgtsinglereset" 
            {
                $EventID += 1843
                $CategoryInt = 1843
            }
            default {}
        }
    }
    Process 
    {
        $RawDataMessage = Get-ByteFromString -String ($Message | Out-String)
        $MessageAsString = $Message | Out-String
        $paramWriteEventLog = @{
            LogName = $LogName
            Source = $SourceName
            EventID = $EventID
            Category = $CategoryInt
            Message = $MessageAsString
            RawData = $RawDataMessage
            EntryType = $MessageType
            ComputerName = $ComputerName
        }
        Write-EventLog @paramWriteEventLog   
    }
}