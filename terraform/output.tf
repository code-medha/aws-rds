# Root-level outputs for ECR repositories
output "cruddur_python_repository_url" {
  description = "URL of the cruddur-python ECR repository"
  value       = module.ecr.cruddur_python_repository_url
}

output "backend_flask_repository_url" {
  description = "URL of the backend-flask ECR repository"
  value       = module.ecr.backend_flask_repository_url
}

output "frontend_react_js_repository_url" {
  description = "URL of the frontend-react-js ECR repository"
  value       = module.ecr.frontend_react_js_repository_url
}

