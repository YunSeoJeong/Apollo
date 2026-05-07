$ErrorActionPreference = "Continue"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$nefconZipPath = Join-Path $scriptPath "nefcon.zip"
$workPath = Join-Path $env:TEMP "apollo-vdd-uninstall"

if (Test-Path $workPath) {
    Remove-Item -LiteralPath $workPath -Recurse -Force
}

New-Item -ItemType Directory -Path $workPath | Out-Null
Expand-Archive -LiteralPath $nefconZipPath -DestinationPath $workPath -Force

$nefconPath = Join-Path $workPath "x64\nefconw.exe"
& $nefconPath --remove-device-node --hardware-id root\mttvdd --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318" | Out-Null

