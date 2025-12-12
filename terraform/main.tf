# VPC Module
module "vpc" {
  source = "./modules/vpc"

}

# # RDS Module
# module "rds" {
#   source = "./modules/rds"
#   subnet_ids = module.vpc.public_subnet_id
#   vpc_id = module.vpc.vpc_id_cruddur
#   vpc_cidr_block = module.vpc.vpc_cidr_block
#   depends_on = [module.vpc]
# }
