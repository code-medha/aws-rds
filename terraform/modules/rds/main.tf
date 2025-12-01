# Fetch values from Parameter Store
data "aws_ssm_parameter" "db_name" {
  name = "/cruddur/db/name"
}

data "aws_ssm_parameter" "db_username" {
  name = "/cruddur/db/user_name"
}

data "aws_ssm_parameter" "db_password" {
  name            = "/cruddur/db/password"
  with_decryption = true
}

resource "aws_db_subnet_group" "cruddur" {
  name       = "cruddur-subnet-group"
  subnet_ids = var.subnet_ids
  tags = {
    Name = "cruddur-subnet-group"
  }
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
  
}

resource "aws_db_instance" "cruddur_db_instance" {
  identifier                            = "cruddur-db-instance"
  instance_class                        = "db.t3.micro"
  engine                                = "postgres"
  engine_version                        = "14.15"
  username                              = data.aws_ssm_parameter.db_username.value
  password                              = data.aws_ssm_parameter.db_password.value
  allocated_storage                     = 20
  availability_zone                     = "us-east-1a"
  backup_retention_period               = 0
  port                                  = 5432
  multi_az                              = false
  db_name                               = data.aws_ssm_parameter.db_name.value
  storage_type                          = "gp2"
  publicly_accessible                   = true
  storage_encrypted                     = true
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  deletion_protection                   = false
  db_subnet_group_name                  = aws_db_subnet_group.cruddur.name
  vpc_security_group_ids                = [aws_security_group.cruddur-sg.id]
  skip_final_snapshot                   = true
}

resource "aws_security_group" "cruddur-sg" {
  name = "cruddur-sg"
  description = "allow postgress access"
  vpc_id = var.vpc_id

  tags = {
    Name = "cruddur security group"
  }  
}

resource "aws_vpc_security_group_ingress_rule" "allow-inbound-postgres" {
  security_group_id = aws_security_group.cruddur-sg.id
  cidr_ipv4 = "${chomp(data.http.my_ip.response_body)}/32" #var.vpc_cidr_block
  from_port = 5432
  to_port = 5432
  ip_protocol = "tcp"
  
}

resource "aws_vpc_security_group_egress_rule" "allow-outbound-postgres" {
  security_group_id = aws_security_group.cruddur-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


