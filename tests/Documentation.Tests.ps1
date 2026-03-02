<#
.Synopsis
Tests that markdown documentation and PowerShell help files do not contain template
placeholder strings.

.Description
Validates the docs\ markdown files and en-us\about_krbtgtRotate.help.txt for
common template strings that indicate unfinished documentation. Does not require
an Active Directory connection or PowerShell module import.

.Example
PS > Invoke-Pester .\Documentation.Tests.ps1

Description
-----------
Tests all documentation files in the docs\ folder and en-us\ help file for
placeholder/template content.

.Notes

#### Name:     Documentation.Tests
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
$DocsFolder = Join-Path $ModuleRoot 'docs'
$AboutFile  = Join-Path $ModuleRoot 'en-us\about_krbtgtRotate.help.txt'


#------------------------------------------------------------------
# Markdown documentation placeholder checks
#------------------------------------------------------------------
Describe "Markdown documentation - no template placeholders" {
    $mdFiles = @( Get-ChildItem -Path $DocsFolder -Filter '*.md' -File -Recurse )

    foreach ($doc in $mdFiles) {
        $content = Get-Content $doc.FullName -Raw

        Context "$($doc.Name)" {
            It "should not contain '{{Manually Enter' template placeholders" {
                $content | Should Not Match '\{\{Manually Enter'
            }

            It "should not contain 'Please enter FwLink' placeholder" {
                $content | Should Not Match 'Please enter FwLink'
            }

            It "should not contain 'Please enter version' placeholder" {
                $content | Should Not Match 'Please enter version'
            }

            It "should not have a 'Brief description' SYNOPSIS placeholder" {
                $content | Should Not Match '(?m)^Brief description\s*$'
            }

            It "should not have a 'Detailed description' DESCRIPTION placeholder" {
                $content | Should Not Match '(?m)^Detailed description\s*$'
            }

            It "should not contain 'Verb-Noun -Parameter' template example text" {
                $content | Should Not Match 'Verb-Noun\s+-Parameter'
            }

            It "should not contain '{{Fill' placeholder text" {
                $content | Should Not Match '\{\{Fill'
            }
        }
    }
}


#------------------------------------------------------------------
# about_krbtgtRotate.help.txt content checks
#------------------------------------------------------------------
Describe "about_krbtgtRotate.help.txt - no placeholder content" {
    $aboutContent = Get-Content $AboutFile -Raw

    It "should not contain 'Summary of the module' placeholder" {
        $aboutContent | Should Not Match 'Summary of the module'
    }

    It "should not contain 'Longer description of the module' placeholder" {
        $aboutContent | Should Not Match 'Longer description of the module'
    }

    It "LONG DESCRIPTION section should contain meaningful content (more than 5 non-blank lines)" {
        $longDescBlock = ($aboutContent -split 'LONG DESCRIPTION')[1] -split 'KEYWORDS' |
            Select-Object -First 1
        $nonBlankLines = ($longDescBlock.Trim() -split '\r?\n') |
            Where-Object { $_.Trim() -ne '' }
        $nonBlankLines.Count | Should BeGreaterThan 5 `
            -Because "LONG DESCRIPTION should contain real module documentation"
    }

    It "KEYWORDS section should be non-empty" {
        $keywordsBlock = ($aboutContent -split 'KEYWORDS')[1] -split 'SEE ALSO' |
            Select-Object -First 1
        $keywordsBlock.Trim() | Should Not BeNullOrEmpty `
            -Because "KEYWORDS should list relevant search terms"
    }

    It "SEE ALSO section should list at least one cmdlet" {
        $seeAlsoBlock = ($aboutContent -split 'SEE ALSO')[1]
        $seeAlsoBlock.Trim() | Should Not BeNullOrEmpty `
            -Because "SEE ALSO should reference related cmdlets"
    }
}


#------------------------------------------------------------------
# README checks
#------------------------------------------------------------------
Describe "ReadMe.md - required sections present" {
    $readmeFile = Join-Path $ModuleRoot 'ReadMe.md'
    $readmeContent = Get-Content $readmeFile -Raw

    It "should contain a Required Privileges section" {
        $readmeContent | Should Match '##\s+Required Privileges'
    }

    It "should contain a Troubleshooting section" {
        $readmeContent | Should Match '##\s+Troubleshooting'
    }

    It "should contain rollback or recovery guidance" {
        $readmeContent | Should Match '(?i)rollback|recovery'
    }

    It "should contain post-rotation validation guidance" {
        $readmeContent | Should Match '(?i)validation|verify|replication'
    }
}
