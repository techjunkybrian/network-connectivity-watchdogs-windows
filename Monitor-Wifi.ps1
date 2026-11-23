# Monitors Wi-Fi and internet connectivity. Install with Install-WifiWatchdog.ps1.
# Runs under Windows PowerShell 5.1 on Windows 10/11.

$ErrorActionPreference = 'Stop'
$OfflineMinutes = 3
$PollSeconds = 15
$LogPath = Join-Path $env:ProgramData 'WifiWatchdog\watchdog.log'

function Write-Log {
    param([string]$Message)
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Test-InternetEndpoint {
    param([string]$Uri, [int]$ExpectedStatus, [string]$ExpectedBody)

    $client = [System.Net.Http.HttpClient]::new()
    $response = $null
    $client.Timeout = [TimeSpan]::FromSeconds(8)
    try {
        $response = $client.GetAsync($Uri).GetAwaiter().GetResult()
        if ([int]$response.StatusCode -ne $ExpectedStatus) { return $false }
        if ($ExpectedBody) {
            $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            return $body.Trim() -eq $ExpectedBody
        }
        return $true
    } catch {
        return $false
    } finally {
        if ($null -ne $response) { $response.Dispose() }
        $client.Dispose()
    }
}

function Test-WifiConnectivity {
    $wirelessAdapters = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
        Where-Object { $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Wireless80211 }

    if (-not $wirelessAdapters -or -not ($wirelessAdapters | Where-Object { $_.OperationalStatus -eq 'Up' })) {
        return $false
    }

    # Either probe succeeding counts as internet access. The response is checked
    # to avoid treating captive portal pages as a working connection.
    if (Test-InternetEndpoint 'http://www.msftconnecttest.com/connecttest.txt' 200 'Microsoft Connect Test') {
        return $true
    }
    return Test-InternetEndpoint 'http://connectivitycheck.gstatic.com/generate_204' 204 ''
}

$null = New-Item -ItemType Directory -Path (Split-Path -Parent $LogPath) -Force
Write-Log 'Watchdog started.'
$offlineSince = $null

while ($true) {
    $connected = Test-WifiConnectivity
    if ($connected) {
        if ($null -ne $offlineSince) {
            Write-Log 'Connectivity restored; outage timer reset.'
            $offlineSince = $null
        }
    } else {
        if ($null -eq $offlineSince) {
            $offlineSince = Get-Date
            Write-Log 'Wi-Fi or internet connectivity lost; starting 3-minute timer.'
        } elseif (((Get-Date) - $offlineSince).TotalMinutes -ge $OfflineMinutes) {
            Write-Log 'Connectivity has been unavailable for 3 minutes; restarting Windows.'
            & "$env:SystemRoot\System32\shutdown.exe" /r /t 0 /f
            exit
        }
    }
    Start-Sleep -Seconds $PollSeconds
}
