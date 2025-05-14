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
          "iam:GetRole",
          "iam:CreateRole",
          "iam:CreatePolicy",
          "iam:UpdateRole",
          "iam:DeleteRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicies",
          "iam:TagRole",
          "iam:TagPolicy",
          "route53:ListHostedZones",
          "route53:GetHostedZone",
          "route53:ListTagsForResource",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
          "acm:RequestCertificate",
          "acm:DescribeCertificate",
          "acm:DeleteCertificate",
          "acm:ListCertificates",
          "acm:AddTagsToCertificate",
          "acm:ListTagsForCertificate",
          "cognito-idp:CreateUserPool",
          "cognito-idp:DeleteUserPool",
          "cognito-idp:UpdateUserPool",
          "cognito-idp:DescribeUserPool",
          "cognito-idp:CreateUserPoolClient",
          "cognito-idp:UpdateUserPoolClient",
          "cognito-idp:DescribeUserPoolClient",
          "cognito-idp:DeleteUserPoolClient",
          "cognito-idp:CreateUserPoolDomain",
          "cognito-idp:DescribeUserPoolDomain",
          "cognito-idp:DeleteUserPoolDomain",
          "cognito-idp:CreateIdentityProvider",
          "cognito-idp:UpdateIdentityProvider",
          "cognito-idp:DescribeIdentityProvider",
          "cognito-idp:DeleteIdentityProvider",
          "cognito-idp:SetUserPoolMfaConfig",
          "cognito-idp:GetUserPoolMfaConfig",
          "cloudformation:CreateStack",
          "cloudformation:CreateStack",
          "cloudformation:UpdateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:DescribeStackEvents",
          "cloudformation:GetTemplate",
          "cloudformation:ListStackResources",
          "cloudformation:ListStacks",
          "cloudformation:ValidateTemplate",
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource",
          "logs:ListTagsForResource",
          "logs:CreateLogDelivery",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DeleteResourcePolicy",
          "logs:ListLogDeliveries",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "apigateway:POST",
          "apigateway:GET",
          "apigateway:DELETE",
          "apigateway:PATCH",
          "apigateway:PUT",
          "appconfig:CreateApplication",
          "appconfig:CreateEnvironment",
          "appconfig:CreateConfigurationProfile",
          "appconfig:CreateHostedConfigurationVersion",
          "appconfig:CreateDeploymentStrategy",
          "appconfig:DeleteApplication",
          "appconfig:DeleteDeploymentStrategy",
          "appconfig:StartDeployment",
          "appconfig:GetApplication",
          "appconfig:GetEnvironment",
          "appconfig:GetConfigurationProfile",
          "appconfig:GetHostedConfigurationVersion",
          "appconfig:GetDeploymentStrategy",
          "appconfig:GetDeployment",
          "appconfig:ListApplications",
          "appconfig:ListEnvironments",
          "appconfig:ListConfigurationProfiles",
          "appconfig:ListHostedConfigurationVersions",
          "appconfig:ListDeploymentStrategies",
          "appconfig:ListDeployments",
          "appconfig:ListTagsForResource",
          "appconfig:TagResource",
          "appconfig:UntagResource",
          "iot:DescribeEndpoint",
          "iot:UpdateCertificate",
          "iot:DeleteCertificate",
          "iot:DescribeCertificate",
          "iot:CreateThing",
          "iot:UpdateThing",
          "iot:DeleteThing",
          "iot:DescribeThing",
          "iot:GetPolicy",
          "iot:CreatePolicy",
          "iot:DeletePolicy",
          "iot:AttachPolicy",
          "iot:DetachPolicy",
          "iot:CreateRoleAlias",
          "iot:DeleteRoleAlias",
          "iot:DescribeRoleAlias",
          "iot:CreateKeysAndCertificate",
          "iot:AttachThingPrincipal",
          "iot:ListThingPrincipals",
          "iot:DetachThingPrincipal",
          "iot:ListPolicyVersions",
          "iot:ListAttachedPolicies",
          "iot:TagResource",
          "iot:ListTagsForResource",
          "sqs:CreateQueue",
          "sqs:DeleteQueue",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:SetQueueAttributes",
          "sqs:ListQueues",
          "sqs:listqueuetags",
          "sqs:TagQueue",
          "sqs:UntagQueue"
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

