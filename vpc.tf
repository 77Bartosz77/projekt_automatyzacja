resource "aws_vpc" "express_app_vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
   Name = "express_app"
  }
}

resource "aws_subnet" "sn1" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.express_app_vpc.id
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "express_app_sn1"
  }
}

resource "aws_subnet" "sn2" {
  cidr_block = "10.0.2.0/24"
  vpc_id = aws_vpc.express_app_vpc.id
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "express_app_sn2"
  }
}

resource "aws_subnet" "sn3" {
  cidr_block = "10.0.3.0/24"
  vpc_id = aws_vpc.express_app_vpc.id
  availability_zone = "eu-north-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "express_app_sn3"
  }
}


resource "aws_security_group" "express_app_sg" {
  name = "express_app_sg"
  vpc_id = aws_vpc.express_app_vpc.id

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.express_app_vpc.id
  tags = {
    Name = "express_app"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.express_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "express_app"
  }
}

resource "aws_route_table_association" "route1" {
  route_table_id = aws_route_table.rt.id
  subnet_id      = aws_subnet.sn1.id
}

resource "aws_route_table_association" "route2" {
  route_table_id = aws_route_table.rt.id
  subnet_id      = aws_subnet.sn2.id
}

resource "aws_route_table_association" "route3" {
  route_table_id = aws_route_table.rt.id
  subnet_id      = aws_subnet.sn3.id
}