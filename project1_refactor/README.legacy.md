# 🚀 Project 1: Terraform AWS Infrastructure (DevSecOps Focus)

This project provisions a secure, modular AWS infrastructure using Terraform. It is designed for learning, testing, and demonstrating DevSecOps best practices such as least privilege IAM, CloudTrail logging, modular design, and remote state configuration.

---

## 📦 Modules Overview

| Module           | Purpose                                      |
|------------------|----------------------------------------------|
| `vpc`            | Creates a VPC, subnet, IGW, and routing      |
| `security_group` | Configures ingress/egress for EC2            |
| `iam`            | Defines IAM roles, policies, and profile     |
| `s3`             | Creates an encrypted log bucket              |
| `cloudtrail`     | Enables account activity logging             |
| `ec2`            | Launches a hardened Amazon Linux 2 instance  |

---

## 🧰 Features

- 🔐 **IAM least privilege**: Role restricted to read-only S3 access  
- 📦 **S3 log bucket**: Encrypted, versioned, public access blocked, optional policies enforcing TLS
- 🛡️ **CloudTrail**: Captures all management events  
- 🖧 **VPC/Subnet**: Custom CIDR, public IP auto-assignment  
- ⚙️ **EC2**: SSH key injected; security group restricts access by IP  
- 🧱 **Modular Terraform**: Reusable modules with clean interface  
- ☁️ **Remote state**: Backend config via `backend.tf` (S3 + DynamoDB)  
- 🏷️ **Tagging**: All resources tagged with environment/project metadata  

---

## 🗂️ Folder Structure

```txt
project1_refactor/
├── backend.tf
├── main.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars
├── variables.tf
├── modules/
│ ├── vpc/
│ ├── security_group/
│ ├── s3/
│ ├── iam/
│ ├── cloudtrail/
│ └── ec2/
```

## ⚙️ Usage

0. **## ⚙️ Bootstrapping Remote Backend (Pre-Req)
Before using the main `project1_refactor/` Terraform configuration, you **must first run the `bootstrap/` configuration** to provision the remote backend.


1. **Initialise Terraform**
```bash
terraform init
```

2. **Validate the configuration**
```bash
terraform validate
```

3. **Review the plan**

```bash
terraform plan -out=tfplan.out
```

4. **Apply the plan**

```bash
terraform apply tfplan.out
```

5. **Destroy**

```bash
terraform destroy
```

## ⚙️ Bootstrapping Remote Backend (Pre-Req)

Before using the main `project1_refactor/` Terraform configuration, you **must first run the `bootstrap/` configuration** to provision the remote backend.

### 📂 Why this step is needed

Terraform requires a **remote backend** to:

- Store the `terraform.tfstate` file securely (in an S3 bucket).
- Prevent concurrent changes using state locking (via DynamoDB).
- Enable safe collaboration and automation (CI/CD, pipelines, teams).

### ✅ Steps

1. Navigate to the `bootstrap/` directory:
```bash
cd bootstrap/
```

2. **Initialise and apply:**
```bash
terraform init
terraform apply
```

3. **Once done, the following backend resources will exist in AWS:**

- `my-eu-tf-state-bucket` (S3 bucket for Terraform state)
- terraform-locks (DynamoDB table for state locking)

4. **Now you can switch to the main project:**
```bash
cd ../project1_refactor/
terraform init
terraform apply
```


## 🌐 Prerequisites
    - AWS account with programmatic access
    - Terraform >= 1.5.0
    - S3 bucket + DynamoDB table (for backend)
    - SSH keypair (already created)

## 🔐 Security Notes

    - `force_destroy = true` is used only in dev — **not recommended** in prod
    - Security Groups restrict SSH to trusted IPs (not 0.0.0.0/0)
    - CloudTrail logs are written to an encrypted S3 bucket
    - IAM roles follow least privilege principles

## 📈 Future Enhancements
Add support for multiple environments (dev, staging, prod)

CI/CD pipeline with terraform fmt, validate, and plan (GitHub Actions)

Extend EC2 provisioning with Ansible or user-data scripts

Use KMS for bucket encryption instead of AES256

Integrate GuardDuty or AWS Config for deeper security

