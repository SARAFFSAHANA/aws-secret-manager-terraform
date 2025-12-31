resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = "appdb"

  username = local.mysql_credentials.username
  password = local.mysql_credentials.password

  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.mysql.name

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "mysql-rds-instance"
  }
}
