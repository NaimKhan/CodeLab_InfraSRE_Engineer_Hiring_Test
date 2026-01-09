# Environment-specific behavior is defined using variable files (terraform.tfvars), not duplicated code.

module "network" {
  source               = "../../modules/network"
  env                  = "dev"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
}

module "firewall" {
  source      = "../../modules/firewall"
  env         = "dev"
  vpc_id      = module.network.vpc_id
  allowed_ips = var.allowed_ips
}

module "compute" {
  source             = "../../modules/compute"
  env                = "dev"
  instance_count     = var.instance_count
  instance_type      = var.instance_type
  subnet_id          = module.network.public_subnet_id
  security_group_id  = module.firewall.web_sg_id
  ami_id             = var.ami_id
}


# Orchestrates modules
# No logic duplication
# Environment-aware wiring

