import json
import os
import secrets
import subprocess
import time
from pathlib import Path

from cowrie.core.artifact import Artifact


COWRIE_ROOT = Path("/opt/cowrie/source")


def login(
    username: str, environment: dict[str, str]
) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        [
            "sshpass",
            "-e",
            "ssh",
            "-p",
            "2222",
            "-o",
            "ConnectTimeout=5",
            "-o",
            "PubkeyAuthentication=no",
            "-o",
            "PreferredAuthentications=password",
            "-o",
            "StrictHostKeyChecking=no",
            "-o",
            "UserKnownHostsFile=/dev/null",
            f"{username}@192.168.56.10",
            "true" if username == "root" else "exit",
        ],
        env=environment,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=15,
        check=False,
    )


def main() -> None:
    artifact_content = b"lab-file-artifact-" + secrets.token_bytes(16)
    artifact = Artifact("acceptance")
    artifact.write(artifact_content)
    artifact_result = artifact.close()
    if artifact_result is None or artifact_result[1] != os.devnull:
        raise RuntimeError("Cowrie did not discard the synthetic file artifact")

    sentinel = f"lab-redaction-{secrets.token_hex(16)}"
    environment = os.environ.copy()
    environment["SSHPASS"] = sentinel

    success = login("root", environment)
    if success.returncode:
        raise RuntimeError(
            f"Synthetic successful login failed with exit status {success.returncode}"
        )

    failure = login(f"lab-invalid-{secrets.token_hex(8)}", environment)
    if failure.returncode == 0:
        raise RuntimeError("Synthetic invalid login unexpectedly succeeded")

    time.sleep(1)
    sentinel_bytes = sentinel.encode()
    state_dir = COWRIE_ROOT / "var"
    files = [path for path in state_dir.rglob("*") if path.is_file()]
    if not files:
        raise RuntimeError("Cowrie produced no persisted output to inspect")

    observed_login_events = set()
    for path in files:
        content = path.read_bytes()
        if sentinel_bytes in content:
            raise RuntimeError(f"Sentinel found in persisted Cowrie file: {path}")
        if artifact_content in content:
            raise RuntimeError(f"File artifact found in Cowrie state: {path}")
        if path.name.startswith("cowrie.json"):
            for line in content.splitlines():
                event = json.loads(line)
                event_id = event.get("eventid")
                if event_id in {"cowrie.login.success", "cowrie.login.failed"}:
                    if "password" in event:
                        raise RuntimeError(f"Password field found in Cowrie event: {path}")
                    if "password redacted" not in event.get("message", ""):
                        raise RuntimeError(f"Login message was not redacted: {path}")
                    observed_login_events.add(event_id)

    if observed_login_events != {"cowrie.login.success", "cowrie.login.failed"}:
        raise RuntimeError("Cowrie did not persist both synthetic login outcomes")

    journal = subprocess.run(
        [
            "journalctl",
            "--unit=cowrie.service",
            "--output=cat",
            "--no-pager",
        ],
        capture_output=True,
        check=True,
    )
    if sentinel_bytes in journal.stdout:
        raise RuntimeError("Sentinel found in the Cowrie system journal")
    if artifact_content in journal.stdout:
        raise RuntimeError("File artifact found in the Cowrie system journal")

    print("PASS: synthetic password is absent from Cowrie persisted outputs")


if __name__ == "__main__":
    main()
