# CodeLab FZC LLC- Senior InfraSRE Engineer – Blockchain Payments - Hiring Test - Naim Khan

# Infrastructure Hiring Assignment – IaC (Terraform)

## Overview
This repository contains a sample Infrastructure as Code (IaC) design using Terraform.
The goal is to demonstrate clear structure, environment separation, reproducibility,
and operational reasoning — not to deploy real infrastructure.

All values (domains, IPs, names) are dummy and non-confidential.

---

## Repository Structure

├── README.md
├── iac/
│ ├── backend.tf
│ ├── modules/
│ │ ├── network/
│ │ ├── firewall/
│ │ └── compute/
│ └── envs/
│ ├── dev/
│ ├── staging/
│ └── prod/
└── docs/
├── environment_and_networks.md
├── security_controls.md
├── governance_flow.md
└── incident_response.md


---

## How to Run (Conceptual)
This repository is for design evaluation only.

If executed in a real environment, the workflow would be:
1. Select environment (`dev`, `staging`, or `prod`)
2. Initialize Terraform backend
3. Review plan output
4. Apply changes only after approval

Actual cloud credentials and execution are intentionally omitted.

---

## Design Intent

- Infrastructure is defined using reusable Terraform modules
- Network, security, and compute are separated for clarity and reuse
- Environment differences are handled via variables, not duplicated code
- Each environment is isolated to reduce blast radius
- Terraform is the single source of truth for infrastructure

---

## Environment Strategy (dev / staging / prod)

### Directory-Based Separation
Each environment has its own directory under `iac/envs/`:

- `dev` – development and testing
- `staging` – pre-production validation
- `prod` – production workloads

This ensures:
- Separate Terraform state per environment
- No shared infrastructure between environments
- Independent lifecycle and rollback

---

### Variable-Based Differences
Environment-specific behavior is controlled using variables (`terraform.tfvars`).

Examples of differences:
- VPC CIDR ranges
- Instance size and count
- Security group rules
- Access restrictions

This avoids code duplication while allowing controlled variation.

---

## Reproducibility & State Handling

### State Management
Terraform uses a remote backend to store state.

Purpose:
- Prevent state loss if a local machine fails
- Enable team collaboration
- Ensure everyone sees the same infrastructure state
- Avoid concurrent conflicting changes

Each environment maintains an independent state file.

---

### Drift Detection

**Definition:**  
Drift occurs when infrastructure is modified manually outside Terraform.

**Detection Method:**
- `terraform plan` is executed in CI or during reviews
- Any difference between code and actual infrastructure is detected automatically

**Operational Policy:**
- Manual console changes are treated as incidents
- All fixes must be applied through Terraform
- Terraform remains the source of truth

**Why This Matters:**
- Manual changes bypass review
- Break reproducibility
- Reduce audit and compliance readiness

---

## Documentation
Additional design explanations are available in the `docs/` directory:
- Network and environment design
- Security controls
- Governance and approval flow
- Incident response principles

---
