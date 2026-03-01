# krbtgtRotate

> ⚠️ **WARNING:**  
> The `krbtgt` account is a special built-in account in Active Directory used by the Kerberos Key Distribution Center (KDC) to encrypt and sign all Kerberos tickets within the domain.  
> **Improper rotation or mishandling of the `krbtgt` password can result in domain-wide authentication failures, service outages, or loss of access for users and computers.**  
> Only experienced administrators should use this module, and all actions must be thoroughly tested in a non-production environment before any production use.

## Introduction

krbtgtRotate is a PowerShell module for safely rotating the `krbtgt` account password in Active Directory environments. It ensures password changes do not disrupt Kerberos authentication by considering ticket lifetimes and clock skew.

## Requirements

- PowerShell 3.0 or later
- Active Directory module
- GroupPolicy module
- Sufficient privileges to reset the `krbtgt` password and write to event logs

## Required Privileges

The account executing this module must have:
- **Domain Admins** membership or equivalent delegation to reset the `krbtgt` password
- Local administrator rights on the machine running the module (elevated PowerShell session required)
- Rights to register and write to the Windows Event Log source (`Register-KrbtgtEventLog` requires admin)

Run PowerShell **as Administrator**. The module detects a non-elevated session and stops with an error before making any changes.

## Installation

1. Download or clone the repository.
2. Import the module in your PowerShell session:
   ```powershell
   Import-Module .\krbtgtRotate.psd1
   ```

## Getting Started

### 1. Register the Event Log Source

Before rotating the password, register the event log source:
```powershell
Register-KrbtgtEventLog
```
This ensures logging is set up for auditing and troubleshooting.

### 2. Check Minimum Password Age

Verify how long you must wait between rotations:
```powershell
Get-KrbtgtPasswordMinimumAge
```

### 3. Rotate the krbtgt Password

To safely rotate the password:
```powershell
Invoke-KrbtgtPasswordRotate -Force
```
This command will orchestrate the rotation, sync, and logging.

### 4. Review Logs

Logs are written to both the event log and a file (default: current directory). Check these for status and errors.

## Step-by-Step: First Rotation

1. Open PowerShell **as Administrator** on a machine with RSAT (Active Directory and GroupPolicy modules installed).
2. Import the module:
   ```powershell
   Import-Module .\krbtgtRotate.psd1
   ```
3. Register the event log source (one-time setup):
   ```powershell
   Register-KrbtgtEventLog
   ```
4. Check the minimum wait time between rotations:
   ```powershell
   Get-KrbtgtPasswordMinimumAge
   # Returns a TimeSpan, e.g.: 10:10:00 (10 hours 10 minutes)
   ```
5. Confirm the current password is old enough:
   ```powershell
   (Get-ADUser krbtgt -Properties PasswordLastSet).PasswordLastSet
   # Compare to: (Get-Date) - (Get-KrbtgtPasswordMinimumAge)
   ```
6. Run a WhatIf dry run to confirm all prerequisites pass:
   ```powershell
   Invoke-KrbtgtPasswordRotate -WhatIf
   ```
7. Execute the rotation with an explicit log path:
   ```powershell
   Invoke-KrbtgtPasswordRotate -LogPath "C:\logs\krbtgtRotate" -Force
   ```
8. Review the log file in `C:\logs\krbtgtRotate\` and the Directory Service event log.

## What to Expect

A successful rotation produces no errors to the console. With `-Verbose`:
```
VERBOSE: krbtgt password was last set: <datetime>
VERBOSE: 'krbtgt' password was set before 10:10:00 ago.
VERBOSE: PDCEmulator responded to connection tests.
VERBOSE: Pre-rotate sync starting across all writable domain controllers...
VERBOSE: Successfully rotated the password for krbtgt.
VERBOSE: Post-rotate sync starting across all writable domain controllers...
VERBOSE: Password rotation completed!
```

A timestamped log file is written to the directory specified by `-LogPath` (default: current directory). Event Log entries are written to the `Directory Service` log under the source `krbtgtRotation`.

## Post-Rotation Validation

After rotation, confirm the password was changed:
```powershell
(Get-ADUser krbtgt -Properties PasswordLastSet -Server (Get-ADDomain).PDCEmulator).PasswordLastSet
```
This should return a timestamp within the last few minutes.

Verify replication across all domain controllers:
```powershell
Get-ADReplicationPartnerMetadata -Target (Get-ADDomain).DNSRoot -Scope Domain |
    Select-Object Partner, LastReplicationSuccess, LastReplicationResult
