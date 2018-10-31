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
        ami = "${var.ami}"
        instance_type = "t2.micro"
        key_name = "NewForAnsible"
        security_groups = ["${aws_security_group.terrasg.name}"]
        root_block_device {
         volume_type = "gp2"
         volume_size = "10"
        }
        tags {
         Name = "DockerServer"
        }
        
        provisioner "local-exec" {
        command = "sleep 120 && echo -e \"[DockerServer]\n${aws_instance.myweb.public_ip} ansible_connection=ssh ansible_ssh_user=ec2-user\" > /etc/ansible/hosts && ansible-playbook -i /etc/ansible/hosts master.yml"  
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

        instances = ["${aws_instance.myweb.id}"]
        cross_zone_load_balancing = true
        idle_timeout = 100
        connection_draining = true
        connection_draining_timeout = 300

        tags {
         Name = "terraformelb"
        }

}

output "elb-dns-name"{
        value = "${aws_elb.terraelb.dns_name}"
}

