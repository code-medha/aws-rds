locals {
    project = var.project_name
    environment = var.environment

    name_prefix = "${var.project_name}-${var.environment}"
  
}
