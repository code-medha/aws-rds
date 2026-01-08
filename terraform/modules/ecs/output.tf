output "ecs_service_security_group_id_cruddur" {
  description = "ID of the ECS service security group for Cruddur"
  value       = aws_security_group.cruddur-service-sg.id
}
