# Production environment

instance_count = 4
instance_type  = "t3.xlarge"
allowed_ips    = ["203.0.113.10/32"]  # Office only
public_subnet_cidr  = "10.1.1.0/24"


# Impossible to deploy prod with dev values
# CI/CD friendly
# Zero risk of human error
# High availability (multiple instances)
# Strong network isolation
# Minimal attack surface

