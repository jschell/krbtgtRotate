<#
.Synopsis
Basic test for validating help has been filled in correctly for all functions
within the '$moduleRoot\Public' and '$moduleRoot\Private' folders.

.Description
Test for synopsis, description, examples, non-default parameters being present 
in the help. Also checks for name, author, version and license.

All functions in the 'private' and 'public' folders will be evaluated.

This test expects to be in the following directory structure:
.\[ModuleName]
    .\private
        myFancyPrivateFunction.ps1
    .\public
        myPlainPublicFunction.ps1
    .\tests
        Function.Help.Tests.ps1
    [ModuleName].psd1
    [ModuleName].psm1

.Parameter FolderPath
Specifies the folder path that should be used for testing child files that are 
written as 'PS1' functions. 

.Parameter ScriptPath
Specifies the script path that should be used for testing matching files that are 
written as 'PS1' functions. 

.Example
PS > invoke-pester .\Function.Help.Tests.ps1

Description
-----------
Tests if the functions contained in the '.\public' and '.\private' folders have 
properly completed help.

.Example
PS > invoke-pester -Script @{Path='.\Function.Help.Tests.ps1';Parameters=@{FolderPath='.\MyUncommonFolder\'}}

Description
-----------
Tests if the functions contained in the '.\MyUncommonFolder' folder have properly 
completed help.

.Example
PS > invoke-pester -Script @{Path='.\Function.Help.Tests.ps1';Parameters=@{ScriptPath='c:\scriptOnRoot.ps1'}}

Description
-----------
Tests if the function contained in the 'c:\scriptOnRoot.ps1' file has properly 
completed help.

.Link
 https://github.com/juneb/PesterTDD/blob/master/Module.Help.Tests.ps1

.Link
 https://github.com/devblackops/POSHOrigin/blob/master/Tests/Help.tests.ps1

.Link
 http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html

.NOTES

#### Name:     Function.Help.Tests
#### Author:   J Schell
#### Version:  0.2.3
#### License:  MIT License

### Change Log


##### 2017-03-21::0.2.3
-allow specific folder/ script to be specified, default will test pub/pri folders

##### 2017-03-21::0.2.2
-format parameters for function and help as array, even if single parameter

##### 2017-03-21::0.2.1
-add try/catch for notes, parameters

##### 2017-03-21::0.2.0
-large scale re-work
-fork of prior design that used 'Help.[FunctionName].Test.ps1' style (per function)

##### 2016-05-27::0.1.0
- initial creation 
#>


[CmdletBinding(DefaultParameterSetName = "Folder")]
Param
(
    [Parameter(Mandatory = $False,
        ParameterSetName = "Folder")]
    [ValidateScript({ Test-Path -Path $_ -PathType 'Container' })]
    [String]
    $FolderPath,

    [Parameter(Mandatory = $False,
        ParameterSetName = "Script")]
    [ValidateScript({ 
        if(Get-ChildItem -Path $_ -Include "*.ps1")
        { $True }
        else 
        { $False }
    })]
    [String]
    $ScriptPath
)

Set-StrictMode -Version Latest

if( !($FolderPath) -AND !($ScriptPath) )
{
    $TestDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
    $ModuleBase = Resolve-Path "$TestDir\.." 
    $ModuleName = Split-Path -Path $ModuleBase -Leaf

    # Removes all versions of the module from the session before importing
    Get-Module $ModuleName | Remove-Module -Force

    $privateFolder = "$ModuleBase\private"
    $publicFolder = "$ModuleBase\public"
    
    $privateFunctions = @( Get-ChildItem -path "$privateFolder\*ps1" -file -exclude "*.tests.*" )
    $publicFunctions = @( Get-ChildItem -path "$publicFolder\*ps1" -file -exclude "*.tests.*" )

    $allFunctions = @( $privateFunctions )
    $allFunctions += @( $publicFunctions )

}
if($FolderPath)
{
    $folderFunctions = @( Get-ChildItem -path "$FolderPath\*ps1" -file -exclude "*.tests.*" )
    $allFunctions = @( $folderFunctions )
}
if($ScriptPath)
{
    $scriptFunctions = @( Get-ChildItem -path "$ScriptPath" -file -exclude "*.tests.*" -Include "*.ps1" )
    $allFunctions = @( $scriptFunctions )
}


foreach($function in $allFunctions)
{
    . $function.FullName
    $functionName = $function.baseName

    $Help = Get-Help -Name $functionName -Online:$false -ErrorAction SilentlyContinue
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

		Context "Test for placeholder/template content in $functionName" {
			It "Synopsis should not be a generic 'Brief description' placeholder" {
				$Help.Synopsis | Should Not BeLike 'Brief description*'
			}

			It "Synopsis should not contain 'Verb-Noun' template text" {
				$Help.Synopsis | Should Not BeLike '*Verb-Noun*'
			}

			It "Description should not be a generic 'Detailed description' placeholder" {
				($Help.Description | Out-String) | Should Not BeLike 'Detailed description*'
			}

			It "Examples should not use 'Verb-Noun' template text" {
				($Help.Examples.Example.Code | Out-String) | Should Not BeLike '*Verb-Noun*'
			}
		}
		
        Context "Test parameter help for $functionName" {
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
