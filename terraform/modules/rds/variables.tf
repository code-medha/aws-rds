variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block used for RDS SG ingress"
  type = string
  
}

variable "name_prefix" {
    description = "Prefix for resource names"
    type = string
}

variable "ecs_service_security_group_id" {
  description = "ID of the ECS service security group"
  type        = string
}

variable "db_identifier" {
    description = "Database identifier"
    type = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type = string
}

variable "db_engine" {
  description = "Database engine"
  type        = string
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
}

variable "publicly_accessible" {
  description = "Make RDS publicly accessible"
  type        = bool
}

variable "deletion_protection" {
  description = "Deletion protection"
  type = bool
}

variable "skip_snapshot" {
  description = "skip final snaphot before deletion"
  type = bool

}

