#VPC

resource "aws_vpc" "cruddur-vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  
  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}


# Internet gateway

resource "aws_internet_gateway" "cruddur-igw" {
  vpc_id = aws_vpc.cruddur-vpc.id
  
  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# Public Route Table

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cruddur-vpc.id
  
  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

# Default route to the Internet

resource "aws_route" "cruddur-public-route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cruddur-igw.id
}

# Public Subnet across 2 AZs using for each


resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id = aws_vpc.cruddur-vpc.id
  cidr_block = each.value
  availability_zone = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet-${substr(each.key, -1, 1)}"
  }
  
}

# resource "aws_subnet" "cruddur-public-subnet-one" {
#   vpc_id                  = aws_vpc.cruddur-vpc.id
#   cidr_block              = "10.0.0.0/24"
#   availability_zone       = "us-east-1a"
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "cruddur-public-subnet-one"
#   }
# }

# resource "aws_subnet" "cruddur-public-subnet-two" {
#   vpc_id                  = aws_vpc.cruddur-vpc.id
#   cidr_block              = "10.0.1.0/24"
#   availability_zone       = "us-east-1b"
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "cruddur-public-subnet-two"
#   }
# }

# Route Table Associations using for_each

resource "aws_route_table_association" "pulic" {
  for_each = aws_subnet.public

  subnet_id = each.value.id
  route_table_id = aws_route_table.public.id
}


# # Associate the public route table with both public subnets

# resource "aws_route_table_association" "cruddur-table-association-one" {
#   subnet_id      = aws_subnet.cruddur-public-subnet-one.id
#   route_table_id = aws_route_table.cruddur-public-route-table.id
# }

# resource "aws_route_table_association" "cruddur-table-association-two" {
#   subnet_id      = aws_subnet.cruddur-public-subnet-two.id
#   route_table_id = aws_route_table.cruddur-public-route-table.id
# }




