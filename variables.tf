variable "aws_account_id" {
  description = "The AWS Account ID"
  type        = string
}

variable "github_username" {
  description = "The name of the GitHub user or organization that owns the repository(ies) the role will use"
  type        = string
}

variable "repository_names" {
  description = "List of names of the GitHub repository that will be allowed to assume the role"
  type        = list(string)
}

variable "role_name" {
  description = "The name of the IAM Role to be created"
  type        = string
  default     = "GithubActionsRole"
}

variable "github_owner_id" {
  description = "The GitHub owner ID associated with the repository."
  type        = string
  default     = null
}

variable "github_repository_ids" {
  description = "Map of GitHub repository names to their immutable repository IDs"
  type        = map(string)
  default     = {}
}
