# ECR Repository for cruddur-python
resource "aws_ecr_repository" "cruddur_python" {
  name                 = "cruddur-python"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true

  tags = {
    Name        = "${var.name_prefix}-ecr-cruddur-python"
    Environment = var.environment
  }
}

# ECR Repository for backend-flask
resource "aws_ecr_repository" "backend_flask" {
  name                 = "backend-flask"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true

  tags = {
    Name        = "${var.name_prefix}-ecr-backend-flask"
    Environment = var.environment
  }
}

# ECR Repository for frontend-react-js
resource "aws_ecr_repository" "frontend_react_js" {
  name                 = "frontend-react-js"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true

  tags = {
    Name        = "${var.name_prefix}-ecr-frontend-react-js"
    Environment = var.environment
  }
}
