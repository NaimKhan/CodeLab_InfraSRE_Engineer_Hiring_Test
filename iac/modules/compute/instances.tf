# Compute (Application Servers)
# Creates stateless application servers inside the application subnet.

resource "aws_instance" "app" {
  count         = var.instance_count
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  ami           = var.ami_id
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = "${var.env}-app-${count.index}"
  }
}

# Same code works for all environments
# Scaling is done by changing variables, not code
# Stateless servers are easier to replace, restart, and scale safely
# Supports high availability in production

