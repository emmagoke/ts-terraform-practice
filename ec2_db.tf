data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ts_frontend_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "frontend server"
  }
}

resource "aws_instance" "ts_backend_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "backend server"
  }
}

resource "aws_db_subnet_group" "ts_rds_subnet" {
  name       = "my-ts-database-subnet-group"
  subnet_ids = [aws_subnet.ts_private_subnet.id, aws_subnet.ts_database_subnet]

  tags = {
    Name = "My DB subnet group"
  }
}


resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "my_ts_db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "foo_user"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}




# resource "aws_ec2_instance_state" "test" {
#   instance_id = aws_instance.test.id
#   state       = "stopped"
# }
