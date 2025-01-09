variable cluster_name {
  type = string
  description = "EKSクラスタ名"
}
variable subnet_ids {
  type = list(string)
  description = "EKSクラスタを作成するサブネットID"
}
variable access_entries {
  type = list(string)
  description = "EKSのIAMアクセスエントリに登録するIAMユーザまたはIAMロールのARN"
}

data "aws_caller_identity" "self" { }

locals {
  account_id = data.aws_caller_identity.self.account_id
}