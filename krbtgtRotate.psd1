@{
RootModule = 'krbtgtRotate.psm1'

ModuleVersion = '0.2.2'

GUID = '3671deb0-f711-488e-b41f-eda82b1c79e5'

Author = 'J Schell'

Copyright = 'The MIT License (MIT), 2016'

PowerShellVersion = '3.0'

PowerShellHostVersion = '3.0'

Description = 'krbtgt password rotation, done safely'

FunctionsToExport = @(
    'Get-KrbtgtPasswordMinimumAge'
    'Invoke-KrbtgtPasswordRotate'
    'New-ComplexPassword'
    'Register-KrbtgtEventLog'
    'Set-KrbtgtPassword'
    'Test-ComplexPassword'
    'Test-Port'
    'Test-PortTCP'
    'Write-KrbtgtEventLog'
    'Write-LogMessage'
)

RequiredModules  = @( 'ActiveDirectory', 'GroupPolicy')

PrivateData = @{

PSData = @{
    
    Tags = @('PSModule', 'krbtgtRotate' )
    
    LicenseURI = 'https://opensource.org/licenses/MIT'
    
    ProjectURI = 'https://github.com/jschell/krbtgtRotate'
    
    ReleaseNotes = @'

### Version 0.2.2
2026-03-01
- Fix: Corrected undefined variable $msgWarnPasswordGenerationNotComplex in New-ComplexPassword (correct name: $msgPasswordGenerationNotComplex)
- Fix: Replaced `break` with `return $False` in Test-ComplexPassword catch block for ADIdentityNotFoundException
- Fix: Replaced incomplete "Error observed! S_" error messages in module loader with Write-Warning including file name and exception details
- Fix: Corrected 4 instances of typo "obseved" to "observed" in Invoke-KrbtgtPasswordRotate

### Version 0.2.1
2016-09-26


'@
}

}

}    

