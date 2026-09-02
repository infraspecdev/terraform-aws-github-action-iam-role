provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

variables {
  aws_account_id   = "123456789012"
  github_username  = "acme-org"
  repository_names = ["service-a", "service-b"]
}

# ---------------------------------------------------------------------------
# 1. Legacy format when GitHub IDs are not provided.
# ---------------------------------------------------------------------------
run "legacy_subject_format_when_ids_not_provided" {
  command = plan

  assert {
    condition = jsondecode(
      data.aws_iam_policy_document.assume_role.json
    ).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"] == [
      "repo:acme-org/service-a:*",
      "repo:acme-org/service-b:*",
    ]

    error_message = "Only legacy GitHub OIDC subjects should be generated when IDs are not provided"
  }
}

# ---------------------------------------------------------------------------
# 2. Legacy + immutable format when GitHub IDs are provided.
# ---------------------------------------------------------------------------
run "both_subject_formats_when_ids_are_provided" {
  command = plan

  variables {
    repository_names     = ["service-a"]
    github_owner_id      = "111222333"
    github_repository_id = "444555666"
  }

  assert {
    condition = jsondecode(
      data.aws_iam_policy_document.assume_role.json
    ).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"] == [
      "repo:acme-org/service-a:*",
      "repo:acme-org@111222333/service-a@444555666:*",
    ]

    error_message = "Both legacy and immutable GitHub OIDC subjects should be generated when IDs are provided"
  }
}