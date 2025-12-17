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

#rds
variable "db_identifier" {
  description = "Database identifier"
  type = string
  default = "cruddur-db-instance"
  
}

variable "db_instance_class" {
  description = "RDS instance class"
  type = string
  default = "db.t3.micro"
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "14.15"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1a"
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 0
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Make RDS publicly accessible"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Deletion protection"
  type = bool
  default = false
}

variable "skip_snapshot" {
  description = "skip final snaphot before deletion"
  type = bool
  default = true
}

#vpc
variable "vpc_cidr_block" {
    description = "CIDR block for VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnets" {
    description = "map of public subnets"
    type = map(string)
    default = {
        "us-east-1a" = "10.0.0.0/24"
        "us-east-1b" = "10.0.1.0/24"
  }  
}
