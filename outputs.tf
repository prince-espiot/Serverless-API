output "s3_bucket_name" {
  value = aws_s3_bucket.storage_bucket.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.my_db.endpoint
}

output "elb_dns_name" {
  value = aws_elb.api_elb.dns_name
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.my_api_deployment.invoke_url
}
