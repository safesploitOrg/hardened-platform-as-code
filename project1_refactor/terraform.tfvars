# ---------- Global ----------
project       = "project1"
aws_region    = "eu-west-2"

# ---------- AMI Lookup ----------
ami_owner        = "amazon"
ami_name_pattern = "amzn2-ami-hvm-*-x86_64-gp2"

# ---------- EC2 ----------
instance_type = "t2.micro"
key_name      = "id_aws_ed25519"
allowed_ips   = ["0.0.0.0/32"]
# Make public_key into a list(string)
# public_key= only supports 1:1 mapping
public_key    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockPublicKeyForTestingOnlyDoNotUseInProduction"

# ---------- VPC ----------
availability_zone  = "eu-west-2a"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
