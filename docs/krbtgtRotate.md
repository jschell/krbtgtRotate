---
Module Name: krbtgtRotate
Module Guid: 3671deb0-f711-488e-b41f-eda82b1c79e5
Download Help Link: https://github.com/jschell/krbtgtRotate
Help Version: 0.2.2.0
Locale: en-US
---

# krbtgtRotate Module
## Description
PowerShell module for safely rotating the Active Directory krbtgt account password without disrupting Kerberos authentication. Manages prerequisite validation, pre-rotate sync, password change, post-rotate sync, and structured logging across all writable domain controllers.

## krbtgtRotate Cmdlets
### [Get-KrbtgtPasswordMinimumAge](Get-KrbtgtPasswordMinimumAge.md)
Returns the minimum required wait time between krbtgt password rotations, calculated from the Kerberos TGT lifetime and maximum clock skew defined in domain policy.

### [Invoke-KrbtgtPasswordRotate](Invoke-KrbtgtPasswordRotate.md)
Orchestrates a safe krbtgt password rotation including prerequisite validation, pre-rotate DC sync, password change on the PDC Emulator, and post-rotate DC sync across all writable domain controllers.

### [New-ComplexPassword](New-ComplexPassword.md)
Generates a new, complex password of specified length that meets Active Directory password complexity requirements. Password can be a fixed length or within a minimum/maximum range.

### [Register-KrbtgtEventLog](Register-KrbtgtEventLog.md)
Registers the krbtgtRotate event log source in the Windows Event Log. Must be run once before executing a rotation so that rotation events can be written to the log.

### [Set-KrbtgtPassword](Set-KrbtgtPassword.md)
Sets the krbtgt account password directly on the specified domain controller. Called internally by Invoke-KrbtgtPasswordRotate; can also be used standalone for manual password operations.

### [Test-ComplexPassword](Test-ComplexPassword.md)
Tests whether a given string meets Active Directory password complexity requirements, optionally checking that the password does not contain the user's SamAccountName or DisplayName segments.

### [Test-Port](Test-Port.md)
Tests TCP network connectivity to one or more computers on specified ports or common AD service port groups. Requires PowerShell 4 or later; uses Test-NetConnection internally.

### [Test-PortTCP](Test-PortTCP.md)
Tests TCP network connectivity using System.Net.Sockets. Compatible with PowerShell 3 and later; used as a fallback when Test-Port is unavailable (pre-PS4 environments).

### [Write-KrbtgtEventLog](Write-KrbtgtEventLog.md)
Writes a structured Windows Event Log entry during the krbtgt rotation process using a computed EventID based on the rotation phase (krbtgt, sync, online) and message severity.

### [Write-LogMessage](Write-LogMessage.md)
Appends a timestamped, categorized message entry to a disk log file. Supports fallback to the system temp directory if the specified output path is unavailable.
