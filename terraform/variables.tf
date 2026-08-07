variable "github_access_token" {
  description = "GitHub personal access token used by Amplify to pull cheapredwine/aws-cf-cdn"
  type        = string
  sensitive   = true
}

variable "multicdn_demo_secret" {
  description = "Value of the X-Multicdn-Demo-Secret header sent from CloudFront to the R2 origin"
  type        = string
  sensitive   = true
}

variable "cloudflare_verify_token" {
  description = "Cloudflare domain ownership verification token for sherron-cloud.com (TXT record value)"
  type        = string
  sensitive   = true
}
