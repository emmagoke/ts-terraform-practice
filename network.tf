resource "aws_vpc" "ts_vpc" {
  cidr_block = "10.0.0.0/16"
}

################################
# ---------- Subnets ----------#
################################

resource "aws_subnet" "ts_public_subnet" {
  vpc_id     = aws_vpc.ts_vpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "ts-public"
  }
}

resource "aws_subnet" "ts_private_subnet" {
  vpc_id     = aws_vpc.ts_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "ts-private"
  }
}

resource "aws_subnet" "ts_database_subnet" {
  vpc_id     = aws_vpc.ts_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "ts_database"
  }
}



# resource "aws_default_security_group" "ts_fe_sg" {
#   vpc_id = aws_vpc.ts_vpc.id

#   ingress {
#     protocol  = "http"
#     self      = true
#     from_port = 80
#     to_port   = 80
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }


# resource "aws_default_security_group" "ts_be_sg" {
#   vpc_id = aws_vpc.ts_vpc.id

#   ingress {
#     protocol  = "tcp"
#     self      = true
#     from_port = 443
#     to_port   = 443
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_default_security_group" "ts_db_sg" {
#   vpc_id = aws_vpc.ts_vpc.id

#   ingress {
#     protocol  = "tcp"
#     self      = true
#     from_port = 33006
#     to_port   = 3306
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

#################################
# ---------- Gateways ----------#
#################################

resource "aws_internet_gateway" "ts_gw" {
  vpc_id = aws_vpc.ts_vpc.id

  tags = {
    Name = "main"
  }
}


# Elastic Ip Address
resource "aws_eip" "ts_nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.ts_gw]
}


// Allows internet into the public subnet
resource "aws_nat_gateway" "ts_nat_gateway" {
  allocation_id = aws_eip.ts_nat_eip.id
  subnet_id     = aws_subnet.ts_public_subnet.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.ts_gw]
}


#####################################
# ---------- Route tables ----------#
#####################################

resource "aws_route_table" "ts_public_rt" {
  vpc_id = aws_vpc.ts_vpc.id

  route {
    cidr_block = "0.0.0.0/0"  // Access to all internet
    gateway_id = aws_internet_gateway.ts_gw.id
  }

#   route {
#     ipv6_cidr_block        = "::/0"
#     egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
#   }

  tags = {
    Name = "Ts-public"
  }
}

resource "aws_route_table" "ts_private_rt" {
  vpc_id = aws_vpc.ts_vpc.id

  route {
    # cidr_block = "10.0.1.0/24"
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ts_nat_gateway.id
  }

#   route {
#     ipv6_cidr_block        = "::/0"
#     egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
#   }

  tags = {
    Name = "Ts-private"
  }
}


resource "aws_route_table" "ts_database_rt" {
  vpc_id = aws_vpc.ts_vpc.id

  # route {
  #   cidr_block = "10.0.3.0/16"
  #   gateway_id = "local"
  # }

  tags = {
    Name = "Ts-Database-rt"
  }
}

resource "aws_route_table_association" "ts_public_association" {
    subnet_id = aws_subnet.ts_public_subnet.id
    route_table_id = aws_route_table.ts_public_rt.id
}

resource "aws_route_table_association" "ts_private_association" {
    subnet_id = aws_subnet.ts_private_subnet.id
    route_table_id = aws_route_table.ts_private_rt.id
}


resource "aws_route_table_association" "ts_database_association" {
    subnet_id = aws_subnet.ts_database_subnet.id
    route_table_id = aws_route_table.ts_database_rt.id
}

#######################################################################################
# ---------- Security groups (chain: internet -> frontend -> backend -> db) ----------#
#######################################################################################

resource "aws_security_group" "public_server" {
  name   = "ts-frontend-sg"
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    description = "HTTP from internet"
    protocol  = "tcp"
    self      = true
    from_port = 80
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_server" {
  name   = "ts-backend-sg"
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    description     = "From frontend only"
    protocol        = "tcp"
    self            = true
    from_port       = 443
    to_port         = 443
    security_groups = [aws_security_group.public_server.id]
  }
  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database_server" {
  name   = "ts-database-sg"
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    description     = "MySQL from backend only"
    protocol        = "tcp"
    self            = true
    from_port       = 3306
    to_port         = 3306
    security_groups = [aws_security_group.private_server.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
