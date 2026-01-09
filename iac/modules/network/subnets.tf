# Public subnet → web / load balancer
# Private subnet → database / internal services

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.private_subnet_cidr

  tags = {
    Name = "${var.env}-private-subnet"
  }
}

# DB must never be internet-facing
# Classic security zoning (public vs private)

