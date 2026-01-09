# Staging environment 

instance_type  = "medium"
instance_count = 2
allowed_ips    = ["10.20.0.0/16"]
vpc_cidr       = "10.20.0.0/16"

# Mirrors production topology
# Uses restricted access
# Safe place to validate changes before prod
 

