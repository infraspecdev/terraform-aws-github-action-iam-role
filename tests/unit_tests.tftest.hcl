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

run "legacy_subject_format_when_ids_not_provided" {
  command = plan

  assert {
    condition = contains(
      jsondecode(data.aws_iam_policy_document.assume_role.json).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"],
      "repo:acme-org/service-a:*"
    )

    error_message = "Legacy OIDC subject for service-a is missing"
  }

  assert {
    condition = contains(
      jsondecode(data.aws_iam_policy_document.assume_role.json).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"],
      "repo:acme-org/service-b:*"
    )

    error_message = "Legacy OIDC subject for service-b is missing"
  }

  assert {
    condition = length(
      jsondecode(data.aws_iam_policy_document.assume_role.json).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"]
    ) == 2

    error_message = "Expected only legacy subjects when github_owner_id/github_repository_ids are not provided"
  }
}

run "both_subject_formats_when_ids_are_provided" {
  command = plan

  variables {
    github_owner_id = "111222333"

    github_repository_ids = {
      service-a = "444555666"
      service-b = "777888999"
    }
  }

  assert {
    condition = contains(
      jsondecode(data.aws_iam_policy_document.assume_role.json).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"],
      "repo:acme-org/service-a:*"
    )

    error_message = "Legacy OIDC subject for service-a is missing"
  }

  assert {
    condition = contains(
      jsondecode(data.aws_iam_policy_document.assume_role.json).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"],
      "repo:acme-org/service-b:*"
    )

    error_message = "Legacy OIDC subject for service-b is missing"
  }

  assert {
    condition = contains(
      jsondecode(data.aws_iam_policy_document.assume_role.json).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"],
      "repo:acme-org@111222333/service-a@444555666:*"
    )

    error_message = "Immutable OIDC subject for service-a should use its own ID (444555666)"
  }

  assert {
    condition = contains(
      jsondecode(data.aws_iam_policy_document.assume_role.json).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"],
      "repo:acme-org@111222333/service-b@777888999:*"
    )

    error_message = "Immutable OIDC subject for service-b should use its own ID (777888999), not service-a's"
  }

  assert {
    condition = length(
      jsondecode(data.aws_iam_policy_document.assume_role.json).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"]
    ) == 4

    error_message = "Expected one legacy and one immutable subject for each repository"
  }
}

run "repo_missing_from_ids_map_is_skipped_gracefully" {
  command = plan

  variables {
    github_owner_id = "111222333"

    github_repository_ids = {
      service-a = "444555666"
      # service-b intentionally omitted
    }
  }

  assert {
    condition = contains(
      jsondecode(data.aws_iam_policy_document.assume_role.json).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"],
      "repo:acme-org@111222333/service-a@444555666:*"
    )

    error_message = "Immutable OIDC subject for service-a is missing"
  }

  assert {
    condition = length(
      jsondecode(data.aws_iam_policy_document.assume_role.json).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"]
    ) == 3

    error_message = "Expected 2 legacy refs + 1 immutable ref (service-b skipped since it has no ID in the map)"
  }
}
