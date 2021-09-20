resource "aws_key_pair" "k8s-lab-instance" {
  key_name   = "k8s-lab-instance"
  public_key = file("${path.module}/../files/k8s_lab_rsa.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

data "template_file" "bootstrap" {
  template = file("${path.module}/../files/bootstrap.sh.tpl")
}

data "template_file" "healthcheck" {
  template = file("${path.module}/../files/healthcheck.sh.tpl")
}

resource "aws_instance" "k8s-lab-instance" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.medium"
  key_name        = aws_key_pair.k8s-lab-instance.key_name
  security_groups = [aws_security_group.k8s-lab-sg.id]
  subnet_id       = data.aws_subnet.default_subnet.id

  root_block_device {
    volume_size = 30
    volume_type = "standard"
  }

  provisioner "file" {
    content     = data.template_file.bootstrap.rendered
    destination = "/home/ubuntu/bootstrap.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/../files/k8s_lab_rsa")
      host        = aws_instance.k8s-lab-instance.public_ip
    }
  }
  provisioner "file" {
    content     = data.template_file.healthcheck.rendered
    destination = "/home/ubuntu/healthcheck.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/../files/k8s_lab_rsa")
      host        = aws_instance.k8s-lab-instance.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/bootstrap.sh",
      "/home/ubuntu/bootstrap.sh",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/../files/k8s_lab_rsa")
      host        = aws_instance.k8s-lab-instance.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/healthcheck.sh",
      "/home/ubuntu/healthcheck.sh",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/../files/k8s_lab_rsa")
      host        = aws_instance.k8s-lab-instance.public_ip
    }
  }
}
