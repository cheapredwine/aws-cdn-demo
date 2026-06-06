resource "aws_amplify_app" "personal_website" {
  name       = "personal-website"
  repository = "https://github.com/cheapredwine/personal-website"
  platform   = "WEB"

  # GitHub token is required on create/update but not tracked in state after import.
  # Provide via: TF_VAR_github_access_token=<token> terraform apply
  access_token = var.github_access_token

  enable_branch_auto_build    = false
  enable_branch_auto_deletion = false
  enable_basic_auth           = false

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands: []
        build:
          commands: []
      artifacts:
        baseDirectory: /
        files:
          - '**/*'
      cache:
        paths: []
  EOT

  cache_config {
    type = "AMPLIFY_MANAGED_NO_COOKIES"
  }

  # NOTE: WAF association (allow_cloudflare web ACL) is not yet supported as a
  # first-class Terraform attribute on aws_amplify_app. After standup, re-attach
  # the WAF ACL via the AWS console or CLI:
  #   aws amplify update-app --app-id <id> \
  #     --waf-configuration webAclArn=<waf_acl_arn>
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.personal_website.id
  branch_name = "main"
  stage       = "PRODUCTION"
  framework   = "Web"

  enable_auto_build          = true
  enable_notification        = false
  enable_basic_auth          = false
  enable_pull_request_preview = false
  enable_performance_mode    = false
  ttl                        = "5"
}

resource "aws_amplify_domain_association" "sherron_cloud" {
  app_id      = aws_amplify_app.personal_website.id
  domain_name = "sherron-cloud.com"

  enable_auto_sub_domain = false

  # Wildcard / root
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = ""
  }

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "www"
  }

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "images"
  }

  certificate_settings {
    type = "AMPLIFY_MANAGED"
  }
}
