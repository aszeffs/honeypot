# Honeypot Lab Runbook

This runbook creates an isolated Ubuntu Server lab on Windows using VirtualBox and Vagrant.

## Prerequisites

Install:

- VirtualBox
- Vagrant
- Windows PowerShell

Enable virtualization in the host BIOS if VirtualBox cannot start a 64-bit guest.

## Provision with controlled connectivity

Provisioning needs temporary internet access to download the Ubuntu box and packages:

1. Start the VM and provision it:

   ```powershell
   vagrant up
   ```

2. Verify the host can reach the VM at `192.168.56.10`.
3. Complete package and service installation while the controlled connection is enabled.
4. Run the disconnect procedure:

   ```powershell
   .\scripts\disconnect_runtime.ps1
   ```

The disconnect procedure removes NAT and all NAT port-forwarding rules. Only the Host-only adapter should remain.

## Runtime isolation

Runtime has no bridged adapter, NAT adapter, NAT Network adapter, or forwarded port.

Start or stop the lab with:

```powershell
vagrant up
vagrant halt
```

After startup, run:

```powershell
.\scripts\verify_lab.ps1
```

The verifier checks that:

- the Windows host has a route to `192.168.56.0/24`;
- the guest cannot reach `1.1.1.1`;
- the guest has no routed LAN connection;
- the host can reach intended lab SSH port `22` and dashboard port `8080`;
- VirtualBox has no NAT, bridged, NAT Network, or port-forwarding rule.

During this ticket, `192.168.56.10:22` is the intended lab service. Port `8080` is reserved for the future analyst dashboard. Any service other than SSH or the reserved dashboard port should be considered a configuration defect.

## Reconnecting for updates

To apply a package or VM update:

1. Use VirtualBox or a Vagrant/VBoxManage command to temporarily restore NAT.
2. Record the start time and exact update performed.
3. Run the update and provisioning steps.
4. Disconnect NAT again with `disconnect_runtime.ps1`.
5. Run `verify_lab.ps1` before restoring runtime use.

Do not leave the VM on NAT or bridged networking after maintenance.

## Clean snapshot

After provisioning and isolation verification pass:

```powershell
VBoxManage snapshot honeypot-lab take clean-runtime
VBoxManage snapshot honeypot-lab list
```

The `clean-runtime` snapshot is the known-good baseline. It must contain no NAT, bridged adapter, NAT Network, or NAT port-forwarding rule.

## Rollback procedure

To restore the clean baseline:

1. Stop the VM:

   ```powershell
   vagrant halt
   ```

2. Restore the snapshot:

   ```powershell
   VBoxManage snapshot honeypot-lab restore clean-runtime
   ```

3. Start the VM:

   ```powershell
   vagrant up
   ```

4. Disconnect controlled connectivity if snapshot restoration retained it:

   ```powershell
   .\scripts\disconnect_runtime.ps1
   ```

5. Verify isolation:

   ```powershell
   .\scripts\verify_lab.ps1
   ```

Rollback is complete only after the verifier reports success.

## Service identities

Cowrie and the analyst dashboard directories and planned services use dedicated unprivileged identities:

- `cowrie`
- `dashboard`

Neither service should run as `root`. Verify identities with:

```bash
sudo -u cowrie -H id
sudo -u dashboard -H id
ps -eo user,pid,cmd | grep -E '[c]owrie|[d]ashboard'
```
