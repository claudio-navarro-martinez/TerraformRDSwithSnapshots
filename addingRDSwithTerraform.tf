provider "aws" {
  region = local.region
}

locals {
  name   = "complete-oracle"
  region = "eu-west-1"
  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2"

  name = local.name
  cidr = "10.99.0.0/18"

  azs              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets   = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
  private_subnets  = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]
  database_subnets = ["10.99.7.0/24", "10.99.8.0/24", "10.99.9.0/24"]

  create_database_subnet_group = true
  enable_dns_hostnames = true
  enable_dns_support   = true
    
  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3"

  name        = local.name
  description = "Complete Oracle example security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 1521
      to_port     = 1521
      protocol    = "tcp"
      description = "Oracle access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}

################################################################################
# RDS Module ### METELE en la subnet complete-oracle-db-eu-west-1b una route table
### 0.0.0.0/0	igw-00e63c15f653ff6b5 
################################################################################

module "db" {
  source = "../../"

  identifier = "demodb-oracle"

  engine               = "oracle-se2"
  engine_version       = "19.0.0.0.ru-2021-01.rur-2021-01.r2"
  family               = "oracle-se2-19"           # DB parameter group
  major_engine_version = "19"           # DB option group
  instance_class       = "db.m5.large"
  license_model        = "bring-your-own-license"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = false

  # Make sure that database name is capitalized, otherwise RDS will try to recreate RDS instance every time
  name                   = "ORARDS"
  username               = "complete_oracle"
  create_random_password = true    # check password in the status file generated after terraform apply
  random_password_length = 12
  port                   = 1521

  multi_az               = true
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.security_group.this_security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["alert", "audit"]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  publicly_accessible  = false
  # See here for support character sets https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.OracleCharacterSets.html
  character_set_name = "AL32UTF8"

  tags = local.tags
}
