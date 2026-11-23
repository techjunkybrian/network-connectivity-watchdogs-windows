# Network Connectivity Watchdogs for Windows

Small PowerShell watchdogs that restart a Windows laptop when Wi-Fi or Ethernet and internet connectivity stay unavailable for three minutes. Each installs as a Windows Scheduled Task and starts at every boot, even before a user signs in.

> **Warning:** When the watchdog restarts Windows, it force-closes running applications. Save your work before leaving the laptop unattended.

## Watchdogs

| Connection type | Install script | Uninstall command | Log |
| --- | --- | --- | --- |
| Wi-Fi | `Install-WifiWatchdog.ps1` | `.Install-WifiWatchdog.ps1 -Uninstall` | `C:\ProgramData\WifiWatchdog\watchdog.log` |
| Ethernet | `Install-EthernetWatchdog.ps1` | `.Install-EthernetWatchdog.ps1 -Uninstall` | `C:\ProgramData\EthernetWatchdog\watchdog.log` |

Each watchdog checks that its connection type has an active adapter and that internet access works. Microsoft's or Google's connectivity check can satisfy the internet test. An internet outage can trigger a restart even if the local Wi-Fi or Ethernet link is still active.

Install only the watchdog for the connection you want to monitor. If you install both, loss of either adapter can trigger a restart even when the other connection still has internet access.

## Requirements

- Windows 11 (also expected to work on Windows 10)
- Windows PowerShell 5.1
- A Wi-Fi adapter for the Wi-Fi watchdog, or an Ethernet adapter for the Ethernet watchdog
- Administrator access to install or uninstall the scheduled task
- Access to at least one connectivity-check endpoint:
  - `www.msftconnecttest.com`
  - `connectivitycheck.gstatic.com`

## Install

1. Download or clone this repository.
2. Open **Windows PowerShell as Administrator** in the downloaded folder.
3. Run the installer for the connection type you want to monitor. For Wi-Fi:

   ```powershell
   .\Install-WifiWatchdog.ps1
   ```

   For Ethernet:

   ```powershell
   .\Install-EthernetWatchdog.ps1
   ```

The installer copies its monitor under `C:\ProgramData` and registers a startup task named **WiFi Connectivity Watchdog** or **Ethernet Connectivity Watchdog**. The task runs as `SYSTEM`, starts at boot without requiring sign-in, and is allowed to run on battery.

To confirm the task is registered:

```powershell
Get-ScheduledTask -TaskName 'WiFi Connectivity Watchdog'
# Or:
Get-ScheduledTask -TaskName 'Ethernet Connectivity Watchdog'
```

## Uninstall

Open an elevated PowerShell window in the downloaded folder and run:

Run the matching uninstall command from the table above. This removes that watchdog's scheduled task and installed copy, including its log file.

## Configuration

Edit the matching monitor script before installing to change the outage threshold or polling interval:

```powershell
$OfflineMinutes = 3
$PollSeconds = 15
```

Run its installer again after editing so the updated monitor is copied to `C:\ProgramData`.

## Troubleshooting

View the watchdog log:

```powershell
Get-Content 'C:\ProgramData\WifiWatchdog\watchdog.log' -Tail 50
# Or:
Get-Content 'C:\ProgramData\EthernetWatchdog\watchdog.log' -Tail 50
```

Check task status and recent task details in **Task Scheduler** under **Task Scheduler Library**, or use:

```powershell
Get-ScheduledTaskInfo -TaskName 'WiFi Connectivity Watchdog'
# Or:
Get-ScheduledTaskInfo -TaskName 'Ethernet Connectivity Watchdog'
```

## Files

| File | Purpose |
| --- | --- |
| `Monitor-Wifi.ps1` | Checks Wi-Fi and internet connectivity, logs state changes, and triggers the restart. |
| `Install-WifiWatchdog.ps1` | Installs or removes the Wi-Fi startup task and deployed monitor. |
| `Monitor-Ethernet.ps1` | Checks Ethernet and internet connectivity, logs state changes, and triggers the restart. |
| `Install-EthernetWatchdog.ps1` | Installs or removes the Ethernet startup task and deployed monitor. |

