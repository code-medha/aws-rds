output "alb_security_group_id_cruddur" {
  description = "ID of the ALB security group for Cruddur"
  value       = aws_security_group.cruddur-alb-sg.id
}

output "aws_lb_target_group_backend" {
   description = "ARN of the backend target group"
   value = aws_lb_target_group.backend-tg.arn
  
}

output "aws_lb_target_group_frontend" {
   description = "ARN of the frontend target group"
   value = aws_lb_target_group.frontend-tg.arn
  
}
