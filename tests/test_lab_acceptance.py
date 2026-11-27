from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class LabAcceptanceTests(unittest.TestCase):
    def test_vm_uses_only_a_host_only_network(self):
        vagrantfile = (ROOT / "Vagrantfile").read_text(encoding="utf-8")
        disconnect = (ROOT / "scripts" / "disconnect_runtime.ps1").read_text(encoding="utf-8")

        self.assertIn("config.vm.network \"private_network\"", vagrantfile)
        self.assertIn('config.ssh.host = "192.168.56.10"', vagrantfile)
        self.assertIn('"nic1", "null"', disconnect)
        self.assertIn('"--natpf1", "delete"', disconnect)
        self.assertNotIn("type: \"bridged\"", vagrantfile)
        self.assertNotIn("forwarded_port", vagrantfile)
        self.assertNotIn("adapter: 2", vagrantfile)

    def test_runtime_verifier_checks_guest_and_host_boundaries(self):
        script = (ROOT / "scripts" / "verify_lab.ps1").read_text(encoding="utf-8")

        self.assertIn("Get-NetRoute", script)
        self.assertIn("1.1.1.1", script)
        self.assertIn("22", script)
        self.assertIn("8080", script)
        self.assertIn("Host-only", script)
        self.assertIn("ip route", script)
        self.assertIn("ss -ltnH", script)

    def test_runbook_covers_provisioning_disconnect_snapshots_and_rollback(self):
        runbook = (ROOT / "docs" / "LAB-RUNBOOK.md").read_text(encoding="utf-8")
        runbook_lower = runbook.lower()

        self.assertIn("controlled connectivity", runbook_lower)
        self.assertIn("disconnect", runbook_lower)
        self.assertIn("snapshot", runbook_lower)
        self.assertIn("rollback", runbook_lower)
        self.assertIn("cowrie", runbook_lower)
        self.assertIn("analyst dashboard", runbook_lower)

    def test_services_are_provisioned_as_unprivileged_users(self):
        provision = (ROOT / "scripts" / "provision.sh").read_text(encoding="utf-8")

        self.assertIn("cowrie", provision)
        self.assertIn("dashboard", provision)
        self.assertIn("useradd", provision)
        self.assertIn("sudo -u", provision)


if __name__ == "__main__":
    unittest.main()
