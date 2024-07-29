module "github_actions_iam_role" {
  source           = "../../"
  aws_account_id   = var.aws_account_id
  github_username  = var.github_username
  repository_names = var.repository_names
  role_name        = var.role_name
}
