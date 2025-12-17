variable "vpc_cidr_block" {
    description = "CIDR block for VPC"
    type = string
}

variable "enable_dns_hostnames" {
    description = "Enable DNS hostnames in VPC"
    type = bool
    default = true
  
}

variable "enable_dns_support" {
    description = "Enable DNS support in VPC"
    type = bool
    default = true
  
}

variable "public_subnets" {
    description = "map of public subnets"
    type = map(string) 
}

variable "name_prefix" {
    description = "Prefix for resource names"
    type = string
}

