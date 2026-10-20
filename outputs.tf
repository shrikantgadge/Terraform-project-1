output "load_balancer_url" {
  description = "Open this URL in a browser"
  value       = "http://${aws_lb.web_alb.dns_name}"
}
output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.web_tg.arn
}
output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.web_asg.name
}
