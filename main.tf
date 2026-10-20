data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "terraform-alb-sg-"
  description = "Allow HTTP traffic to the ALB"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name_prefix = "terraform-ec2-sg-"
  description = "Allow HTTP only from ALB"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "web_tg" {
  name_prefix = "webtg-"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb" "web_alb" {
  name_prefix        = "web-alb-"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_launch_template" "web_lt" {
  name_prefix   = "terraform-web-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {}))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "terraform-autoscaling-web"
      Project = "terraform-aws-auto-scaling"
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name_prefix         = "terraform-web-asg-"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.web_tg.arn]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 180
  wait_for_capacity_timeout = "10m"

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "Name"
    value               = "terraform-autoscaling-web"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "request_scaling" {
  name                   = "terraform-request-scaling"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  target_tracking_configuration {
    target_value = 1000.0
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${aws_lb.web_alb.arn_suffix}/${aws_lb_target_group.web_tg.arn_suffix}"
    }
  }
}
