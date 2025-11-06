resource "aws_vpc" "cruddur-vpc" { 
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "cruddur-vpc"
  }
}

resource "aws_subnet" "cruddur-public-subnet" {
  vpc_id = aws_vpc.cruddur-vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1e"
  map_public_ip_on_launch = true
  tags = {
    Name = "cruddur-public-subnet"
  }
}

resource "aws_subnet" "cruddur-private-subnet" {
  vpc_id = aws_vpc.cruddur-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1e"
  tags = {
    Name = "cruddur-private-subnet"
  }
}

resource "aws_internet_gateway" "cruddur-igw" {
  vpc_id = aws_vpc.cruddur-vpc.id
  tags = {
    Name = "cruddur-igw"
  }
}

resource "aws_route_table" "cruddur-public-route-table" {
  vpc_id = aws_vpc.cruddur-vpc.id
  tags = {
    Name = "cruddur-public-route-table"
  }
}

resource "aws_route" "cruddur-public-route" {
  route_table_id = aws_route_table.cruddur-public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.cruddur-igw.id
}


resource "aws_route_table" "cruddur-private-route-table" {
  vpc_id = aws_vpc.cruddur-vpc.id
  tags = {
    Name = "cruddur-private-route-table"
  }
}

resource "aws_route_table_association" "cruddur-public-route-table-association" {
  subnet_id = aws_subnet.cruddur-public-subnet.id
  route_table_id = aws_route_table.cruddur-public-route-table.id    # Associate the public route table with the internet gateway
}

resource "aws_route_table_association" "cruddur-private-route-table-association" {
  subnet_id = aws_subnet.cruddur-private-subnet.id
  route_table_id = aws_route_table.cruddur-private-route-table.id  # Associate the private route table with the private subnet
}

