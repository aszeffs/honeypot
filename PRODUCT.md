# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Undecided; no application framework or scaffold is present yet.

## Users

Cybersecurity learners practicing SOC triage.

## Product Purpose

A local-only learning lab for observing simulated interactions with an emulated SSH service and practicing SOC triage. Success means reviewing simulated SSH sessions and their ordered interaction events.

## Positioning

An isolated emulation lab for triaging locally generated SSH interactions without granting access to the host operating system or presenting lab activity as evidence of external attacks.

## Operating Context

An authorized local test client connects to the honeypot and submits simulated authentication attempts or command text. The analyst reviews sessions and their ordered events in a dashboard, then marks each session as `new` or `reviewed`.

## Capabilities and Constraints

- The honeypot runs only inside an isolated lab and does not provide access to the host operating system.
- The emulated shell records submitted command text and returns emulated behavior.
- Simulated authentication does not authenticate a real system account; it may lead to an emulated shell session.
- Password values are not retained as lab data.
- Lab interactions are generated locally for learning and verification. They are not real-world attack traffic or evidence of an external attack.
- Use the glossary terms `lab interaction`, `test client`, `lab session`, `interaction event`, `emulated shell`, `simulated authentication`, `analyst dashboard`, and `review status`.

## Evidence on Hand

No customer proof, real-world attack evidence, or product assets are documented. Do not fabricate them; lab activity is simulated and locally generated.

## Product Principles

- Keep lab activity isolated from the host operating system.
- Make the simulation boundary explicit; do not imply that lab events are external attacks.
- Organize observations into ordered sessions and events that learners can review.
- Do not retain simulated-authentication password values.
