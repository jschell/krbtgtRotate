<#
.Synopsis
AST-based code quality tests for all public and private PowerShell functions.

.Description
Tests for code quality issues detectable via PowerShell AST analysis without
requiring an Active Directory connection or live domain. Catches:
  - Write-Warning calls referencing variables that are never assigned (T1)
  - Use of 'break' outside of a loop or switch statement (T2)
  - Known typos in string literals (T3)
  - Unexpected Global-scope variable creation in public functions (T4)
  - Incomplete error messages in the module loader (T5)

.Example
PS > Invoke-Pester .\Code.Quality.Tests.ps1

Description
-----------
Runs all AST-based code quality tests against the public and private function files.

.Notes

#### Name:     Code.Quality.Tests
#### Author:   J Schell
#### Version:  0.1.0
#### License:  MIT License

### Change Log

##### 2026-03-01::0.1.0
- Initial creation from code review findings
#>

Set-StrictMode -Version Latest

$TestDir   = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$ModuleRoot = Resolve-Path "$TestDir\.."

$privateFolder = "$ModuleRoot\private"
$publicFolder  = "$ModuleRoot\public"

$allPs1    = @( Get-ChildItem -Path "$privateFolder\*.ps1" -File -Exclude "*.tests.*" )
$allPs1   += @( Get-ChildItem -Path "$publicFolder\*.ps1"  -File -Exclude "*.tests.*" )
$publicPs1 = @( Get-ChildItem -Path "$publicFolder\*.ps1"  -File -Exclude "*.tests.*" )


#------------------------------------------------------------------
# T1: Write-Warning must not reference variables that are never assigned in the same function
#------------------------------------------------------------------
Describe "T1 - Write-Warning variable safety" {
    foreach ($file in $allPs1) {
        It "$($file.Name) - Write-Warning should not reference undefined variables" {
            $src  = Get-Content $file.FullName -Raw
            $ast  = [System.Management.Automation.Language.Parser]::ParseInput($src, [ref]$null, [ref]$null)

            $warnCalls = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.CommandElements.Count -ge 2 -and
                $node.CommandElements[0].Value -eq 'Write-Warning'
            }, $true)

            foreach ($call in $warnCalls) {
                $argExpr = $call.CommandElements[1]
                if ($argExpr -is [System.Management.Automation.Language.VariableExpressionAst]) {
                    $varName = $argExpr.VariablePath.UserPath
                    $assignments = $ast.FindAll({
                        param($n)
                        $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                        $n.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
                        $n.Left.VariablePath.UserPath -eq $varName
                    }, $true)
                    $assignments.Count | Should BeGreaterThan 0 `
                        -Because "Write-Warning at line $($argExpr.Extent.StartLineNumber) uses `$$varName which must be assigned somewhere in $($file.Name)"
                }
            }
        }
    }
}


#------------------------------------------------------------------
# T2: 'break' must not appear outside a loop or switch statement
#------------------------------------------------------------------
Describe "T2 - No 'break' outside loop or switch" {
    foreach ($file in $allPs1) {
        It "$($file.Name) - 'break' should only appear inside a loop or switch" {
            $src    = Get-Content $file.FullName -Raw
            $ast    = [System.Management.Automation.Language.Parser]::ParseInput($src, [ref]$null, [ref]$null)
            $breaks = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.BreakStatementAst]
            }, $true)

            foreach ($brk in $breaks) {
                $parent = $brk.Parent
                $inLoop = $false
                while ($null -ne $parent) {
                    if ($parent -is [System.Management.Automation.Language.LoopStatementAst] -or
                        $parent -is [System.Management.Automation.Language.SwitchStatementAst]) {
                        $inLoop = $true
                        break
                    }
                    $parent = $parent.Parent
                }
                $inLoop | Should Be $true `
                    -Because "'break' at line $($brk.Extent.StartLineNumber) in $($file.Name) is not inside a loop or switch"
            }
        }
    }
}


#------------------------------------------------------------------
# T3: No known typos in string literals
#------------------------------------------------------------------
$knownTypos = [ordered]@{
    'obseved'  = 'observed'
    'Obseved'  = 'Observed'
    'recieve'  = 'receive'
    'occurence'= 'occurrence'
    'existance'= 'existence'
}

Describe "T3 - No known typos in string literals" {
    foreach ($file in $allPs1) {
        $src     = Get-Content $file.FullName -Raw
        $ast     = [System.Management.Automation.Language.Parser]::ParseInput($src, [ref]$null, [ref]$null)
        $strings = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.StringConstantExpressionAst]
        }, $true)

        foreach ($typo in $knownTypos.Keys) {
            It "$($file.Name) - should not contain typo '$typo'" {
                $hits = $strings | Where-Object { $_.Value -match [regex]::Escape($typo) }
                $hits.Count | Should Be 0 `
                    -Because "String literal(s) in $($file.Name) contain known typo '$typo'"
            }
        }
    }
}


#------------------------------------------------------------------
# T4: No unexpected Global-scoped variable creation in public functions
#------------------------------------------------------------------
$allowedGlobalFiles = @('Test-Port.ps1', 'Test-PortTCP.ps1')

Describe "T4 - No unexpected Global variable creation" {
    $restrictedPs1 = $publicPs1 | Where-Object { $_.Name -notin $allowedGlobalFiles }

    foreach ($file in $restrictedPs1) {
        It "$($file.Name) - should not create Global-scoped variables" {
            $content = Get-Content $file.FullName -Raw
            $content | Should Not Match 'New-Variable\s.*-Scope\s+Global'
        }
    }
}


#------------------------------------------------------------------
# T5: Module loader should not contain incomplete 'S_' error message
#------------------------------------------------------------------
Describe "T5 - Module loader error messages are complete" {
    It "krbtgtRotate.psm1 should not contain incomplete 'S_' error string" {
        $content = Get-Content "$ModuleRoot\krbtgtRotate.psm1" -Raw
        $content | Should Not Match '"Error observed! S_"'
    }

    It "krbtgtRotate.psm1 catch blocks should emit errors to the error stream, not success stream" {
        $content = Get-Content "$ModuleRoot\krbtgtRotate.psm1" -Raw
        # Bare string literals (output to success stream) in catch blocks are a smell
        # Test that no bare quoted string immediately follows 'catch {'
        $content | Should Not Match 'catch\s*\{[^}]*"Error observed'
    }
}
