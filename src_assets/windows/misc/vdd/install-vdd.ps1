$ErrorActionPreference = "Stop"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$vddZipPath = Join-Path $scriptPath "vdd_control.zip"
$nefconZipPath = Join-Path $scriptPath "nefcon.zip"
$workPath = Join-Path $env:TEMP "apollo-vdd-install"
$settingsPath = "C:\VirtualDisplayDriver"

if (Test-Path $workPath) {
    Remove-Item -LiteralPath $workPath -Recurse -Force
}

New-Item -ItemType Directory -Path $workPath | Out-Null
New-Item -ItemType Directory -Path $settingsPath -Force | Out-Null

Expand-Archive -LiteralPath $vddZipPath -DestinationPath (Join-Path $workPath "vdd") -Force
Expand-Archive -LiteralPath $nefconZipPath -DestinationPath (Join-Path $workPath "nefcon") -Force

$driverArch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "ARM64" } else { "x86" }
$driverPath = Join-Path $workPath "vdd\SignedDrivers\$driverArch\VDD"
$nefconPath = Join-Path $workPath "nefcon\x64\nefconw.exe"

Copy-Item -LiteralPath (Join-Path $driverPath "vdd_settings.xml") -Destination (Join-Path $settingsPath "vdd_settings.xml") -Force

& $nefconPath --remove-device-node --hardware-id root\mttvdd --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318" | Out-Null
& $nefconPath --create-device-node --class-name Display --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318" --hardware-id root\mttvdd | Out-Null
& $nefconPath --install-driver --inf-path (Join-Path $driverPath "MttVDD.inf") | Out-Null

$vddDevice = Get-PnpDevice -Class Display | Where-Object {
    $_.FriendlyName -eq "Virtual Display Driver" -or $_.InstanceId -like "ROOT\MTTVDD*"
} | Select-Object -First 1

if ($vddDevice) {
    Disable-PnpDevice -InstanceId $vddDevice.InstanceId -Confirm:$false | Out-Null
}
