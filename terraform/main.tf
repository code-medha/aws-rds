# VPC Module
module "vpc" {
  source = "./modules/vpc"
  name_prefix = local.name_prefix
  vpc_cidr_block = var.vpc_cidr_block
  public_subnets = var.public_subnets

}

# # RDS Module
# module "rds" {
#   source = "./modules/rds"
#   subnet_ids = module.vpc.public_subnet_id
#   vpc_id = module.vpc.vpc_id_cruddur
#   vpc_cidr_block = module.vpc.vpc_cidr_block

#   db_identifier = var.db_identifier
#   db_instance_class = var.db_instance_class
#   db_engine = var.db_engine
#   db_engine_version = var.db_engine_version
#   allocated_storage = var.allocated_storage
#   aws_region = var.aws_region
#   backup_retention_period = var.backup_retention_period
#   multi_az = var.multi_az
#   publicly_accessible = var.publicly_accessible
#   deletion_protection = var.deletion_protection
#   skip_snapshot = var.skip_snapshot

#   name_prefix = local.name_prefix

#   depends_on = [module.vpc]
# }

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  name_prefix = local.name_prefix
  environment = local.environment
  image_tag_mutability = var.image_tag_mutability
}

# Application load balancer
module "alb" {
  source = "./modules/alb"
  vpc_id = module.vpc.vpc_id_cruddur
  subnet_ids = module.vpc.public_subnet_id
  name_prefix = local.name_prefix
  environment = local.environment

  depends_on = [module.vpc]
  
}

# Elastic Container Service
module "ecs" {
  source = "./modules/ecs"
  vpc_id = module.vpc.vpc_id_cruddur
  subnet_ids = module.vpc.public_subnet_id
  alb_security_group_id = module.alb.alb_security_group_id_cruddur
  name_prefix = local.name_prefix
  environment = local.environment

  depends_on = [module.vpc, module.alb]
  
}

