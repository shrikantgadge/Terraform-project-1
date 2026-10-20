output "load_balancer_url" {
  value = "http://${aws_lb.web_alb.dns_name}"
}

output "target_group_arn" {
  value = aws_lb_target_group.web_tg.arn
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.web_asg.name
}
