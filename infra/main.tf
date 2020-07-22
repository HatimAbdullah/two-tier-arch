module "fish_labels" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = "no-man-land"
  environment = "trees"
  name        = "no one goes unnoticed"
  attributes  = ["public"]
  delimiter   = "_"

  tags = {
    "owner" = var.name
  }

}


module "bastion" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = "no-man-land"
  environment = "practice"
  name        = "bastion_env"
  attributes  = ["bastion"]
  delimiter   = "_"

  tags = {
    "owner" = var.name
  }

}


module "cp" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = "no-man-land"
  environment = "practice"
  name        = "cp_env"
  attributes  = ["control-plane"]
  delimiter   = "_"

  tags = {
    "owner" = var.name
  }

}


module "worker" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = "no-man-land"
  environment = "practice"
  name        = "worker_env"
  attributes  = ["worker"]
  delimiter   = "_"

  tags = {
    "owner" = var.name
  }

}

resource "aws_route53_zone" "fish-off-access" {
  name = "nobodyknowswhereyouare.brmbmbmbmbm"
  tags = module.fish_labels.tags
  vpc {
    vpc_id = aws_vpc.ocean.id
  }
}

resource "aws_vpc" "ocean" {
  cidr_block           = "10.0.0.0/16"
  tags                 = module.fish_labels.tags
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "ocean_gateway" {
  vpc_id = aws_vpc.ocean.id
  tags   = module.fish_labels.tags
}

resource "aws_route" "ocean_internet_access" {
  route_table_id         = aws_vpc.ocean.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ocean_gateway.id
}

resource "aws_subnet" "bastion" {
  vpc_id                  = aws_vpc.ocean.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags                    = module.bastion.tags
}

resource "aws_subnet" "worker" {
  count                   = 2
  vpc_id                  = aws_vpc.ocean.id
  cidr_block              = format("10.0.%s.0/24", count.index + 1)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = module.worker.tags
}

resource "aws_subnet" "cp" {
  count                   = 2
  vpc_id                  = aws_vpc.ocean.id
  cidr_block              = format("10.0.%s.0/24", count.index + 3)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = module.cp.tags
}


data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_security_group" "bastion" {
  name        = "bastion"
  vpc_id      = aws_vpc.ocean.id
  tags        = module.bastion.tags
  description = "Security Group for the masses"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
    cidr_blocks = [
    "0.0.0.0/0"]

  }
}

resource "aws_security_group" "workers" {
  name        = "workers"
  vpc_id      = aws_vpc.ocean.id
  tags        = module.worker.tags
  description = "Security Group for the worker nodes"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    security_groups = [aws_security_group.bastion.id, aws_security_group.control-plane.id]
  }
}

resource "aws_security_group" "control-plane" {
  name        = "control-plane"
  vpc_id      = aws_vpc.ocean.id
  tags        = module.cp.tags
  description = "Security Group for the cp nodes"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6969
    to_port     = 6969
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

resource "aws_security_group_rule" "ingress_instances" {
  description = "Incoming traffic from bastion"
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "TCP"

  source_security_group_id = aws_security_group.bastion.id

  security_group_id = aws_security_group.control-plane.id
}

resource "aws_key_pair" "sunk_keypair" {
  key_name   = format("%s%s", var.name, "_keypair")
  public_key = file(var.public_key_path)
}

resource "aws_instance" "bastion" {
  instance_type          = "t3.micro"
  ami                    = lookup(var.aws_amis, var.aws_region)
  key_name               = aws_key_pair.sunk_keypair.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = aws_subnet.bastion.id
  tags                   = module.bastion.tags
}


resource "aws_launch_configuration" "nodes_config" {
  image_id        = "ami-09d057a8621c5b6fb"
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.workers.id]
  key_name        = aws_key_pair.sunk_keypair.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ocean_ASG" {
  max_size                  = 3
  min_size                  = 2
  launch_configuration      = aws_launch_configuration.nodes_config.name
  health_check_grace_period = 300

  health_check_type   = "EC2"
  vpc_zone_identifier = aws_subnet.worker.*.id

  target_group_arns = [aws_lb_target_group.worker_tg.arn]

  tag {
    key                 = "owner"
    value               = var.name
    propagate_at_launch = true
  }

  tag {
    key                 = "type"
    value               = "worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "environment"
    value               = "worker_env"
    propagate_at_launch = true
  }

  tag {
    key                 = "name"
    value               = "worker"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_instance.control_nodes,
  ]
}

resource "aws_lb" "worker_lb" {
  name               = "worker-lb"
  load_balancer_type = "application"
  subnets            = aws_subnet.worker.*.id
  security_groups    = [aws_security_group.workers.id]
  tags               = module.worker.tags
}

resource "aws_autoscaling_attachment" "asg" {
  autoscaling_group_name = aws_autoscaling_group.ocean_ASG.id
  alb_target_group_arn   = aws_lb_target_group.worker_tg.arn
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.worker_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "worker_tg" {
  name     = "worker-tg"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = aws_vpc.ocean.id
  tags     = module.worker.tags
}

resource "aws_lb_listener_rule" "worker_lr" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.worker_tg.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

#control plane

#resource "aws_elb" "cp_elb" {
#  name = format("%selb", var.name)
#  subnets = aws_subnet.cp.*.id
#  security_groups = [aws_security_group.control-plane.id]
#  instances = aws_instance.control_nodes.*.id

#  listener {
#    instance_port     = 80
#    instance_protocol = "http"
#    lb_port           = 80
#    lb_protocol       = "http"
#  }

#  tags = module.fish_labels.tags
#}

resource "aws_instance" "control_nodes" {
  instance_type          = "t3.large"
  ami                    = "ami-0ccbf0b7573581ed7"
  key_name               = aws_key_pair.sunk_keypair.id
  vpc_security_group_ids = [aws_security_group.control-plane.id]
  subnet_id              = aws_subnet.cp[1].id
  tags                   = module.cp.tags
}

resource "aws_route53_record" "cp-env" {
  zone_id = aws_route53_zone.fish-off-access.id
  name    = "cp"
  type    = "A"
  ttl     = "300"

  records = [aws_instance.control_nodes.private_ip]
}

