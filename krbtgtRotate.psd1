@{
RootModule = 'krbtgtRotate.psm1'

ModuleVersion = '0.2.1'

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

### Version 0.2.1
2016-09-26


'@
}

}

}    

