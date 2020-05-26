
resource "aws_ecs_task_definition" "elasticsearch" {
  family                = "elasticsearch"
  container_definitions = templatefile("elasticsearch.json.tmpl", {
      image  = var.elasticsearch_image,
      region = var.region
  })

  volume {
    name = "elasticsearch"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.elasticsearch.id
      root_directory = "/"
    }
  }
}

resource "aws_ecs_service" "elasticsearch-ecs-service" {
  name            = "elasticsearch-ecs-service"
  iam_role        = aws_iam_role.ecs-service-role.name
  cluster         = aws_ecs_cluster.mmrc-elk-cluster.id
  task_definition = aws_ecs_task_definition.elasticsearch.arn
  desired_count   = 1

  load_balancer {
    target_group_arn  = aws_alb_target_group.elasticsearch-group.arn
    container_port    = 9200
    container_name    = "elasticsearch"
  }

  depends_on = [aws_alb_listener.alb-elasticsearch-listener]
}

resource "aws_ecs_task_definition" "logstash" {
  family                = "logstash"
  container_definitions = templatefile("logstash.json.tmpl", {
      image = var.logstash_image
  })
}

resource "aws_ecs_service" "logstash-ecs-service" {
  name            = "logstash-ecs-service"
  cluster         = aws_ecs_cluster.mmrc-elk-cluster.id
  task_definition = aws_ecs_task_definition.logstash.arn
  desired_count   = 1
}

resource "aws_ecs_task_definition" "kibana" {
  family                = "kibana"
  container_definitions = templatefile("kibana.json.tmpl", {
      image = var.kibana_image
  })
}

resource "aws_ecs_service" "kibana-ecs-service" {
  name            = "kibana-ecs-service"
  iam_role        = aws_iam_role.ecs-service-role.name
  cluster         = aws_ecs_cluster.mmrc-elk-cluster.id
  task_definition = aws_ecs_task_definition.kibana.arn
  desired_count   = 1

  load_balancer {
    target_group_arn  = aws_alb_target_group.kibana-group.arn
    container_port    = 5601
    container_name    = "kibana"
  }

  depends_on = [aws_alb_listener.alb-kibana-listener]
}


resource "aws_ecs_task_definition" "filebeat" {
  family                = "filebeat"
  container_definitions = templatefile("filebeat.json.tmpl", {
      image = var.filebeat_image
  })

  volume {
    name      = "containers"
    host_path = "/var/lib/docker/containers"
  }

  volume {
    name      = "docker-sock"
    host_path = "/var/run/docker.sock"
  }
}

resource "aws_ecs_service" "filebeat-ecs-service" {
  name            = "filebeat-ecs-service"
  cluster         = aws_ecs_cluster.mmrc-elk-cluster.id
  task_definition = aws_ecs_task_definition.filebeat.arn
  desired_count   = 1
}


resource "aws_ecs_task_definition" "apache" {
  family                = "apache"
  container_definitions = templatefile("apache.json.tmpl", {
      image = var.apache_image
  })
}

resource "aws_ecs_service" "apache-ecs-service" {
  name            = "apache-ecs-service"
  iam_role        = aws_iam_role.ecs-service-role.name
  cluster         = aws_ecs_cluster.mmrc-elk-cluster.id
  task_definition = aws_ecs_task_definition.apache.arn
  desired_count   = 1

  load_balancer {
    target_group_arn  = aws_alb_target_group.apache-group.arn
    container_port    = 80
    container_name    = "apache"
  }

  depends_on = [aws_alb_listener.alb-apache-listener]
}

