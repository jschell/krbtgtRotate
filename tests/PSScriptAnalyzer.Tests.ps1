<#
.Synopsis
PSScriptAnalyzer compliance tests for all public and private PowerShell functions.

.Description
Runs PSScriptAnalyzer against all public and private function files. Excludes rules
that have documented justifications within the module (PSAvoidUsingUserNameAndPassWordParams
and PSUseShouldProcessForStateChangingFunctions in New-ComplexPassword).

Requires PSScriptAnalyzer to be installed:
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser

.Example
PS > Invoke-Pester .\PSScriptAnalyzer.Tests.ps1

Description
-----------
Runs PSScriptAnalyzer against all public and private function files and reports
any violations as test failures.

.Notes

#### Name:     PSScriptAnalyzer.Tests
#### Author:   J Schell
#### Version:  0.1.0
#### License:  MIT License

### Change Log

##### 2026-03-01::0.1.0
- Initial creation from code review findings
#>

Set-StrictMode -Version Latest

$TestDir    = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$ModuleRoot = Resolve-Path "$TestDir\.."

$privateFolder = "$ModuleRoot\private"
$publicFolder  = "$ModuleRoot\public"

$allPs1 = @( Get-ChildItem -Path "$privateFolder\*.ps1" -File -Exclude "*.tests.*" )
$allPs1+= @( Get-ChildItem -Path "$publicFolder\*.ps1"  -File -Exclude "*.tests.*" )

# Per-file documented PSSA rule exceptions
# Key = filename, Value = array of rule names to exclude for that file
$perFileExclusions = @{
    'New-ComplexPassword.ps1' = @(
        'PSAvoidUsingUserNameAndPassWordParams'        # documented: evaluating complexity, not storing
        'PSUseShouldProcessForStateChangingFunctions' # documented: not a true state change
    )
    'Test-ComplexPassword.ps1' = @(
        'PSAvoidUsingUserNameAndPassWordParams'        # documented: evaluating complexity, not storing
    )
    'Set-KrbtgtPassword.ps1' = @(
        'PSAvoidUsingUserNameAndPassWordParams'        # documented: plaintext required by AD password reset API
        'PSAvoidUsingPlainTextForPassword'            # documented: intentional, SecureString wrapping done internally
    )
    'Test-PortTCP.ps1' = @(
        'PSReviewUnusedParameter'                     # $foolishPSSAGame: intentional PSSA workaround, documented in code
    )
}

if (-not (Get-Module -ListAvailable -Name 'PSScriptAnalyzer')) {
    Write-Warning "PSScriptAnalyzer module not found. Skipping PSSA tests. Install with: Install-Module PSScriptAnalyzer"
    return
}

Import-Module PSScriptAnalyzer -ErrorAction Stop

Describe "PSScriptAnalyzer compliance" {
    foreach ($file in $allPs1) {
        $exclusions = $perFileExclusions[$file.Name]

        It "$($file.Name) should have no PSScriptAnalyzer violations" {
            $analyzerParams = @{
                Path        = $file.FullName
                Severity    = @('Error', 'Warning')
            }
            if ($exclusions) {
                $analyzerParams['ExcludeRule'] = $exclusions
            }

            $results = Invoke-ScriptAnalyzer @analyzerParams
            $summary = $results |
                Select-Object RuleName, Line, Message |
                Format-Table -AutoSize |
                Out-String

            $results.Count | Should Be 0 -Because `
                "PSScriptAnalyzer found $($results.Count) violation(s) in $($file.Name):`n$summary"
        }
    }
}
