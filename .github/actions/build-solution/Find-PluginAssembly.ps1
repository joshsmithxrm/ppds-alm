[CmdletBinding()]
param(
    [string]$PluginsFolder = 'src/Plugins',
    [string]$Configuration = 'Release',
    [string]$ProjectPath = '',
    [string]$TargetFramework = ''
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

if ($ProjectPath) {
    if (-not (Test-Path -LiteralPath $ProjectPath -PathType Leaf) -or
        [IO.Path]::GetExtension($ProjectPath) -ne '.csproj') {
        throw "plugin-project must identify an existing .csproj: $ProjectPath"
    }
    $projects = @(Get-Item -LiteralPath $ProjectPath)
}
elseif (Test-Path -LiteralPath $PluginsFolder -PathType Container) {
    $projects = @(Get-ChildItem -LiteralPath $PluginsFolder -Filter '*.csproj' -Recurse -File |
        Where-Object { $_.FullName -notmatch '[\\/](bin|obj)[\\/]' } |
        Sort-Object FullName)
}
else {
    # A solution containing only plugin packages need not have a classic plugin project.
    return
}

if ($projects.Count -eq 0) { return }
if ($projects.Count -ne 1) {
    throw "Found $($projects.Count) plugin projects in '$PluginsFolder'. Set plugin-project explicitly."
}

# Evaluate the same project/configuration that was built. This respects imported
# and conditional AssemblyName/OutputPath properties and never selects a dependency.
$arguments = @(
    'msbuild', $projects[0].FullName, '-nologo',
    '-getProperty:TargetPath,TargetFramework,TargetFrameworks',
    "-p:Configuration=$Configuration"
)
if ($TargetFramework) { $arguments += "-p:TargetFramework=$TargetFramework" }
$raw = & dotnet @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Could not evaluate plugin project '$($projects[0].FullName)' (MSBuild exit $LASTEXITCODE)."
}
try {
    $properties = ($raw -join [Environment]::NewLine | ConvertFrom-Json).Properties
}
catch {
    throw "MSBuild did not return project properties for '$($projects[0].FullName)'."
}
if (-not $TargetFramework -and $properties.TargetFrameworks) {
    $frameworks = @($properties.TargetFrameworks -split ';' | Where-Object { $_ })
    if ($frameworks.Count -gt 1) {
        throw 'The plugin project targets multiple frameworks. Set plugin-target-framework explicitly.'
    }
    if ($frameworks.Count -eq 1) {
        & $PSCommandPath -PluginsFolder $PluginsFolder -Configuration $Configuration `
            -ProjectPath $projects[0].FullName -TargetFramework $frameworks[0]
        return
    }
}

$targetPath = $properties.TargetPath
if (-not $targetPath -or [IO.Path]::GetExtension($targetPath) -ne '.dll' -or
    -not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
    throw "The built plugin DLL was not found at evaluated TargetPath '$targetPath'. Build the selected project/configuration/framework first."
}
(Get-Item -LiteralPath $targetPath).FullName
