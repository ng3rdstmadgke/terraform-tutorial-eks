region         = "ap-northeast-1"
# tfstateの保存先バケット
bucket         = "terraform-tutorial-eks-tfstate"
# tfstateのロック情報を管理するDynamoDB
dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
# tfstateの暗号化
encrypt = true
