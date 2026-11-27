$ErrorActionPreference = "Stop"

$vmName = "honeypot-lab"

function Invoke-VBoxManage {
    param([Parameter(Mandatory)][string[]]$Arguments)

    & VBoxManage.exe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "VBoxManage failed: $($Arguments -join ' ')"
    }
}

$vms = & VBoxManage.exe list runningvms
if ($LASTEXITCODE -ne 0) {
    throw "Could not query running VirtualBox machines."
}
if (-not ($vms | Where-Object { $_ -like "*`"$vmName`"*"})) {
    Write-Error "The honeypot-lab VM is not running."
}

Invoke-VBoxManage -Arguments @("controlvm", $vmName, "nic1", "null")

$info = & VBoxManage.exe showvminfo $vmName --machinereadable
if ($LASTEXITCODE -ne 0) {
    throw "Could not read the VirtualBox machine configuration."
}
$forwardRules = $info | Where-Object { $_ -match '^"natpf\d+"="([^,]+),' }
foreach ($rule in $forwardRules) {
    if ($rule -match '^"natpf\d+"="([^,]+),') {
        Invoke-VBoxManage -Arguments @("modifyvm", $vmName, "--natpf1", "delete", $Matches[1])
    }
}

Invoke-VBoxManage -Arguments @("modifyvm", $vmName, "--nic1", "null")

Write-Host "Runtime network disconnected. Only the Host-only network should remain."
