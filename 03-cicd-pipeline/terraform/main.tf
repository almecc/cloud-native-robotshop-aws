locals {
  repo      = "almecc/cloud-native-robotshop-aws"
  state_arn = "arn:aws:s3:::robotshop-tfstate-almecc"
}

# Tells AWS to trust GitHub as a login provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Only this repo, and only the main branch or pull requests, can use the role
data "aws_iam_policy_document" "github_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repo}:ref:refs/heads/main",
        "repo:${local.repo}:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "robotshop-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

# Can read everything, so terraform plan works. Cannot change anything.
resource "aws_iam_role_policy_attachment" "read_only" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Can read and write the Terraform state bucket (plan needs the lock file)
data "aws_iam_policy_document" "state_access" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [local.state_arn]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.state_arn}/*"]
  }
}

resource "aws_iam_role_policy" "state_access" {
  name   = "terraform-state-access"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.state_access.json
}
