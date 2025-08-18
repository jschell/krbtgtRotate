---
external help file: krbtgtRotate-help.xml
online version: https://technet.microsoft.com/en-us/library/cc786468.aspx
schema: 2.0.0
---

# Test-Port
## SYNOPSIS
Test connectivity to one or more computers.
Requires PowerShell version 4 or later.

## SYNTAX

### PortSet (Default)
```
Test-Port [-ComputerName <String[]>] -Port <Int32[]> [-InfoVariable <String>]
```

### CommonServiceSet
```
Test-Port [-ComputerName <String[]>] -CommonService <String> [-InfoVariable <String>]
```

### CommonPortSet
```
Test-Port [-ComputerName <String[]>] -CommonPort <String[]> [-InfoVariable <String>]
```

## DESCRIPTION
Test connectivity to one or more computers.
Primary goal of this cmdlet was to 
test connectivity against specific ports, using methods available in Constrained 
Language Mode.
This cmdlet uses Test-Connection and Test-NetConnection.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

	PS > Test-Port -Port 135
	
	True

Description
-----------
When no computer name is specified, the check will be against the local machine. 
Because the machine responded for ping, and port 135, the result was 'True'.

### -------------------------- EXAMPLE 2 --------------------------

	PS > Test-Port -ComputerName NotOnline -CommonPort RPC
	
	False

Description
-----------
If the computer fails one or more of the connectivity checks, the result will be 'False'

### -------------------------- EXAMPLE 3 --------------------------

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
In the above example, DC01 fails one of the tests within 'ADMinimum'.
Because 
the details have been sent to the variable 'DCStatus', the user can view the 
complete results, then drill down to see where the failure occured.

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

### -InfoVariable
Specifies the variable that should be used for the extended information, 
regarding the test results.
This option will evenually be deprecated, though 
for now 'Write-Information' is not commonly available (WMF5 and later); when 
deprecated, the data will be sent to Write-Information and accessable via the 
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
#### Name:       Test-Port
#### Author:     J Schell
#### Version:    0.1.5
#### License:    MIT License

### Change Log

##### 2016-06-24::0.1.5
- Updated 'Port' to accept array of values

##### 2016-06-14::0.1.4
- Updated 'Scope' on 'InfoVariable' to 'global'.
Feels dirty, though there doesn't appear to be better way at present
- Added common port 'ADWS'
- Updated CommonPort to accept array of values

##### 2016-06-10::0.1.3
- Had to bump 'Scope' for 'InfoVariable' by 1 (now @2) for functionality within modules...

##### 2016-06-10::0.1.2
- proper help and examples complete

##### 2016-06-10::0.1.1
- may have given myself headache in this refactor...
results look reasonable

##### 2016-06-10::0.1.0
- rework of various Test-Port* implementations sitting on disk

## RELATED LINKS

