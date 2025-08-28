# 🏗️ Hardened Platform-as-Code (Terraform · AWS · GitHub Actions)

Provision a **secure, auditable, cloud-native environment** using **Terraform** on **AWS**, deployed via **GitHub Actions** using **OIDC** (no long-lived secrets).  
This project demonstrates **DevSecOps best practice** (“DevOps done properly”): least-privilege IAM, encrypted storage, audit logging, CI/CD guardrails, and remote state with locking.

----------

# Table of Contents

- [🏗️ Hardened Platform-as-Code (Terraform · AWS · GitHub Actions)](#️-hardened-platform-as-code-terraform--aws--github-actions)
- [Table of Contents](#table-of-contents)
  - [✨ TL;DR](#-tldr)
  - [🧱 Architecture (High Level)](#-architecture-high-level)
  - [🔐 Security Decisions (Secure-by-Default)](#-security-decisions-secure-by-default)
  - [📦 What’s Included](#-whats-included)
  - [🔧 Prerequisites](#-prerequisites)
  - [🚀 Bootstrapping Remote State (One-off)](#-bootstrapping-remote-state-one-off)
  - [⚙️ Configuration](#️-configuration)
  - [▶️ Usage](#️-usage)
    - [Option A — Via GitHub Actions (recommended)](#option-a--via-github-actions-recommended)
    - [Option B — Local (for quick iteration)](#option-b--local-for-quick-iteration)
  - [📤 Example Outputs](#-example-outputs)
  - [🗂️ Repo Structure](#️-repo-structure)
  - [🧪 CI/CD Overview (GitHub Actions)](#-cicd-overview-github-actions)
  - [🧭 Design Notes \& Rationale](#-design-notes--rationale)
  - [🧩 Optional Enhancements](#-optional-enhancements)
  - [💰 Costs \& Clean-up](#-costs--clean-up)
  
----------

## ✨ TL;DR

- **What it builds:** VPC, hardened EC2, encrypted S3 (logs), IAM (least privilege), Security Groups, CloudTrail.
- **How it deploys:** GitHub Actions with **OIDC role assumption** → `plan` on PR/merge; **manual** `apply` via `workflow_dispatch`.
- **State:** S3 backend with **DynamoDB locking** (via a small bootstrap stack).
- **Security:** S3 SSE, TLS-only bucket policy, IAM least privilege, EC2 with IMDSv2 & SSM Session Manager preferred, CloudTrail → S3.

----------

## 🧱 Architecture (High Level)

```
GitHub Repo (Terraform + Workflow) ──▶ GitHub Actions (OIDC) ──▶ AWS Account
                                      - fmt/validate/plan
                                      - manual apply only┌───────────────┐
                                                         │ VPC + Subnet  │
                                                         │   + Route     │
                                                         └──────┬────────┘
                                                                │
                                                     ┌──────────▼──────────┐
                                                     │  EC2 (Amazon Linux) │
                                                     │  - IMDSv2 required  │
                                                     │  - SSM by  default  │
                                                     └─────────┬───────────┘
                                                               │
                                                    ┌──────────▼──────────┐
                                                    │  S3 (logs, private) │
                                                    │  - SSE, TLS only    │
                                                    │  - CloudTrail logs  │
                                                    └──────────────────────┘
``` 

----------

## 🔐 Security Decisions (Secure-by-Default)

| Area                | Control                                                                 | Why it matters                                                                                  |
|--------------------|-------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| **Identity & Access** | **OIDC** from GitHub Actions to AWS IAM Role (no long-lived keys)      | Eliminates static secrets; short-lived, auditable credentials.                                  |
| **Terraform State**   | S3 backend + **state locking**                                 | Prevents concurrent applies; centralised, durable state.                                        |
| **Logging & Audit**   | **CloudTrail** (multi-region) → encrypted S3                             | Full API audit trail for investigations and compliance.                                         |
| **Storage**           | S3 bucket: **SSE (AES256)**, **block public access**, **TLS-only policy**, versioning, lifecycle | Confidentiality, integrity, and basic retention controls; denies unencrypted or non-TLS requests. |
| **Compute**           | EC2 with **IMDSv2 required** | Reduces credential exposure; avoids opening port 22 to the Internet.                                            |
| **Network**           | Security Groups: default-deny inbound; explicit, minimal ingress        | Least-privilege networking reduces attack surface.                                             |
| **CI/CD Guardrails**  | Plan on PR/merge; **apply only via manual trigger**; backend health checks; job **concurrency** | Safe deployment flow; fail fast if remote state is unavailable; no overlapping runs.           |

> Note: SSE-KMS with a CMK can be used if you want stronger key control; this project uses SSE-S3 for simplicity.

----------

## 📦 What’s Included

- **Terraform modules**: `vpc`, `security_group`, `iam`, `s3`, `cloudtrail`, `ec2`, `key_pair`
- **Root config**: backend, providers, variables, outputs
- **GitHub Actions**: `.github/workflows/terraform-provision.yml` (OIDC, fmt/validate/plan, manual apply, outputs)
- **Defence-in-depth S3 bucket policy**: TLS-only + CloudTrail write permissions
- **Lifecycle rule** with `filter { prefix = "" }` (provider-compatible; applies to all objects)
 
----------

## 🔧 Prerequisites

- AWS account with permissions to assume the GitHub **OIDC role** used by the workflow  
- Terraform **v1.13+**  
- A pre-created **S3 bucket** for remote state and a **DynamoDB table** for locks (via the bootstrap stack below)


----------

## 🚀 Bootstrapping Remote State (One-off)

Use a tiny “bootstrap” stack (separate repo) to create:

- S3 bucket: `my-eu-tf-state-bucket`
- DynamoDB table: `terraform-locks`
   
Then the root project’s `backend.tf` points at:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-eu-tf-state-bucket"
    key            = "envs/dev/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"   # enables state locking
  }
}
``` 

----------

## ⚙️ Configuration

Edit `terraform.tfvars` (or supply via CI variables):

```hcl
# ---------- EC2 ----------
...
allowed_ips   = ["20.0.100.1/32"]
public_key    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockPublicKeyForTestingOnlyDoNotUseInProduction"
```

> Defaults target **London (eu-west-2)**.

----------

## ▶️ Usage

### Option A — Via GitHub Actions (recommended)

1. Configure the repository secret **`AWS_OIDC_ROLE`** with the ARN of your AWS IAM role for GitHub OIDC.
2. Push a PR → workflow runs `fmt/validate/plan` (**no apply**).
3. Merge to `main` → workflow re-checks and plans again.
4. From **Actions → Run workflow** → manually trigger **apply** (`workflow_dispatch`).
5. Outputs are printed as a dedicated step (JSON), e.g. EC2 public IP and SSH helper.  

**Guardrails in the workflow**

-   Backend sanity checks: `aws s3api head-bucket` and `aws dynamodb describe-table`
    
-   Concurrency control: one run per branch
    
-   Apply only when manually approved (no automatic applies)
    

### Option B — Local (for quick iteration)

```bash
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output -json
``` 

----------

## 📤 Example Outputs

```
{
  "ec2_public_ip": { "value": "18.135.15.200" },
  "public_subnet_id": { "value": "subnet-0dff5aeb2b8a6fed1" },
  "ssh_command": { "value": "ssh ec2-user@1.222.33.4 -i ~/.ssh/id_aws_ed25519" },
  "vpc_id": { "value": "vpc-029d36bdff4b18fff" }
}
``` 

----------

## 🗂️ Repo Structure

```
project1_refactor/
├── backend.tf
├── main.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars
├── variables.tf
├── modules/
│   ├── vpc/
│   ├── security_group/
│   ├── iam/
│   ├── s3/          # owns bucket + full bucket policy (incl. CloudTrail permissions)
│   ├── cloudtrail/  # consumes bucket name; no  policy duplication
│   ├── ec2/
│   └── key_pair/
└── .github/workflows/terraform-provision.yml
``` 

----------

## 🧪 CI/CD Overview (GitHub Actions)

- **Triggers**
   - `pull_request` → pre-merge `fmt/validate/plan`
   - `push` to `main` → post-merge `plan`
   - `workflow_dispatch` → **manual apply**


- **Credentials**: OIDC → `aws-actions/configure-aws-credentials@v4` with `role-to-assume: ${{ secrets.AWS_OIDC_ROLE }}`
 
- **Safety**
    - Remote state **S3/DynamoDB** checks before init
    - **Concurrency** guard per branch
    - Apply **never** runs automatically

----------

## 🧭 Design Notes & Rationale

- **Bucket policy ownership** lives in the **S3 module** (single source of truth); the **CloudTrail module** only references the bucket. This avoids policy drift and respects module boundaries (**DRY**).
- **Lifecycle rule** uses `filter { prefix = "" }` which is required by newer AWS provider versions and applies to all objects.    

----------

## 🧩 Optional Enhancements

- Swap S3 SSE-S3 for **SSE-KMS (CMK)** and restrict key usage  
- Add **tfsec/tflint** jobs to the pipeline  
- Multi-environment pattern (e.g., `envs/dev/staging/prod` with separate state keys)  
- GuardDuty / AWS Config integration  
- Post-provision tests (e.g., curl health checks) before surfacing outputs  

----------

## 💰 Costs & Clean-up

This uses Free-Tier-friendly resources, but charges can accrue.  
Destroy when you’re done:

```bash
terraform destroy
```