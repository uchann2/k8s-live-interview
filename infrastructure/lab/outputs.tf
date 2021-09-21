
data "aws_instance" "ssh-details" {
  filter {
    name   = "tag:Name"
    values = ["${var.unique-prefix}-k8s-lab-instance"]
  }
  depends_on = [
    aws_instance.k8s-lab-baremetal-instance,
    aws_instance.k8s-lab-ami-instance
  ]
}

output "ssh-details" {
  value       = "ssh -i ./files/k8s_lab_rsa ubuntu@${data.aws_instance.ssh-details.public_ip}"
  description = "SSH details"
}
