resource "aws_security_group" "terrasg" {
        name = "terraform-sg"
        description = "Web Security Group"
        
        ingress {
                from_port = 22
                to_port = 22
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        ingress {
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }

        egress {
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
}

resource "aws_instance" "myweb" {
        count = "${var.count}"
        ami = "${var.ami}"
        instance_type = "t2.micro"
        key_name = "NewForAnsible"
        security_groups = ["${aws_security_group.terrasg.name}"]
        root_block_device {
         volume_type = "gp2"
         volume_size = "10"
        }
        tags {
         Name = "DockerServer-${count.index + 1}"
        }
        
        
}

resource "aws_launch_configuration" "example" {
  image_id               = "${var.ami}"
  instance_type          = "t2.micro"
  security_groups        = ["${aws_security_group.terrasg.name}"]
  key_name               = "NewForAnsible"
  lifecycle {
    create_before_destroy = true
  }
}

## Creating AutoScaling Group
resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = ["ap-south-1a"]
  min_size = 1
  max_size = 1
  load_balancers = ["${aws_elb.terraelb.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "terraelb" {
        name = "terraform-elb"
        subnets = ["subnet-805ba0e8"]
        security_groups = ["${aws_security_group.terrasg.id}"]
        listener {
         instance_port = 80
         instance_protocol = "http"
         lb_port = 80
         lb_protocol = "http"
        }

        health_check {
         healthy_threshold = 2
         unhealthy_threshold = 2
         timeout = 3
         target = "TCP:80"
         interval = 5
        }


}

output "elb-dns-name"{
        value = "${aws_elb.terraelb.dns_name}"
}

