output "instance1_ip" {
  value = aws_instance.instance1.public_ip
}

output "instance2_ip" {
  value = aws_instance.instance2.public_ip
}

output "load_balancer_dns" {
  value = aws_lb.app_lb.dns_name
}

