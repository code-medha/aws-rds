# Outputs for cruddur-python repository
output "cruddur_python_repository_url" {
  description = "URL of the cruddur-python ECR repository"
  value       = aws_ecr_repository.cruddur_python.repository_url
}

output "cruddur_python_repository_name" {
  description = "Name of the cruddur-python ECR repository"
  value       = aws_ecr_repository.cruddur_python.name
}

# Outputs for backend-flask repository
output "backend_flask_repository_url" {
  description = "URL of the backend-flask ECR repository"
  value       = aws_ecr_repository.backend_flask.repository_url
}

output "backend_flask_repository_name" {
  description = "Name of the backend-flask ECR repository"
  value       = aws_ecr_repository.backend_flask.name
}

# Outputs for frontend-react-js repository
output "frontend_react_js_repository_url" {
  description = "URL of the frontend-react-js ECR repository"
  value       = aws_ecr_repository.frontend_react_js.repository_url
}

output "frontend_react_js_repository_name" {
  description = "Name of the frontend-react-js ECR repository"
  value       = aws_ecr_repository.frontend_react_js.name
}
