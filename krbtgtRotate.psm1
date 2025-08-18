# See http://stackoverflow.com/questions/5489494/powershell-module-manifest-automatically-loading-a-required-module#5490326 for why requiredModules is processed inside the psm1 (vs manifest file)
$requiredModules = @(
    'ActiveDirectory'
    'GroupPolicy'
)
if( $requiredModules.Count -ge 1 )
{
    foreach($module in $requiredModules)
    {
        if( !(Get-Module $module) )
        {
            Import-Module $module -ErrorAction Stop
        }
    }
}

$privateFolder = "$psScriptRoot\private"
$publicFolder = "$psScriptRoot\public"

$privateFunctions = @( Get-ChildItem -path "$privateFolder\*ps1" -file -exclude "*tests*" )
$publicFunctions = @( Get-ChildItem -path "$publicFolder\*ps1" -file -exclude "*tests*" )

foreach( $entry in $privateFunctions ){
    try {
        # . $entry.fullName
        . ( [scriptblock]::Create( [io.file]::ReadAllText($entry) ) )
    }
    catch {
        "Error observed! S_"
    }
    if( Get-Command -name $entry.baseName ){
        Write-Verbose "Loaded `'$($entry.baseName)`' via dot sourcing."
    }
    else {
        Throw "Could not load `'$($entry.baseName)`'"
    }
}

foreach( $entry in $publicFunctions ){
    try {
        # . $entry.fullName
        . ( [scriptblock]::Create( [io.file]::ReadAllText($entry) ) )
    }
    catch {
        "Error observed! S_"
    }
    if( Get-Command -name $entry.baseName ){
        Write-Verbose "Loaded `'$($entry.baseName)`' via dot sourcing."
    }
    else {
        Throw "Could not load `'$($entry.baseName)`'"
    }
    
    $entryContent = Get-Content -raw -path $entry.fullName
    $tokens = $null
    $errors = $null
    $function = [System.Management.Automation.Language.Parser]::ParseInput( $entryContent, [ref]$tokens, [ref]$errors)
    $functionList = @( $function.findAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $false ) )
    foreach( $functionFound  in $functionList ){
        Export-ModuleMember $functionFound.name
    }
    
}

$ExecutionContext.SessionState.Module.OnRemove = { 
    #---Action to take when module removed
}
