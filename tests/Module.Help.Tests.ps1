<#
.Synopsis
Basic test for validating help has been filled in correctly for all functions
exported by the base module.

.Description
Test for synopsis, description, examples, non-default parameters being present 
in the help. Also checks for name, author, version and license.

All functions exported will be evaluated.

This test expects to be in the following directory structure:
.\[ModuleName]
    .\private
        myFancyPrivateFunction.ps1
    .\public
        myPlainPublicFunction.ps1
    .\tests
        Module.Help.Tests.ps1
    [ModuleName].psd1
    [ModuleName].psm1

.Example
PS > invoke-pester Module.Help.Tests.ps1

Description
-----------
Tests if the exported functions have properly completed help.

.Link
 https://github.com/juneb/PesterTDD/blob/master/Module.Help.Tests.ps1

.Link
 https://github.com/devblackops/POSHOrigin/blob/master/Tests/Help.tests.ps1

.Link
 http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html

.NOTES

#### Name:     Module.Help.Tests
#### Author:   J Schell
#### Version:  0.2.2
#### License:  MIT License

### Change Log

##### 2017-03-21::0.2.2
-format parameters for function and help as array, even if single parameter

##### 2017-03-21::0.2.1
-add try/catch for notes, parameters

##### 2017-03-21::0.2.0
-large scale re-work
-fork of prior design that used 'Help.[FunctionName].Test.ps1' style (per function)
-Test all functions exported by the module

##### 2016-05-27::0.1.0
- initial creation 
#>


Set-StrictMode -Version Latest

$TestDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$ModuleBase = Resolve-Path "$TestDir\.." 
$ModuleName = Split-Path -Path $ModuleBase -Leaf
$ModuleManifestPath = "$($ModuleBase)\$($ModuleName).psd1"

# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module -Force
$Module = Import-Module $ModuleManifestPath -Force -ErrorAction Stop -PassThru
$ExportedFunction = Get-Command -Module $Module -CommandType Cmdlet, Function, Workflow  # Not alias

## When testing help, remember that help is cached at the beginning of each session.
## To test, restart session.

foreach ($function in $ExportedFunction)
{
	$functionName = $function.Name
	
	# The module-qualified command fails on Microsoft.PowerShell.Archive cmdlets
	$Help = Get-Help -Name $functionName -ErrorAction SilentlyContinue -Online:$false
	# If no parameters are defined, continue with testing and use empty array
	Try
	{
		# Wrap the parameter set in @() to force the object to be an array, even if only single object
		$HelpParameters = @( $Help.Parameters.Parameter	)
	}
	Catch
	{
		$HelpParameters = @()
	}
	
	$functionAST = (Get-Command -Name $functionName).ScriptBlock.AST.Body
    # If no parameters are defined, continue with testing and use empty array
    Try 
    {
        # Wrap the parameter set in @() to force the object to be an array, even if only single object
        $functionASTParameters = @($functionAST.ParamBlock.Parameters.Name.VariablePath.UserPath)
    }
    Catch 
    {
        $functionASTParameters = @()
    }

	Describe "Test help for $functionName" {
		Context "Test synopsis, description and examples for $functionName"{
			# If help is not found, synopsis in auto-generated help is the syntax diagram
			It "should not be auto-generated" {
				$Help.Synopsis | Should Not BeLike '*`[`<CommonParameters`>`]*'
			}
			
			# Should be a description for every function
			It "gets description for $functionName" {
				$Help.Description | Should Not BeNullOrEmpty
			}

			# Should be at least one example
			It "gets example code from $functionName" {
				($Help.Examples.Example | 
					Select-Object -First 1).Code | Should Not BeNullOrEmpty
			}
			
			# Should be at least one example description
			It "gets example help from $functionName" {
				($Help.Examples.Example.Remarks | 
					Select-Object -First 1).Text | Should Not BeNullOrEmpty
			}	
		}

		Context "Test parameter help for $functionName"{		
			It 'should contain a matching number of .PARAMETER blocks for all defined parameters' {
				$NamedArgs = try { $functionAST.ParamBlock.Attributes.NamedArguments } 
				catch { $NamedArgs = @() }

				if ($NamedArgs -and $NamedArgs.ArgumentName -contains 'SupportsShouldProcess') 
				{
					# Accounting for -WhatIf and -Confirm
					$functionParamCount = $functionASTParameters.Count + 2 
				}
				else
				{
					$functionParamCount = $functionASTParameters.Count
				}

				$HelpParameters.Count | Should Be $functionParamCount
			}
			
			# Parameter Description
			ForEach( $Parameter in $HelpParameters ) 
			{
				if ($functionASTParameters -contains $Parameter.Name) 
				{
					It "should contain a .PARAMETER block for the following parameter: $($Parameter.Name)" {
						$Parameter.Description | Should Not BeNullOrEmpty
					}
				}
			}
		}
		# Notes should exist, contain name of function, author, version, and license
        Context "Test notes for `'$functionName`'" {
			# if notes are not properly formatted or not available, continue with empty set
			Try
            {
                $notes = @(($help.AlertSet.Alert.Text) -split '\n')
            }
            Catch
            {
                $notes = ""
            }

            It "Notes attribute `'name`' should contain $functionName" {
                $notesName = $notes | Select-String -pattern "Name:\s*"
                $notesName | Should Match "Name:\s*$($functionName)"
            }
            
            It "Notes attribute `'author`' should exist" {
                $notesAuthor = $notes | Select-String -pattern "Author:"
                $notesAuthor | Should Match "Author:*"
            }
            
            It "Notes attribute `'version`' should be in System.Version format" {
                $notesVersion = $notes | Select-String -pattern "Version:"
                $notesVersion | Should Match 'Version:\s*(\d{1,9}\.){2,4}'
            }
            
            It "Notes attribute `'license`' should exist" {
                $notesLicense = $notes | Select-String -pattern "License:"
                $notesLicense | Should Match 'License:*'
            }
		}
	}
}
