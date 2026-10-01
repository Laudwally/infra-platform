locals {
  name = "infra-platform-dev"
  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "infra-platform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = local.name
  cidr_block           = "10.10.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]
  single_nat_gateway   = true
  tags                 = local.tags
}

module "eks" {
  source = "../../modules/eks"

  name                = local.name
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  node_instance_types = ["t3.medium"]
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 3
  tags                = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name                       = "${local.name}-db"
  db_name                    = "app"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  instance_class             = "db.t4g.micro"
  multi_az                   = false
  deletion_protection        = false
  tags                       = local.tags
}

module "cost_dashboard" {
  source = "../../modules/cost-dashboard"

  name                     = local.name
  monthly_budget_limit_usd = 300
  alert_emails             = var.budget_alert_emails
  tags                     = local.tags
}
