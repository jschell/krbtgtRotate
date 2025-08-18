function Get-ByteFromString {
<#
.SYNOPSIS
Get the byte representation of a string, when full language mode is not available.

.DESCRIPTION
Get the byte representation of a string, when full language mode is not available.
Constrained language mode does not grant access to certain methods, including 
getting the encoding as a byte array.

.PARAMETER String
Specifies the string to be returned as a byte array.

.EXAMPLE
PS > Get-ByteFromString -String "Example"

69
120
97
109
112
108
101
13
10

Description
-----------
Returns the byte array of the characters in 'Example'

.INPUTS
System.String

.OUTPUTS
System.Byte

.LINK
about_comment_based_help

.Notes

#### Name:      Get-ByteFromString
#### Author:    J Schell
#### Version:   0.2.1
#### License:   MIT License

### ChangeLog

##### 2017-03-21::0.2.1
-proper help added

##### 2016-09-21::0.2.0
-rework of several pieces, bumping to v0.2.0 for module

##### 2016-07-05::0.1.0
-initial creation
#>


    [CmdletBinding()]
    [OutputType([Byte[]])]
    Param(
        [Parameter( Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True )]
        [String]
        $String
    )
    
    Begin 
    {
        $fileName = [guid]::NewGuid().toString("n")
        $filePath = "$env:Temp\$fileName"
    }
    Process 
    {
        Set-Content -Path $filePath -Value $String
        [Byte[]]$ByteEncoded = Get-Content -Path $filePath -Encoding Byte
        $ByteEncoded
    }
    End 
    {
        Remove-Item -Path $filePath
    }    
}