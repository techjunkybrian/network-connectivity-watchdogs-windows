param(
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$taskName = 'WiFi Connectivity Watchdog'
$installDirectory = Join-Path $env:ProgramData 'WifiWatchdog'
$monitorPath = Join-Path $installDirectory 'Monitor-Wifi.ps1'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from an elevated PowerShell window (Run as administrator).'
}

if ($Uninstall) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $installDirectory) {
        Remove-Item -LiteralPath $installDirectory -Recurse -Force
    }
    Write-Host 'WiFi Connectivity Watchdog uninstalled.'
    exit 0
}

$sourceMonitor = Join-Path $PSScriptRoot 'Monitor-Wifi.ps1'
if (-not (Test-Path -LiteralPath $sourceMonitor)) {
    throw "Monitor script not found: $sourceMonitor"
}

$null = New-Item -ItemType Directory -Path $installDirectory -Force
Copy-Item -LiteralPath $sourceMonitor -Destination $monitorPath -Force

$action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -Argument "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$monitorPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
    -Principal $principal -Settings $settings -Description 'Restarts Windows after Wi-Fi/internet connectivity is unavailable for 3 continuous minutes.' -Force | Out-Null

Write-Host "Installed. The watchdog starts at boot and checks connectivity every 15 seconds."
Write-Host "Log file: $installDirectory\watchdog.log"
