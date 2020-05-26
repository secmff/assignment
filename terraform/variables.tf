variable "region" {
  description = "AWS region name"
}

variable "instance_type" {
  description = "instance type to use for the ECS cluster"
}
  
variable "availability_zone_1" {
  description = "AWS availability zone"
}

variable "availability_zone_2" {
  description = "AWS availability zone"
}

variable "ecs_key_pair_name" {
  description = "EC2 instance key pair name"
}

variable "public_cidr" {
  description = "trusted public IP access"
}

variable "elasticsearch_image" {
  description = "docker image for elastic search (generated with: build_ecs_image.sh"
}

variable "logstash_image" {
  description = "docker image for logstash (generated with: build_ecs_image.sh"
}

variable "kibana_image" {
  description = "docker image for kibana (generated with: build_ecs_image.sh"
}

variable "filebeat_image" {
  description = "docker image for filebeat (generated with: build_ecs_image.sh"
}

variable "apache_image" {
  description = "docker image for apache (generated with: build_ecs_image.sh"
}