```
All domain controllers should show a recent `LastReplicationSuccess` and `LastReplicationResult` of 0 (success).

## Rollback and Recovery

**There is no automated rollback.** The krbtgt password cannot be reverted once changed.

If the rotation fails mid-way (e.g., post-rotate sync fails):
1. **Do not rotate again immediately.** A second rotation before the minimum age elapses will invalidate all existing Kerberos tickets and cause domain-wide authentication failures.
2. Wait for the minimum age period to elapse (see `Get-KrbtgtPasswordMinimumAge`).
3. Force AD replication manually: `repadmin /syncall /AdeP`
4. Review the rotation log file and event log to identify which DC failed to sync.
5. Once all DCs have converged on the new password, attempt the next scheduled rotation.

If users report authentication failures immediately after rotation, tickets issued before the change are now invalid. This resolves itself within the Kerberos ticket lifetime (default 10 hours). Service accounts may need to be restarted to obtain new tickets.

## Example Usage

```powershell
# Register event log source
Register-KrbtgtEventLog

# Check minimum age before rotation
Get-KrbtgtPasswordMinimumAge

# Rotate password with default settings
Invoke-KrbtgtPasswordRotate -Force
```

## Documentation

See the [docs/](docs/) folder for detailed cmdlet documentation:
- [Get-KrbtgtPasswordMinimumAge](docs/Get-KrbtgtPasswordMinimumAge.md)
- [Invoke-KrbtgtPasswordRotate](docs/Invoke-KrbtgtPasswordRotate.md)
- [Set-KrbtgtPassword](docs/Set-KrbtgtPassword.md)
- [Register-KrbtgtEventLog](docs/Register-KrbtgtEventLog.md)
- [Write-KrbtgtEventLog](docs/Write-KrbtgtEventLog.md)
- [Write-LogMessage](docs/Write-LogMessage.md)
- [New-ComplexPassword](docs/New-ComplexPassword.md)
- [Test-ComplexPassword](docs/Test-ComplexPassword.md)
- [Test-Port](docs/Test-Port.md)
- [Test-PortTCP](docs/Test-PortTCP.md)

See the [docs/plans/](docs/plans/) folder for code review and improvement tracking documents.

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---|---|---|
| `The powershell session must be run in an elevated context` | PowerShell not launched as Administrator | Close and reopen PowerShell as Administrator |
| `'krbtgt' password needs to age: HH:MM:SS` | Rotation attempted too soon after last rotation | Wait the indicated time, then retry |
| `'<ComputerName>' is not the PDCEmulator` | ComputerName parameter does not match PDC Emulator | Omit ComputerName to auto-detect PDCe |
| Cannot reach PDC Emulator on RPC/LDAP ports | Network or firewall issue | `Test-Port -ComputerName <PDCe> -CommonService ADMinimum` |
| `Insufficient access rights to perform operation` | Running account lacks replication permissions | Verify Domain Admin membership |
| `No matches found for krbtgt` | krbtgtSamAccountName is incorrect | `Get-ADUser -Filter "SamAccountName -eq 'krbtgt'"` |
| Module fails to import | ActiveDirectory or GroupPolicy module not found | Install RSAT: `Add-WindowsFeature RSAT-AD-PowerShell` |
| Log file not found at expected path | LogPath did not exist; fallback to $env:Temp used | Check $env:Temp for the log file; specify a valid -LogPath |

## Responsibility and Warranty

This module is provided as-is, with no warranty, express or implied.  
Users are solely responsible for thoroughly testing all functionality in a safe, non-production environment before deploying in production.  
The authors and contributors accept no liability for any issues or damages resulting from the use of this code.