#VPC

resource "aws_vpc" "cruddur-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "cruddur-vpc"
  }
}


# Internet gateway

resource "aws_internet_gateway" "cruddur-igw" {
  vpc_id = aws_vpc.cruddur-vpc.id
  tags = {
    Name = "cruddur-igw"
  }
}

# Public Route Table

resource "aws_route_table" "cruddur-public-route-table" {
  vpc_id = aws_vpc.cruddur-vpc.id
  tags = {
    Name = "cruddur-public-route-table"
  }
}

# Default route to the Internet

resource "aws_route" "cruddur-public-route" {
  route_table_id         = aws_route_table.cruddur-public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cruddur-igw.id
}

# Public Subnet across 2 AZs

resource "aws_subnet" "cruddur-public-subnet-one" {
  vpc_id                  = aws_vpc.cruddur-vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "cruddur-public-subnet-one"
  }
}

resource "aws_subnet" "cruddur-public-subnet-two" {
  vpc_id                  = aws_vpc.cruddur-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "cruddur-public-subnet-two"
  }
}

# Associate the public route table with both public subnets

resource "aws_route_table_association" "cruddur-table-association-one" {
  subnet_id      = aws_subnet.cruddur-public-subnet-one.id
  route_table_id = aws_route_table.cruddur-public-route-table.id
}

resource "aws_route_table_association" "cruddur-table-association-two" {
  subnet_id      = aws_subnet.cruddur-public-subnet-two.id
  route_table_id = aws_route_table.cruddur-public-route-table.id
}




