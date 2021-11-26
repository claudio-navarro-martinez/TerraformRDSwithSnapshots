provider "aws" {
  region = "eu-west-1"
}

#### demodb-oracle-copy.c08fgkmewvuy.eu-west-1.rds.amazonaws.com

### sqlplus complete_oracle/xxxxxxx@demodb-oracle-copy.c08fgkmewvuy.eu-west-1.rds.amazonaws.com/ORARDSCP
# Get latest snapshot from production DB
data "aws_db_snapshot" "db_snapshot" {
    most_recent = true
    db_instance_identifier = "demodb-oracle"
}

#Apply scheme by using bastion host
resource "aws_db_instance" "default_bastion" {
  identifier           = "demodb-oracle-copy"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "oracle-se2"
  engine_version       = "19.0.0.0.ru-2021-01.rur-2021-01.r2"
  instance_class       = "db.m5.large"
  license_model        = "bring-your-own-license"

  name                   = "ORARDSCP"
  username               = "complete_oracle"
  password               = "xxxxxxxxxxx"   (mas de 8 caracteres)
  port                   = 1521
  multi_az               = true
  #subnet_ids             = ["subnet-0a68c77f57eced43d","subnet-0a6a752dc3d37060d","subnet-0b2fbba75925f14f4"]
  
  skip_final_snapshot  = true
  db_subnet_group_name = "demodb-oracle-20211125100327291400000005"
  snapshot_identifier  = data.aws_db_snapshot.db_snapshot.id
  vpc_security_group_ids = ["sg-00abf46aacccb7adb"]

  publicly_accessible  = false
  character_set_name = "AL32UTF8"

#   provisioner "file" {
#       connection {
#       user        = "ec2-user"
#       host        = "x.x.x.x"
#       private_key = file("~/Downloads/awsinformatestsandbox.pem")
#         }
#     source      = "~/Downloads/instantclient-basic-linux.x64-19.8.0.0.0dbru.zip"
#     destination = "~"
#   }

#   provisioner "file" {
#       connection {
#       user        = "ec2-user"
#       host        = "x.x.x.x"
#       private_key = file("~/Downloads/awsinformatestsandbox.pem")
#         }
#     source      = "~/Downloads/instantclient-sqlplus-linux.x64-19.8.0.0.0dbru.zip"
#     destination = "~"
#   }

  provisioner "remote-exec" {
      connection {
            user        = "ec2-user"
            host        = "x.x.x.x"
            private_key = file("~/Downloads/awsinformatestsandbox.pem")
       }
      inline = [
            "uname -a > /tmp/kk.cnm.txt",
            "wget https://yum.oracle.com/public-yum-ol7.repo",
            "wget http://public-yum.oracle.com/RPM-GPG-KEY-oracle-ol7 -O /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle",
            "yum install -y yum-utils",
            "yum-config-manager --enable ol7_oracle_instantclient",
            "yum install -y oracle-instantclient19.9-basic.x86_64 oracle-instantclient19.9-sqlplus.x86_64",
            "export CLIENT_HOME=/usr/lib/oracle/19.9/client64",
            "export LD_LIBRARY_PATH=$CLIENT_HOME/lib",
            "export PATH=$PATH:$CLIENT_HOME/bin",
            "echo 'select * from dual' | sqlplus complete_oracle/xxxxxx@demodb-oracle-copy.c08fgkmewvuy.eu-west-1.rds.amazonaws.com/ORARDSCP",
    ]
  }
}

