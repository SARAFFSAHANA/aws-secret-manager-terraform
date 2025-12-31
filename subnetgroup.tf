resource "aws_db_subnet_group" "mysql" {
  name = "mysql-subnet-group"

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name = "mysql-db-subnet-group"
  }
}
