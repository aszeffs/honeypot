$ErrorActionPreference = "Stop"

$vmName = "honeypot-lab"
$hostOnlyPrefix = "192.168.56"
$failures = @()

Write-Host "Checking host-only SSH access..."
vagrant ssh -c "echo READY" *> $null
if ($LASTEXITCODE -ne 0) {
    $failures += "Guest SSH is unreachable over 192.168.56.10; isolation checks could not run."
    Write-Host "FAIL: $($failures[-1])"
    exit 1
}
Write-Host "PASS: guest SSH is reachable over Host-only networking."

Write-Host "Checking Host-only routing..."
$hostRoutes = Get-NetRoute |
    Where-Object { $_.DestinationPrefix -like "$hostOnlyPrefix*" }
if (-not $hostRoutes) {
    $failures += "No Host-only route for $hostOnlyPrefix.0/24 was found."
}

Write-Host "Checking guest internet isolation..."
$guestResult = vagrant ssh -c "curl --fail --connect-timeout 3 --head http://1.1.1.1 2>/dev/null"
if ($LASTEXITCODE -eq 0) {
    $failures += "Guest reached 1.1.1.1; it must not reach the internet."
} else {
    Write-Host "PASS: guest cannot reach 1.1.1.1."
}

Write-Host "Checking guest LAN isolation..."
$lanResult = vagrant ssh -c "ip route | grep -Ev '^192\.168\.56\.|^169\.254\.'"
if (($LASTEXITCODE -eq 0) -and ($lanResult.Trim())) {
    $failures += "Guest has a routed LAN or internet network: $lanResult"
} else {
    Write-Host "PASS: guest has no routed LAN or internet connection."
}

Write-Host "Checking intended host-to-service ports..."
foreach ($port in @(22, 8080)) {
    $probe = Test-NetConnection -ComputerName "192.168.56.10" -Port $port -InformationLevel Quiet
    if ($probe) {
        Write-Host "PASS: host can reach intended port $port."
    } elseif ($port -eq 22) {
        $failures += "Host cannot reach required SSH service on port 22."
    } else {
        Write-Host "INFO: dashboard port $port is reserved for the future dashboard service."
    }
}

Write-Host "Checking guest listening services..."
$listeners = vagrant ssh -c "ss -ltnH"
if ($LASTEXITCODE -ne 0) {
    $failures += "Could not inspect guest listening services."
} else {
    $unexpectedListeners = $listeners | Where-Object {
        $_ -match ":(\d+)\s+" -and $Matches[1] -notin @("22", "8080")
    }
    if ($unexpectedListeners) {
        $failures += "Guest has unintended listening services: $($unexpectedListeners -join '; ')"
    } else {
        Write-Host "PASS: guest listeners are limited to intended ports 22 and 8080."
    }
}

Write-Host "Checking VirtualBox network configuration..."
$info = & VBoxManage.exe showvminfo $vmName --machinereadable
$adapters = $info | Select-String '^"nic\d+"="([^"]*)"$'
$forwardRules = $info | Select-String '(^"natpf\d+"=)'

foreach ($adapter in $adapters) {
    if ($adapter.Matches[0].Groups[1].Value -notin @("hostonly", "null", "none")) {
        $failures += "Guest has a non-Host-only adapter: $($adapter.Line)"
    }
}
if ($forwardRules) {
    $failures += "Guest has a NAT port-forwarding rule."
}

if ($failures.Count -gt 0) {
    Write-Host "FAIL:"
    $failures | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host "PASS: runtime isolation checks completed."
