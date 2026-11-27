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

2. Vagrant installs the pinned Cowrie release, runs its credential-redaction acceptance test, and disconnects the NAT adapter after provisioning.
3. If the disconnect trigger did not run, disconnect manually:

   ```powershell
   .\scripts\disconnect_runtime.ps1
   ```

The disconnect procedure removes NAT and all NAT port-forwarding rules. Only the Host-only adapter should remain. Cowrie runs as the unprivileged `cowrie` user in emulated-shell mode.

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
- the guest firewall denies outbound traffic and limits inbound services to the Windows host;
- the guest has no routed LAN connection;
- the host can reach management SSH port `22`, Cowrie port `2222`, and dashboard port `8080`;
- VirtualBox has no NAT, bridged, NAT Network, or port-forwarding rule.

The Cowrie sensor is available at `192.168.56.10:2222`; port `22` is reserved for local Vagrant management. Port `8080` is reserved for the future analyst dashboard. Any other listener should be considered a configuration defect.

Run the sentinel-password test again at any time:

```powershell
vagrant ssh -c "sudo /opt/cowrie/venv/bin/python /vagrant/scripts/verify_cowrie_redaction.py"
```

The test submits a generated password to the local sensor and scans every Cowrie state file and its system journal for that sentinel. Cowrie is pinned to commit `894d398712b8558dca7a3a8ef6b427337b988d91` (v2.9.8); the version-specific patch removes password fields and values from login events before dispatch, sends file artifacts to `/dev/null`, and removes the emulated SCP command.

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
