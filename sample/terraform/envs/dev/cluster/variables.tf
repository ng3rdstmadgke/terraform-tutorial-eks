// EKSのアクセスエントリに追加するIAMユーザまたはIAMロールのARN
variable access_entries {
  type = list(string)
  description = "arn:aws:iam::111111111111:user/xxxxxxxxxxxxxxxx, arn:aws:iam::111111111111:role/xxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

locals {
  app_name = "tte-mido"
  stage    = "dev"
  cluster_name = "${local.app_name}-${local.stage}"
}

data "terraform_remote_state" "network" {
  // https://developer.hashicorp.com/terraform/language/state/remote-state-data#argument-reference
  backend = "s3"

  config = {
    // https://developer.hashicorp.com/terraform/language/backend/s3
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/network/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
  }
}