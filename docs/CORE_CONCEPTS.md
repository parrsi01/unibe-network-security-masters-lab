# Core Concepts

Author: Simon Parris  
Date: 2026-02-26

## 1. Threat Modeling Before Tooling

- Start by defining assets, trust boundaries, adversary goals, and observable attack paths.
- Tool output is useful only when mapped back to a threat model and detection objective.

## 2. Packet Path + Control Path Reasoning

Network security analysis requires understanding:

- packet path (interfaces, routing, NAT, ACLs, middleboxes)
- control path (DNS, PKI, identity, policy engines, key distribution)

## 3. Detection Engineering as Software Engineering

- detection rules require version control, testing, tuning, and change history
- noisy detections degrade response quality
- triage logic should be reproducible and evidence-backed

## 4. Forensics and Incident Response Discipline

- preserve evidence before remediation when safe
- record time, source, method, and integrity notes
- differentiate containment actions from root cause findings

## 5. Research Rigor

- define hypotheses, variables, and metrics before running experiments
- control environmental changes in lab evaluations
- document limitations and external validity assumptions

