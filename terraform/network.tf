
## NETWORKING PART
resource "aws_vpc" "mmrc_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "mmrc_ig" {
  vpc_id = aws_vpc.mmrc_vpc.id
}

resource "aws_subnet" "mmrc_pubsn" {
  vpc_id = aws_vpc.mmrc_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = var.availability_zone_1
}

resource "aws_route_table" "mmrc_pubsn_rt" {
  vpc_id = aws_vpc.mmrc_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mmrc_ig.id
  }
}

resource "aws_subnet" "mmrc_public_sn_01" {
  vpc_id = aws_vpc.mmrc_vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = var.availability_zone_1
}

resource "aws_subnet" "mmrc_public_sn_02" {
  vpc_id = aws_vpc.mmrc_vpc.id
  cidr_block = "10.0.20.0/24"
  availability_zone = var.availability_zone_2
}

resource "aws_route_table_association" "mmrc_pubsn_assn" {
  subnet_id = aws_subnet.mmrc_pubsn.id
  route_table_id = aws_route_table.mmrc_pubsn_rt.id
}

resource "aws_route_table_association" "mmrc_pubsn_assn_01" {
  subnet_id = aws_subnet.mmrc_public_sn_01.id
  route_table_id = aws_route_table.mmrc_pubsn_rt.id
}

resource "aws_route_table_association" "mmrc_pubsn_assn_02" {
  subnet_id = aws_subnet.mmrc_public_sn_02.id
  route_table_id = aws_route_table.mmrc_pubsn_rt.id
}

resource "aws_security_group" "mmrc_public_sg" {
  name = "mmrc_public_sg"
  description = "Public access security group"
  vpc_id = aws_vpc.mmrc_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      var.public_cidr
    ]
  }

  ingress {
    from_port = 9200
    to_port = 9200
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 5601
    to_port = 5601
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true
    cidr_blocks = [
      var.public_cidr,
      "10.0.0.0/16"
    ]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_route53_zone" "private" {
  name = "local"
  vpc {
    vpc_id = aws_vpc.mmrc_vpc.id
  }
}

resource "aws_alb" "ecs-load-balancer" {
    name                = "ecs-load-balancer"
    security_groups     = [aws_security_group.mmrc_public_sg.id]
    subnets             = [aws_subnet.mmrc_public_sn_01.id, aws_subnet.mmrc_public_sn_02.id]
}

# loadbalance configuration for elasticsearch
resource "aws_alb_target_group" "elasticsearch-group" {
    name                = "elasticsearch-group"
    port                = "9200"
    protocol            = "HTTP"
    vpc_id              = aws_vpc.mmrc_vpc.id

    health_check {
        healthy_threshold   = "5"
        unhealthy_threshold = "2"
        interval            = "30"
        matcher             = "200"
        path                = "/_cat/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = "5"
    }
}

resource "aws_alb_listener" "alb-elasticsearch-listener" {
    load_balancer_arn = aws_alb.ecs-load-balancer.arn
    port              = "9200"
    protocol          = "HTTP"

    default_action {
        target_group_arn = aws_alb_target_group.elasticsearch-group.arn
        type             = "forward"
    }
}

resource "aws_route53_record" "elasticsearch" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "elasticsearch"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_alb.ecs-load-balancer.dns_name]
}

# loadbalance configuration for kibana
resource "aws_alb_target_group" "kibana-group" {
    name                = "kibana-group"
    port                = "5601"
    protocol            = "HTTP"
    vpc_id              = aws_vpc.mmrc_vpc.id

    health_check {
        healthy_threshold   = "5"
        unhealthy_threshold = "2"
        interval            = "30"
        matcher             = "200"
        path                = "/app/kibana"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = "5"
    }
}

resource "aws_alb_listener" "alb-kibana-listener" {
    load_balancer_arn = aws_alb.ecs-load-balancer.arn
    port              = "5601"
    protocol          = "HTTP"

    default_action {
        target_group_arn = aws_alb_target_group.kibana-group.arn
        type             = "forward"
    }
}

resource "aws_route53_record" "kibana" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "kibana"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_alb.ecs-load-balancer.dns_name]
}

# loadbalance configuration for apache
resource "aws_alb_target_group" "apache-group" {
    name                = "apache-group"
    port                = "80"
    protocol            = "HTTP"
    vpc_id              = aws_vpc.mmrc_vpc.id

    health_check {
        healthy_threshold   = "5"
        unhealthy_threshold = "2"
        interval            = "30"
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = "5"
    }
}

resource "aws_alb_listener" "alb-apache-listener" {
    load_balancer_arn = aws_alb.ecs-load-balancer.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        target_group_arn = aws_alb_target_group.apache-group.arn
        type             = "forward"
    }
}

resource "aws_route53_record" "apache" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "apache"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_alb.ecs-load-balancer.dns_name]
}

