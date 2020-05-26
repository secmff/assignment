resource "aws_launch_configuration" "ecs-launch-configuration" {
  name                 = "ecs-launch-configuration"
  image_id             = "ami-0a74b180a0c97ecd1"
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ecs-instance-profile.id

  root_block_device {
    volume_type           = "standard"
    volume_size           = 100
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  security_groups             = [aws_security_group.mmrc_public_sg.id]
  associate_public_ip_address = "true"
  key_name                    = var.ecs_key_pair_name
  user_data                   = file("user_data.sh")
}

resource "aws_autoscaling_group" "ecs-autoscaling-group" {
  name                        = "ecs-autoscaling-group"
  max_size                    = 1
  min_size                    = 0
  desired_capacity            = 1
  vpc_zone_identifier         = [aws_subnet.mmrc_public_sn_01.id, aws_subnet.mmrc_public_sn_02.id]
  launch_configuration        = aws_launch_configuration.ecs-launch-configuration.name
  health_check_type           = "EC2"

  tag {
    key                 = "ElasticSearch"
    value               = "mmrc-n-elk"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "ECS Instance - EC2Container"
    propagate_at_launch = true
  }
}

resource "aws_ecs_cluster" "mmrc-elk-cluster" {
  name = "mmrc-n-elk"
}
