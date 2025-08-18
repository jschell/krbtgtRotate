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

## Troubleshooting

- Ensure you run PowerShell as an administrator.
- Review event logs and output files for errors.
- Confirm all required modules are available.

## Responsibility and Warranty

This module is provided as-is, with no warranty, express or implied.  
Users are solely responsible for thoroughly testing all functionality in a safe, non-production environment before deploying in production.  
The authors and contributors accept no liability for any issues or damages resulting from the use of this code.