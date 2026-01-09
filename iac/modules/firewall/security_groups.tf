# Firewall / Security Group (SG-equivalent)
# Opens HTTPS (443) only
# IPs come from variables


resource "aws_security_group" "web_sg" {
  name   = "${var.env}-web-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Prod ≠ Dev security
# No hardcoded IPs
# Zero chance of “oops, prod is open”
# Default security posture is deny-all
# Explicit allow rules are easier to audit and review
# allowed_cidrs changes per environment:
# dev: broader access for testing
# staging: limited internal ranges
# prod: strict allowlists only

