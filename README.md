# Wi-Fi Connectivity Watchdog for Windows

A small PowerShell utility that restarts a Windows laptop when Wi-Fi or internet connectivity stays unavailable for three minutes. It installs as a Windows Scheduled Task and starts at every boot, even before a user signs in.

> **Warning:** When the watchdog restarts Windows, it force-closes running applications. Save your work before leaving the laptop unattended.

## How it works

- Checks for an active Wi-Fi adapter and internet access every 15 seconds.
- Considers internet access available if either Microsoft's or Google's connectivity check responds as expected.
- Starts a three-minute timer after a failed check. Any successful check resets the timer.
- Restarts Windows if connectivity remains unavailable for the full interval.
- Logs state changes to `C:\ProgramData\WifiWatchdog\watchdog.log`.

This checks internet reachability as well as Wi-Fi association. An internet outage while the laptop remains connected to its Wi-Fi network can therefore trigger a restart. The watchdog requires a Wi-Fi adapter; it is not intended for Ethernet-only computers.

## Requirements

- Windows 11 (also expected to work on Windows 10)
- Windows PowerShell 5.1
- A Wi-Fi adapter
- Administrator access to install or uninstall the scheduled task
- Access to at least one connectivity-check endpoint:
  - `www.msftconnecttest.com`
  - `connectivitycheck.gstatic.com`

## Install

1. Download or clone this repository.
2. Open **Windows PowerShell as Administrator** in the downloaded folder.
3. Run:

   ```powershell
   .\Install-WifiWatchdog.ps1
   ```

The installer copies the monitor to `C:\ProgramData\WifiWatchdog` and registers the **WiFi Connectivity Watchdog** task. The task runs as `SYSTEM`, starts at boot without requiring sign-in, and is allowed to run on battery.

To confirm the task is registered:

```powershell
Get-ScheduledTask -TaskName 'WiFi Connectivity Watchdog'
```

## Uninstall

Open an elevated PowerShell window in the downloaded folder and run:

```powershell
.\Install-WifiWatchdog.ps1 -Uninstall
```

This removes the scheduled task and the installed copy, including its log file.

## Configuration

Edit `Monitor-Wifi.ps1` before installing to change the outage threshold or polling interval:

```powershell
$OfflineMinutes = 3
$PollSeconds = 15
```

Run the installer again after editing so the updated monitor is copied to `C:\ProgramData\WifiWatchdog`.

## Troubleshooting

View the watchdog log:

```powershell
Get-Content 'C:\ProgramData\WifiWatchdog\watchdog.log' -Tail 50
```

Check task status and recent task details in **Task Scheduler** under **Task Scheduler Library**, or use:

```powershell
Get-ScheduledTaskInfo -TaskName 'WiFi Connectivity Watchdog'
```

## Files

| File | Purpose |
| --- | --- |
| `Monitor-Wifi.ps1` | Checks Wi-Fi and internet connectivity, logs state changes, and triggers the restart. |
| `Install-WifiWatchdog.ps1` | Installs or removes the startup scheduled task and deployed monitor. |

