# Terraform-project-1
my terraform project


# AWS Auto Scaling with Terraform

This project provisions an Application Load Balancer (ALB), target group, EC2 launch template, Auto Scaling Group (ASG), security groups, and a request-count target tracking scaling policy in AWS Mumbai (`ap-south-1`).

## Architecture
Internet → ALB (HTTP/80) → Target Group → EC2 instances managed by ASG

- Initial desired capacity: 2 EC2 instances
- Minimum capacity: 2
- Maximum capacity: 4
- Scaling metric: `ALBRequestCountPerTarget`
- Nginx is installed through EC2 user data.

## Prerequisites
- Terraform 1.5+
- AWS CLI configured with credentials and sufficient IAM permissions
- A default VPC with suitable subnets in at least two Availability Zones

## Deploy
Run in this directory:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Open the URL printed by:

```bash
terraform output load_balancer_url
```

## Cleanup
```bash
terraform destroy
```
Review the proposed changes before confirming. AWS charges may apply while resources exist.

## Notes
- The web page shows the responding EC2 instance ID and private IP.
- The Server 1/2/3 label is a display label derived from the instance ID suffix, not a guaranteed unique ordinal.
- Browser refreshes alone do not guarantee scaling; the request-count policy needs enough traffic and time for metric evaluation.
- Never commit AWS keys, Terraform state, or sensitive variable files to GitHub.

##EC2 par traffic badhao — automatic scaling test
 ```bash
URL=$(terraform output -raw load_balancer_url)

for i in {1..100}; do
  curl -s "$URL" > /dev/null &
done

wait
```
##Verify karo ki EC2 scale hue ya nahi
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names terraform-web-asg \
  --query "AutoScalingGroups[0].{Desired:DesiredCapacity,Instances:Instances[*].InstanceId}" \
  --output table
```

##Check karo instances badhe ya nahi
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name terraform-web-asg \
  --region ap-south-1 \
  --query "AutoScalingGroups[0].{Desired:DesiredCapacity,Instances:Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus}}" \
  --output table
```


