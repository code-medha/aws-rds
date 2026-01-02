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

resource "aws_security_group" "cruddur-alb-sg" {
  name        = "load-balancer-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "allow-inbound-alb-http" {
  security_group_id = aws_security_group.cruddur-alb-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
  
}

resource "aws_vpc_security_group_ingress_rule" "allow-inbound-alb-https" {
  security_group_id = aws_security_group.cruddur-alb-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  
}

#temporary
resource "aws_vpc_security_group_ingress_rule" "allow-inbound-alb-back" {
  security_group_id = aws_security_group.cruddur-alb-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 5000
  to_port = 5000
  ip_protocol = "tcp"
  
}

#temporary
resource "aws_vpc_security_group_ingress_rule" "allow-inbound-alb-front" {
  security_group_id = aws_security_group.cruddur-alb-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 3000
  to_port = 3000
  ip_protocol = "tcp"
  
}

resource "aws_vpc_security_group_egress_rule" "allow-outbound-alb" {
  security_group_id = aws_security_group.cruddur-alb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

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


