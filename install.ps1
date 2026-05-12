#Requires -Version 5.1
<#
.SYNOPSIS
    Install hica on Windows.
.DESCRIPTION
    Downloads the latest hica release binary and installs it to a local directory.
    Set $env:HICA_INSTALL_DIR to override the default install location.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Repo = 'cladam/hica'

$InstallDir = if ($env:HICA_INSTALL_DIR) {
    $env:HICA_INSTALL_DIR
} else {
    Join-Path $env:LOCALAPPDATA 'hica'
}

$Arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture) {
    'X64'   { 'x86_64' }
    'Arm64' { 'arm64' }
    default { throw "Unsupported architecture: $_" }
}

$Artifact = "hica-windows-$Arch"
$Url = "https://github.com/$Repo/releases/latest/download/$Artifact.zip"

Write-Host 'Installing hica...'
Write-Host "  arch:    $Arch"
Write-Host "  install: $InstallDir"
Write-Host ''

$TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null

try {
    $ZipPath = Join-Path $TmpDir "$Artifact.zip"
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing

    Expand-Archive -Path $ZipPath -DestinationPath $TmpDir -Force

    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    $ExeSrc = Join-Path $TmpDir 'hica.exe'
    $ExeDst = Join-Path $InstallDir 'hica.exe'
    Move-Item -Path $ExeSrc -Destination $ExeDst -Force

    Write-Host "hica installed to $ExeDst"

    # Add to user PATH if not already present
    $UserPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable('PATH', "$InstallDir;$UserPath", 'User')
        Write-Host ''
        Write-Host "Added $InstallDir to your user PATH."
        Write-Host 'Restart your terminal for the change to take effect.'
    }

    Write-Host ''
    & $ExeDst --version
}
finally {
    Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
}
