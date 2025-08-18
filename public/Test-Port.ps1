#Requires -Version 4
function Test-Port {
<#
.Synopsis
Test connectivity to one or more computers. Requires PowerShell version 4 or later.

.Description
Test connectivity to one or more computers. Primary goal of this cmdlet was to 
test connectivity against specific ports, using methods available in Constrained 
Language Mode. This cmdlet uses Test-Connection and Test-NetConnection.

.Example
PS > Test-Port -Port 135
    True

Description
-----------
When no computer name is specified, the check will be against the local machine. 
Because the machine responded for ping, and port 135, the result was 'True'.

.Example
PS > Test-Port -ComputerName NotOnline -CommonPort RPC
    False

Description
-----------
If the computer fails one or more of the connectivity checks, the result will be 'False'

.Example
PS > Get-ADDomainController -Filter * | Select -ExpandProperty Hostname
    DC01.local.example.com
    DC02.local.example.com
    
PS > Test-Port -ComputerName (Get-ADDomainController -Filter * | Select -ExpandProperty HostName) -CommonService ADMinimum -InfoVariable DCStatus
    False
    True

PS > $DCStatus.Where({$_.Status -eq $false})

    ComputerName            Label           Status  Tests
    ------------            -----           ------  -----
    DC01.local.example.com  Passed Tests    False   {@{ComputerName=DC01.local.example.co...

PS > $DCStatus.Where({$_.Status -eq $false}).Tests

    ComputerName            Test        PortNum Passed
    ------------            ----        ------- ------
    DC01.local.example.com  Ping        ICMP    True
    DC01.local.example.com  DNS         53      False
    DC01.local.example.com  Kerberos    88      True
    DC01.local.example.com  RPC         135     True
    DC01.local.example.com  LDAP        389     True
    DC01.local.example.com  GC          3268    True
    DC01.local.example.com  WinRM       5985    True

PS > $DCStatus.Where({$_.Status -eq $false}).Tests.Where({$_.Passed -eq $false})

    ComputerName            Test        PortNum Passed
    ------------            ----        ------- ------
    DC01.local.example.com  DNS         53      False


Description
-----------
In the above example, DC01 fails one of the tests within 'ADMinimum'. Because 
the details have been sent to the variable 'DCStatus', the user can view the 
complete results, then drill down to see where the failure occured.

.Parameter ComputerName
Specifies the computer name (or names) that should be tested.

.Parameter CommonPort
Specifies the common port to check (in friendly terms). Currently focused on 
Active Directory, additional common ports may be added later. Available options 
include: DNS (53), Kerberos (88), RPC (135), LDAP (389), LDAPssl (636), GC (3268), 
GCssl (3269), RDP (3389), WinRM (5985), WinRMssl (5986), ADWS (9389).

.Parameter CommonService
Specifies the common service to check - a service is comprised of one or more 
ports. Available options include: ADFull (DNS, Kerberos, RPC, LDAP, GC, WinRM), 
ADMinimum (Kerberos, RPC, LDAP), ADssl (DNS, Kerberos, RPC, LDAP, LDAPssl, GC, 
GCssl, WinRM), DNS (DNS)

.Parameter Port
Specifies the port to test. Valid values are 1-65535.

.Parameter InfoVariable
Specifies the variable that should be used for the extended information, 
regarding the test results. This option will evenually be deprecated, though 
for now 'Write-Information' is not commonly available (WMF5 and later); when 
deprecated, the data will be sent to Write-Information and accessable via the 
common InformationVariable parameter.

.Notes

#### Name:       Test-Port
#### Author:     J Schell
#### Version:    0.1.5
#### License:    MIT License

### Change Log

##### 2016-06-24::0.1.5
- Updated 'Port' to accept array of values

##### 2016-06-14::0.1.4
- Updated 'Scope' on 'InfoVariable' to 'global'. Feels dirty, though there doesn't appear to be better way at present
- Added common port 'ADWS'
- Updated CommonPort to accept array of values

##### 2016-06-10::0.1.3
- Had to bump 'Scope' for 'InfoVariable' by 1 (now @2) for functionality within modules...

##### 2016-06-10::0.1.2
- proper help and examples complete

##### 2016-06-10::0.1.1
- may have given myself headache in this refactor... results look reasonable

##### 2016-06-10::0.1.0
- rework of various Test-Port* implementations sitting on disk

#>    
    
    
    [CmdletBinding(DefaultParameterSetName = "PortSet")]
    [OutputType([Bool])]
    Param(
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = "CommonPortSet")]
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = "CommonServiceSet")]
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = "PortSet")]
        [String[]]
        $ComputerName = $env:ComputerName,
        
        [Parameter(Mandatory = $True,
            ParameterSetName = "CommonPortSet")]
        [ValidateSet("DNS", "Kerberos", "RPC", "LDAP", "LDAPssl", "GC", "GCssl", "RDP", "WinRM", "WinRMssl", "ADWS")]
        [String[]]
        $CommonPort,
        
        [Parameter(Mandatory = $True,
            ParameterSetName = "CommonServiceSet")]
        [ValidateSet("ADFull","ADMinimum","ADssl","DNS")]
        [String]
        $CommonService,
        
        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = "PortSet")]
        [ValidateRange(1,65535)]
        [int[]]
        $Port,
        
        [Parameter(Mandatory = $False)]
        [String]
        $InfoVariable
    )
    
    
    Begin {
    
        $portDNS = New-Object -typeName PsObject -Property @{
            Name = "DNS"
            PortNum = 53
        }
        $portKerberos = New-Object -typeName PsObject -Property @{
            Name = "Kerberos"
            PortNum = 88
        }
        $portRPC = New-Object -typeName PsObject -Property @{
            Name = "RPC"
             PortNum = 135
        }
        $portLDAP = New-Object -typeName PsObject -Property @{
            Name = "LDAP"
            PortNum = 389
        }
        $portLDAPssl = New-Object -typeName PsObject -Property @{
            Name = "LDAPssl"
            PortNum = 636
        }
        $portGC = New-Object -typeName PsObject -Property @{
            Name = "GC"
            PortNum = 3268
        }
        $portGCssl = New-Object -typeName PsObject -Property @{
            Name = "GCssl"
            PortNum = 3269
        }
        $portRDP = New-Object -typeName PsObject -Property @{
            Name = "RDP"
            PortNum = 3389
        }
        $portWinRM = New-Object -typeName PsObject -Property @{
            Name = "WinRM"
            PortNum = 5985
        }
        $portWinRMssl = New-Object -typeName PsObject -Property @{
            Name = "WinRMssl"
            PortNum = 5986
        }
        $portADWS = New-Object -typeName PsObject -Property @{
            Name = "ADWS"
            PortNum = 9389
        }
        
        $PortCollection = @()
        if($CommonPort) {
            foreach($Entry in $CommonPort){
                Switch ($Entry) {
                    "DNS" { 
                        $PortCollection += @($portDNS) }
                    "Kerberos" {  
                        $PortCollection += @($portKerberos) }
                    "RPC" { 
                        $PortCollection += @($portRPC) }
                    "LDAP" { 
                        $PortCollection += @($portLDAP) }
                    "LDAPssl" { 
                        $PortCollection += @($portLDAPssl) }
                    "GC" { 
                        $PortCollection += @($portGC) }
                    "GCssl" { 
                        $PortCollection += @($portGCssl) }
                    "RDP" { 
                        $PortCollection += @($portRDP) }
                    "WinRM" { 
                        $PortCollection += @($portWinRM) }
                    "WinRMssl" { 
                        $PortCollection += @($portWinRMssl) }
                    "ADWS" {
                        $PortCollection += @($portADWS) }
                }
            }
        }
        if($CommonService) {
            Switch ($CommonService) {
                "ADFull" { 
                    $PortCollection = @( $portDNS, $portKerberos, $portRPC, $portLDAP, $portGC, $portWinRM, $portADWS )
                }
                "ADMinimum" {
                    $PortCollection = @( $portKerberos, $portRPC, $portLDAP )
                }
                "ADssl" {
                    $PortCollection = @( $portDNS, $portKerberos, $portRPC, $portLDAP, $portLDAPssl ,$portGC, 
                        $portGCssl, $portWinRM, $portADWS )
                }
                "DNS" { $PortCollection = @($portDNS) }
            }
        }
        if($Port) {
			foreach($Entry in $Port){
				$portUser = New-Object -typeName PsObject -Property @{
					Name = 'User Defined'
					PortNum = $Entry
				}
				$PortCollection += @($portUser)
			}
        }
        
        $paramPing = @{
            ComputerName = ''
            Count = 1
            Quiet = $True
        }
        $paramTestPort = @{
            ComputerName = ''
            Port = ''
            InformationLevel = 'Quiet'
            ErrorAction = 'SilentlyContinue'
        }
    }
    Process {
        $InformationStatusAll = @()
        ForEach($Computer in $ComputerName) {
            $status = @()
            $paramPing.ComputerName = $Computer
            $paramTestPort.ComputerName = $Computer
            
            $statusPingBool = Test-Connection @paramPing
            $statusPing = New-Object -typeName PsObject -Property ([ordered]@{
                    ComputerName = $Computer
                    Test = "Ping"
                    PortNum = "ICMP"
                    Passed = $statusPingBool
            })
            
            $status += @($statusPing)
            
            if($statusPingBool){
                ForEach($Entry in $PortCollection) {
                    $paramTestPort.Port = $Entry.PortNum
                    
                    $statusPortBool = Test-NetConnection @paramTestPort
                    $statusPort = New-Object -typeName PsObject -Property ([ordered]@{
                        ComputerName = $Computer
                        Test = "$($Entry.Name)"
                        PortNum = $($Entry.PortNum)
                        Passed = $statusPortBool
                    })
                        
                    $status += @($statusPort)
                }
            }
            if( $status.Passed -contains $False ){
                $statusReturn = $False
            }
            else {
                $statusReturn = $True
            }
            
            $InformationStatus = New-Object -typeName PsObject -Property ([ordered]@{
                    ComputerName = $Computer
                    Label = "Passed Tests"
                    Status = $statusReturn
                    Tests = @()
            })
            
            ForEach( $Check in $status ){
                $InformationStatus.Tests += @($Check)
            }
            
            $InformationStatusAll += @($InformationStatus)
            $statusReturn
        }
        # Not gauranteed to be on WMF5+, can't rely on Write-Information, '-InformationVariable'
        if($InfoVariable){
            New-Variable -Name $($InfoVariable) -Value $InformationStatusAll -Scope Global -Force
        }
    }
}