# Creates the Application Load Balancer (ALB) that distributes
# incoming traffic to targets
resource "aws_lb" "cruddur-alb" {
  name               = "cruddur-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cruddur-alb-sg.id]
  subnets            = var.subnet_ids

  tags = {
    Name        = "${var.name_prefix}-cruddur-alb"
    Environment = var.environment
  }
}

# Creates a security group for the ALB to control inbound and outbound traffic
resource "aws_security_group" "cruddur-alb-sg" {
  name        = "load-balancer-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-load-balancer-sg"
  }

}

# Allows inbound HTTP traffic on port 80 from anywhere (required for 
# HTTP to HTTPS redirect)
resource "aws_vpc_security_group_ingress_rule" "allow-inbound-alb-http" {
  security_group_id = aws_security_group.cruddur-alb-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
  
}

# Allows inbound HTTPS traffic on port 443 from anywhere (main production traffic)
resource "aws_vpc_security_group_ingress_rule" "allow-inbound-alb-https" {
  security_group_id = aws_security_group.cruddur-alb-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  
}

# Temporary: Allows direct access to backend on port 5000 (for 
# testing/debugging, should be removed in production)
resource "aws_vpc_security_group_ingress_rule" "allow-inbound-alb-back" {
  security_group_id = aws_security_group.cruddur-alb-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 5000
  to_port = 5000
  ip_protocol = "tcp"
  
}

# Temporary: Allows direct access to frontend on port 3000 (for 
# testing/debugging, should be removed in production)
resource "aws_vpc_security_group_ingress_rule" "allow-inbound-alb-front" {
  security_group_id = aws_security_group.cruddur-alb-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 3000
  to_port = 3000
  ip_protocol = "tcp"
  
}

# Allows all outbound traffic from ALB to any destination (needed
# to forward requests to targets)
resource "aws_vpc_security_group_egress_rule" "allow-outbound-alb" {
  security_group_id = aws_security_group.cruddur-alb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Creates target group for backend Flask service - routes traffic to
# ECS tasks on port 5000
resource "aws_lb_target_group" "backend-tg" {
  name        = "cruddur-backend-flask-tg"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path = "/api/health-check"
    healthy_threshold = 3
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
  }
}

# Creates target group for frontend React service - routes traffic to
# ECS tasks on port 3000
resource "aws_lb_target_group" "frontend-tg" {
  name        = "cruddur-frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path = "/"
    healthy_threshold = 3
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
  }
}

# Temporary listener: Direct HTTP listener on port 3000 for 
# frontend (for testing, typically removed in production)
# Listener for Frontend (Port 3000)
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.cruddur-alb.arn
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend-tg.arn
  }
}

# Temporary listener: Direct HTTP listener on port 5000 for 
# backend (for testing, typically removed in production)
# Listener for Backend (Port 5000)
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.cruddur-alb.arn
  port              = "5000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend-tg.arn
  }
}

# HTTP listener on port 80 that redirects all traffic to HTTPS (port 443)
# for security
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.cruddur-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Fetches the SSL/TLS certificate from AWS Certificate Manager (ACM) for
# HTTPS encryption
data "aws_acm_certificate" "cruddur_cert" {
  domain      = "devopsky.click"
  most_recent = true
  statuses    = ["ISSUED"]
}

# Main HTTPS listener on port 443 - handles encrypted traffic and routes 
# to frontend by default
# Listener rules can be added to route specific hostnames (e.g., api.devopsky.click) to backend
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.cruddur-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.cruddur_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend-tg.arn
  }
}


resource "aws_lb_listener_rule" "api_backend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend-tg.arn
  }

  condition {
    host_header {
      values = ["api.devopsky.click"]
    }
  }
}

