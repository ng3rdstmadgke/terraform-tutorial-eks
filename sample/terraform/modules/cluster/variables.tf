variable app_name {}
variable stage {}
variable subnet_ids {
  type = list(string)
}
variable access_entries {
  type = list(string)
  description = "arn:aws:iam::111111111111:user/xxxxxxxxxxxxxxxx or arn:aws:iam::111111111111:role/xxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

data "aws_caller_identity" "self" { }
data "aws_region" "self" {}

locals {
  account_id = data.aws_caller_identity.self.account_id
  region = data.aws_region.self.name
  cluster_name = "${var.app_name}-${var.stage}"
}