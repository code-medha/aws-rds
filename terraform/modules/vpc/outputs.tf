output "public_subnet_id" {
  description = "IDs of the public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "vpc_id_cruddur" {
  description = "ID of the VPC for Cruddur"
  value       = aws_vpc.cruddur-vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block used for RDS SG ingress"
  value = aws_vpc.cruddur-vpc.cidr_block
}

