provider "aws" {
  region = "us-east-1"
}

# S3 Bucket for storage
resource "aws_s3_bucket" "storage_bucket" {
  bucket = "my-application-storage-bucket"
  
}

# DynamoDB Table
resource "aws_dynamodb_table" "my_table" {
  name         = "MyTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# RDS Database
resource "aws_db_instance" "my_db" {
  allocated_storage    = 20
  max_allocated_storage = 100
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  db_name              = "mydb"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.postgres12"
  skip_final_snapshot  = true
}

# ElastiCache Cluster (Redis)
resource "aws_elasticache_cluster" "my_cache" {
  cluster_id           = "my-cache-cluster"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
}

# Security Group for EC2 Instances
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-sg"
  description = "Allow all inbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance for API Servers
resource "aws_instance" "api_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t3.micro"
  count         = 2
  security_groups = [aws_security_group.ec2_security_group.name]

  tags = {
    Name = "API Server"
  }
}

# Auto Scaling Group for EC2 Instances
resource "aws_autoscaling_group" "api_asg" {
  launch_configuration = aws_launch_configuration.api_launch_config.id
  min_size             = 1
  max_size             = 10
  desired_capacity     = 2

  tag {
    key                 = "Name"
    value               = "API Server"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "api_launch_config" {
  name          = "api-launch-configuration"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  security_groups = [aws_security_group.ec2_security_group.name]

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic Load Balancer
resource "aws_elb" "api_elb" {
  name = "api-elb"
  availability_zones = ["us-east-1a", "us-east-1b"]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  instances = aws_instance.api_server.*.id
}

# API Gateway
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "MyAPI"
  description = "API for my application"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "resource"
}

# API Gateway Method
resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Integration with ELB
resource "aws_api_gateway_integration" "api_integration" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST"
  type = "HTTP"

  uri = aws_elb.api_elb.dns_name
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/api/my_api"
  retention_in_days = 14
}

# CloudWatch Alarm (Example)
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "high_cpu_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    InstanceId = aws_instance.api_server.id
  }

  alarm_description = "This alarm triggers if the CPU utilization exceeds 80% for 2 consecutive periods of 120 seconds."
}

# Outputs
output "s3_bucket_name" {
  value = aws_s3_bucket.storage_bucket.id
}

output "rds_endpoint" {
  value = aws_db_instance.my_db.endpoint
}

output "dynamodb_table" {
  value = aws_dynamodb_table.my_table.name
}

output "api_endpoint" {
  value = aws_api_gateway_deployment.my_api_deployment.invoke_url
}

