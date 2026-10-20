resource "aws_vpc" "ts_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "ts_public_subnet" {
  vpc_id     = aws_vpc.ts_vpc.id
  cidr_block = "10.0.1.0/24"

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
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "ts_database"
  }
}



resource "aws_default_security_group" "ts_fe_sg" {
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol  = "http"
    self      = true
    from_port = 80
    to_port   = 80
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_default_security_group" "ts_be_sg" {
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 443
    to_port   = 443
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_security_group" "ts_db_sg" {
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 33006
    to_port   = 3306
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_internet_gateway" "ts_gw" {
  vpc_id = aws_vpc.ts_vpc

  tags = {
    Name = "main"
  }
}


resource "aws_route_table" "ts_public_rt" {
  vpc_id = aws_vpc.ts_vpc.id

  route {
    cidr_block = "10.0.0.0/16"
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

  # route {
  #   cidr_block = "10.0.2.0/16"
  #   gateway_id = "local"
  # }

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

# Elastic Ip Address


// Allows internet into the public subnet
resource "aws_nat_gateway" "ts_nat_gateway" {
#   allocation_id = aws_eip.example.id
  subnet_id     = aws_subnet.ts_public_subnet

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.ts_gw]
}


resource "aws_default_security_group" "public_server" {
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 80
    to_port   = 80
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_security_group" "private_server" {
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 443
    to_port   = 443
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_security_group" "database_server" {
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 3306
    to_port   = 3306
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
