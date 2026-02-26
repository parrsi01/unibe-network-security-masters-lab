# Project Manual

Author: Simon Parris  
Date: 2026-02-26

## Purpose

This repository is a master's-level network security lab and study framework designed for rigorous self-study, interview preparation, and portfolio evidence generation.

## Operating Model

- Read module theory in `docs/`
- Use `Library/` for deeper synthesis notes
- Execute labs and capture evidence
- Practice ticket triage in `incidents/`
- Run `validate_repo.sh` and tests before commits

## Standard Workflow (Per Topic)

1. Read the module `01_START_HERE.md`
2. Review the linked concept note
3. Execute one related lab
4. Capture outputs and evidence
5. Write a short finding summary and risk interpretation
6. Run validation and tests
7. Commit with a specific message

## Evidence Standard

- exact commands used
- observed outputs or packet/alert excerpts
- hypothesis and validation method
- false-positive / false-negative considerations
- remediation or detection tuning rationale

## Safety Notes

- Labs are designed for local VMs and controlled datasets.
- Do not test detection or scanning workflows against unauthorized systems.
- Prefer offline sample data where provided.

