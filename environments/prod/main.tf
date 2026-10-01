locals {
  name = "infra-platform-prod"
  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = "infra-platform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = local.name
  cidr_block           = "10.20.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]
  single_nat_gateway   = false
  tags                 = local.tags
}

module "eks" {
  source = "../../modules/eks"

  name                = local.name
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  node_instance_types = ["m6i.large"]
  node_desired_size   = 3
  node_min_size       = 3
  node_max_size       = 10
  tags                = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name                       = "${local.name}-db"
  db_name                    = "app"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  instance_class             = "db.r6g.large"
  multi_az                   = true
  deletion_protection        = true
  backup_retention_days      = 30
  tags                       = local.tags
}

module "cost_dashboard" {
  source = "../../modules/cost-dashboard"

  name                     = local.name
  monthly_budget_limit_usd = 3000
  alert_emails             = var.budget_alert_emails
  tags                     = local.tags
}
