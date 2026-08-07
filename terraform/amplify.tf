resource "aws_amplify_app" "cf_cdn_aws_amplify" {
  name       = "aws-cf-cdn"
  repository = "https://github.com/cheapredwine/aws-cf-cdn"
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
        baseDirectory: src
        files:
          - '**/*'
      cache:
        paths: []
  EOT

  cache_config {
    type = "AMPLIFY_MANAGED_NO_COOKIES"
  }

  # NOTE: WAF association must be managed via AWS CLI, not supported in Terraform
  # aws_amplify_app resource as of AWS provider 5.x. Standup scripts handle this
  # automatically via:
  #   aws amplify update-app --app-id <id> \
  #     --waf-configuration webAclArn=<waf_acl_arn>
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.cf_cdn_aws_amplify.id
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
  app_id      = aws_amplify_app.cf_cdn_aws_amplify.id
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
