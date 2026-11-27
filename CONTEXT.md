# Honeypot Lab

This project is a local-only cybersecurity learning lab for observing simulated interactions with an emulated SSH service and practicing SOC triage. It distinguishes locally generated lab activity from real-world attack traffic.

## Lab interactions

**Honeypot**:
A decoy service used to observe suspicious interactions. In this project, it exists only inside an isolated lab and does not provide access to the host operating system.
_Avoid_: Production SSH server

**Lab interaction**:
An action submitted by the authorized local test client to the honeypot, such as connecting, attempting authentication, or entering command text. It is generated for the lab and is not evidence of an external attack.
_Avoid_: Real attack, attacker activity

**Test client**:
An authorized local client that generates lab interactions for learning and verification.
_Avoid_: Attacker

**Lab session**:
One connection from a test client to the honeypot, grouping the ordered interaction events observed during that connection.
_Avoid_: Incident, case

**Interaction event**:
A timestamped observation within a lab session, such as a connection, simulated authentication, or command input.
_Avoid_: Alert

**Emulated shell**:
A simulated command-line environment that records submitted command text and returns emulated behavior without granting access to the host operating system.
_Avoid_: Real shell, host shell

**Simulated authentication**:
A fake authentication step within the honeypot that can lead to an emulated shell session; it does not authenticate a real system account. Password values are not retained as lab data.
_Avoid_: Real login, credential capture

## Analysis

**Analyst dashboard**:
A local interface for reviewing lab sessions, inspecting their ordered interaction events, and marking sessions as new or reviewed.
_Avoid_: Public monitoring console

**Review status**:
The analyst's triage state for a lab session: `new` or `reviewed`.
_Avoid_: Severity, incident status
