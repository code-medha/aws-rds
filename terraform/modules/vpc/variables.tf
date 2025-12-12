variable "vpc_cidr_block" {
    description = "CIDR block for VPC"
    type = string
    default = "10.0.0.0/16"
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
    default = {
        "us-east-1a" = "10.0.0.0/24"
        "us-east-1b" = "10.0.1.0/24"
  }  
}

variable "project_name" {
    description = "Name of the project"
    type = string
    default = "cruddur"
  
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}
