locals {
  github_repository = "KennyH/mine-bitcoin-online"
  branches = {
    dev  = "main"
    prod = "prod"
  }
}

resource "aws_iam_role" "github_actions" {
  for_each = local.branches

  name = "mine-bitcoin-online-github-actions-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github_oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${local.github_repository}:ref:refs/heads/${each.value}"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "github_actions_policy" {
  name = "mine-bitcoin-online-github-actions-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:*",
          "lambda:*",
          "cloudwatch:*",
          "cloudfront:*",
          "s3:*",
          "dynamodb:*",
          "kms:*",
          "iam:*" #TODO reduce this!
          # Add more later
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  for_each = local.branches

  role       = aws_iam_role.github_actions[each.key].name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}

