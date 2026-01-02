resource "aws_security_group" "cruddur-service-sg" {
  name        = "ECS-service-sg"
  description = "ECS service security group"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "allow-inbound-alb-backend" {
  security_group_id = aws_security_group.cruddur-service-sg.id
  from_port = 5000
  to_port = 5000
  referenced_security_group_id = var.alb_security_group_id
  ip_protocol = "tcp"
  
}


resource "aws_vpc_security_group_ingress_rule" "allow-inbound-alb-frontend" {
  security_group_id = aws_security_group.cruddur-service-sg.id
  from_port = 3000
  to_port = 3000
  referenced_security_group_id = var.alb_security_group_id
  ip_protocol = "tcp"
  
}

resource "aws_vpc_security_group_egress_rule" "allow-outbound-alb" {
  security_group_id = aws_security_group.cruddur-service-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
