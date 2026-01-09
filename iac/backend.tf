# Reproducibility & State Handling: Backend & State (Terraform’s Memory)

terraform {
  backend "s3" {
    bucket = "company-terraform-state"
    key = "${var.env}/app/terraform.tfstate"
    region = "ap-south-1"
  }
}

