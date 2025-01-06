resource "aws_iam_role" "ebs_csi_controller_sa_role" {
  name = "${var.cluster_name}-EbsCsiControllerSaRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEksAuthToAssumeRoleForPodIdentity",
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
  ])
  role = aws_iam_role.ebs_csi_controller_sa_role.name
  policy_arn = each.key
}

resource "aws_iam_policy" "ebs_csi_driver_encrypt_volume_policy" {
  name = "${var.cluster_name}-EbsCsiDriverEncryptVolumePolicy"
  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ],
          "Resource": ["*"],
          "Condition": {
            "Bool": {
              "kms:GrantIsForAWSResource": "true"
            }
          }
        },
        {
          "Effect": "Allow",
          "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource": ["*"]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_encrypt_volume_policy" {
  role = aws_iam_role.ebs_csi_controller_sa_role.name
  policy_arn = aws_iam_policy.ebs_csi_driver_encrypt_volume_policy.arn
}