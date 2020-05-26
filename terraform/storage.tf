
resource "aws_efs_file_system" "elasticsearch" {
  creation_token = "elasticsearch"
}

resource "aws_efs_mount_target" "mount_sn_01" {
  file_system_id = aws_efs_file_system.elasticsearch.id
  subnet_id      = aws_subnet.mmrc_public_sn_01.id
  security_groups = [aws_security_group.mmrc_public_sg.id]
}

resource "aws_efs_mount_target" "mount_sn_02" {
  file_system_id = aws_efs_file_system.elasticsearch.id
  subnet_id      = aws_subnet.mmrc_public_sn_02.id
  security_groups = [aws_security_group.mmrc_public_sg.id]
}
