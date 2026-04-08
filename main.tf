terraform {
  required_providers {
    github = {
      source = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = "Practical-DevOps-GitHub"
}

variable "github_token" {
  description = "PAT"
  type = string
  sensitive = true
}
locals {
  repo_name = "github-terraform-task-harturicko-1"
}
data "github_repository" "repo" {
  full_name = "Practical-DevOps-GitHub/${local.repo_name}"
}

resource "github_repository_collaborator" "repo_collaborator" {
  repository = local.repo_name
  username = "softservedata"
  permission = "admin"
}

resource "github_branch" "develop" {
  repository = local.repo_name
  branch     = "develop"
}

resource "github_branch_default" "default" {
  repository = local.repo_name
  branch = github_branch.develop.branch
}

resource "github_branch_protection" "main" {
  repository_id = data.github_repository.repo.node_id

  pattern = "main"

  required_pull_request_reviews {
    required_approving_review_count = 0
    require_code_owner_reviews = true
  }
}

resource "github_branch_protection" "develop" {
  repository_id = data.github_repository.repo.node_id

  pattern = "develop"

  required_pull_request_reviews{
    required_approving_review_count = 2
    require_code_owner_reviews = true
  }
}

resource "github_repository_file" "codeowners_main" {
  repository = local.repo_name
  branch = "main"
  file = ".github/CODEOWNERS"
  content = "* @softservedata"
  overwrite_on_create = true
}

resource "github_repository_file" "pr_template" {
  repository          = local.repo_name
  branch              = "main"
  file                = ".github/pull_request_template.md"
  overwrite_on_create = true
  content             = <<-EOT
## Describe your changes

## Issue ticket number and link

## Checklist before requesting a review
- [ ] I have performed a self-review of my code
- [ ] If it is a core feature, I have added thorough tests
- [ ] Do we need to implement analytics?
- [ ] Will this be part of a product update? If yes, please write one phrase about this update
  EOT
}

variable "deploy_key_public" {
  description = "deploy key"
  type = string
}

resource "github_repository_deploy_key" "deploy_key" {
  repository = local.repo_name
  title = "DEPLOY_KEY"
  key = var.deploy_key_public
  read_only = true
}

resource "github_repository_webhook" "discord_webhook" {
  repository = local.repo_name

  configuration {
    url = "https://discord.com/api/webhooks/1485538333143597106/cfemQPshXwoEYB9PiDs1F4Rhp5lwA8M0mck_yPOQHGhd7ND_Gn0FZMvbisXTe0RgSq0l"
    content_type = "application/json"
  }
  events = ["pull_request"]
}
resource "github_actions_secret" "terraform_secret" {
  repository = local.repo_name
  secret_name = "PAT"

  plaintext_value = file("${path.module}/main.tf")
}