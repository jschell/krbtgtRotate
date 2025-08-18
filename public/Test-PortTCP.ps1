function Test-PortTCP {
<#
.Synopsis
Test connectivity to one or more computers. Requires PowerShell full language mode.

.Description
Test connectivity to one or more computers. Primary goal of this cmdlet was to 
test connectivity against specific ports, using pre-PSv4 hosts. This is specifically
to support backwards compatibility on older environments.

-Required modules
    None
-Required functions
    None
-PS Script Analyzer exceptions 
    None
    
.Example
PS > Test-PortTCP -Port 135
    True

Description
-----------
When no computer name is specified, the check will be against the local machine. 
Because the machine responded for ping, and port 135, the result was 'True'.

.Example
PS > Test-PortTCP -ComputerName NotOnline -CommonPort RPC
    False

Description
-----------
If the computer fails one or more of the connectivity checks, the result will be 'False'

.Example
PS > Get-ADDomainController -Filter * | Select -ExpandProperty Hostname
    DC01.local.contoso.com
    DC02.local.contoso.com
    
PS > Test-PortTCP -ComputerName (Get-ADDomainController -Filter * | Select -ExpandProperty HostName) -CommonService ADMinimum -InfoVariable DCStatus
    False
    True

PS > $DCStatus.Where({$_.Status -eq $false})

    ComputerName            Label           Status  Tests
    ------------            -----           ------  -----
    DC01.local.contoso.com  Passed Tests    False   {@{ComputerName=DC01.local.contoso.co...

PS > $DCStatus.Where({$_.Status -eq $false}).Tests

    ComputerName            Test        PortNum Passed
    ------------            ----        ------- ------
    DC01.local.contoso.com  Ping        ICMP    True
    DC01.local.contoso.com  DNS         53      False
    DC01.local.contoso.com  Kerberos    88      True
    DC01.local.contoso.com  RPC         135     True
    DC01.local.contoso.com  LDAP        389     True
    DC01.local.contoso.com  GC          3268    True
    DC01.local.contoso.com  WinRM       5985    True

PS > $DCStatus.Where({$_.Status -eq $false}).Tests.Where({$_.Passed -eq $false})

    ComputerName            Test        PortNum Passed
    ------------            ----        ------- ------
    DC01.local.contoso.com  DNS         53      False


Description
-----------
In the above example, DC01 fails one of the tests within 'ADMinimum'. Because 
the details have been sent to the variable 'DCStatus', the user can view the 
complete results, then drill down to see where the failure occurred.

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

.Parameter Timeout
Specifies the timeout in milliseconds.

.Parameter InfoVariable
Specifies the variable that should be used for the extended information, 
regarding the test results. This option will eventually be deprecated, though 
for now 'Write-Information' is not commonly available (WMF5 and later); when 
deprecated, the data will be sent to Write-Information and accessible via the 
common InformationVariable parameter.

.Notes

#### Name:       Test-PortTCP
#### Author:     J Schell
#### Version:    0.2.0
#### License:    MIT License

### Change Log

##### 2017-03-22::0.2.0
-Spelling + PSSA fixes

##### 2016-07-06::0.1.0
- Implementation of Test-Port (constrained language mode capable, PSv4+) using System.Net.* in order to support older clients/ environments.

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
        
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = "CommonPortSet")]
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = "CommonServiceSet")]
        [Parameter(Mandatory = $False,
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = "PortSet")]
        [ValidateRange(10,60000)]
        [int]
        $Timeout = 1000,
        
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
    }
    Process {
        $InformationStatusAll = @()
        ForEach($Computer in $ComputerName) {
            $status = @()

            $pingObject = New-Object System.Net.NetworkInformation.Ping
            try {
                $pingTest = $pingObject.Send($Computer)
            }
            catch {
                Write-Verbose $_
            }
            if($pingTest.Status -eq "Success"){
                $statusPingBool = $True
            }
            else {
                $statusPingBool = $False
            }
            $pingObject.Dispose()
            
            $statusPing = New-Object -typeName PsObject -Property ([ordered]@{
                    ComputerName = $Computer
                    Test = "Ping"
                    PortNum = "ICMP"
                    Passed = $statusPingBool
            })
            $status += @($statusPing)
            if($statusPingBool){
                ForEach($Entry in $PortCollection) {
                    $targetPort = $Entry.PortNum
                    
                    $tcpObject = New-Object System.Net.Sockets.TcpClient
                    $tcpTest = $tcpObject.BeginConnect($Computer,$targetPort,$null,$null)
                    $tcpWait = $tcpTest.AsyncWaitHandle.WaitOne($Timeout,$False)
                    # This section exists to make PSSA not squawk
                    $foolishPSSAGame = @()
                    $foolishPSSAGame += @( $tcpWait )
                    $foolishPSSAGame = $null 
                    # End of PSSA-no-squawk
                    $statusPortBool = $tcpObject.Connected

                    $statusPort = New-Object -typeName PsObject -Property ([ordered]@{
                        ComputerName = $Computer
                        Test = "$($Entry.Name)"
                        PortNum = $($Entry.PortNum)
                        Passed = $statusPortBool
                    })    
                    $status += @($statusPort)
                    $tcpObject.Dispose()
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
            
        if($InfoVariable){
            New-Variable -Name $($InfoVariable) -Value $InformationStatusAll -Scope Global -Force
        }
    }
}