locals {
  app_name = "tutorial-mido"
  stage    = "dev"
  cluster_name = "${local.app_name}-${local.stage}"
  vpc_cidr = "10.60.0.0/16"
  private_subnets = [
    "10.60.1.0/24",
    "10.60.2.0/24",
    "10.60.3.0/24",
  ]
  public_subnets = [
    "10.60.101.0/24",
    "10.60.102.0/24",
    "10.60.103.0/24",
  ]
}

variable access_entries {
  type = list(string)
}
