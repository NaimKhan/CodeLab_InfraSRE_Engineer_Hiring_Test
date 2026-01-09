# Creates a private virtual network (VPC)
# CIDR is variable → different per environment

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.env}-vpc"
  }
}


# Dev / Prod must NEVER share the same network
# Isolation = security + blast-radius control

