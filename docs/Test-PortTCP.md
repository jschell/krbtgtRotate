---
external help file: krbtgtRotate-help.xml
online version: https://technet.microsoft.com/en-us/library/cc786468.aspx
schema: 2.0.0
---

# Test-PortTCP
## SYNOPSIS
Test connectivity to one or more computers.
Requires PowerShell full language mode.

## SYNTAX

### PortSet (Default)
```
Test-PortTCP [-ComputerName <String[]>] -Port <Int32[]> [-Timeout <Int32>] [-InfoVariable <String>]
```

### CommonServiceSet
```
Test-PortTCP [-ComputerName <String[]>] -CommonService <String> [-Timeout <Int32>] [-InfoVariable <String>]
```

### CommonPortSet
```
Test-PortTCP [-ComputerName <String[]>] -CommonPort <String[]> [-Timeout <Int32>] [-InfoVariable <String>]
```

## DESCRIPTION
Test connectivity to one or more computers.
Primary goal of this cmdlet was to 
test connectivity against specific ports, using pre-PSv4 hosts.
This is specifically
to support backwards compatibility on older environments.

-Required modules
    None
-Required functions
    None
-PS Script Analyzer exceptions 
    None

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

	PS > Test-PortTCP -Port 135
	
	True

Description
-----------
When no computer name is specified, the check will be against the local machine. 
Because the machine responded for ping, and port 135, the result was 'True'.

### -------------------------- EXAMPLE 2 --------------------------

	PS > Test-PortTCP -ComputerName NotOnline -CommonPort RPC
	
	False

Description
-----------
If the computer fails one or more of the connectivity checks, the result will be 'False'

### -------------------------- EXAMPLE 3 --------------------------

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
In the above example, DC01 fails one of the tests within 'ADMinimum'.
Because 
the details have been sent to the variable 'DCStatus', the user can view the 
complete results, then drill down to see where the failure occurred.

## PARAMETERS

### -ComputerName
Specifies the computer name (or names) that should be tested.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: $env:ComputerName
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -CommonPort
Specifies the common port to check (in friendly terms).
Currently focused on 
Active Directory, additional common ports may be added later.
Available options 
include: DNS (53), Kerberos (88), RPC (135), LDAP (389), LDAPssl (636), GC (3268), 
GCssl (3269), RDP (3389), WinRM (5985), WinRMssl (5986), ADWS (9389).

```yaml
Type: String[]
Parameter Sets: CommonPortSet
Aliases: 

Required: True
Position: Named
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommonService
Specifies the common service to check - a service is comprised of one or more 
ports.
Available options include: ADFull (DNS, Kerberos, RPC, LDAP, GC, WinRM), 
ADMinimum (Kerberos, RPC, LDAP), ADssl (DNS, Kerberos, RPC, LDAP, LDAPssl, GC, 
GCssl, WinRM), DNS (DNS)

```yaml
Type: String
Parameter Sets: CommonServiceSet
Aliases: 

Required: True
Position: Named
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port
Specifies the port to test.
Valid values are 1-65535.

```yaml
Type: Int32[]
Parameter Sets: PortSet
Aliases: 

Required: True
Position: Named
Default value: 
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Timeout
Specifies the timeout in milliseconds.

```yaml
Type: Int32
Parameter Sets: PortSet
Aliases: 

Required: False
Position: Named
Default value: 1000
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: Int32
Parameter Sets: CommonServiceSet, CommonPortSet
Aliases: 

Required: False
Position: Named
Default value: 1000
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -InfoVariable
Specifies the variable that should be used for the extended information, 
regarding the test results.
This option will eventually be deprecated, though 
for now 'Write-Information' is not commonly available (WMF5 and later); when 
deprecated, the data will be sent to Write-Information and accessible via the 
common InformationVariable parameter.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.Boolean

## NOTES
#### Name:       Test-PortTCP
#### Author:     J Schell
#### Version:    0.2.0
#### License:    MIT License

### Change Log

##### 2017-03-22::0.2.0
-Spelling + PSSA fixes

##### 2016-07-06::0.1.0
- Implementation of Test-Port (constrained language mode capable, PSv4+) using System.Net.* in order to support older clients/ environments.

## RELATED LINKS

