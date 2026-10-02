param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'build\SLASH'),
    [string]$IntermediateDirectory = (Join-Path $PSScriptRoot 'obj\Release-x64')
)
$ErrorActionPreference = 'Stop'
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (!(Test-Path -LiteralPath $vswhere)) { throw 'Visual Studio Installer was not found.' }
$installation = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (!$installation) { throw 'Install Visual Studio with Desktop development with C++ and C++ ATL.' }
$msbuild = Join-Path $installation 'MSBuild\Current\Bin\MSBuild.exe'
$toolsets = Get-ChildItem -LiteralPath (Join-Path $installation 'MSBuild\Microsoft\VC') -Directory |
    ForEach-Object { Join-Path $_.FullName 'Platforms\x64\PlatformToolsets' } |
    Where-Object { Test-Path -LiteralPath $_ } |
    ForEach-Object { Get-ChildItem -LiteralPath $_ -Directory } |
    Where-Object { $_.Name -match '^v\d+$' } |
    Sort-Object Name -Descending
if (!$toolsets) { throw 'No supported C++ platform toolset was found.' }
$toolset = $toolsets[0].Name
$output = [IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\') + '\'
$intermediate = [IO.Path]::GetFullPath($IntermediateDirectory).TrimEnd('\') + '\'
New-Item -ItemType Directory -Force -Path $output, $intermediate | Out-Null
$projectDirectory = Join-Path $PSScriptRoot 'DX21_05_Init'
$projectFile = Join-Path $projectDirectory 'DX21_05_Init.vcxproj'
& $msbuild $projectFile /nologo /m /t:Build /p:Configuration=Release /p:Platform=x64 "/p:PlatformToolset=$toolset" "/p:OutDir=$output" "/p:IntDir=$intermediate" /v:minimal
if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE." }
Copy-Item -LiteralPath (Join-Path $projectDirectory 'asset') -Destination $output -Recurse -Force
Copy-Item -Path (Join-Path $projectDirectory '*.hlsl') -Destination $output -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'PLAYING.txt'), (Join-Path $PSScriptRoot 'THIRD_PARTY_NOTICES.txt') -Destination $output -Force
Write-Output "Ready: $(Join-Path $output 'SLASH.exe')"
