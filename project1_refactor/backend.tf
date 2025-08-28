# Backend where Terraform stores its state file (terraform.tfstate).
# - stores the state of your infrastructure (so it knows what it’s managing),
# - optionally locks the state (to prevent concurrent updates),
# - can support collaboration in a team setting (via remote state).

# Backend Dev Environment 
terraform {
  backend "s3" {
    bucket         = "<YOUR_BACKEND_BUCKET>"
    key            = "envs/dev/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    use_lockfile   = true
  }
}
