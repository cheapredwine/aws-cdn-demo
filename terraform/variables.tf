variable "github_access_token" {
  description = "GitHub personal access token used by Amplify to pull cheapredwine/personal-website"
  type        = string
  sensitive   = true
}

variable "multicdn_demo_secret" {
  description = "Value of the X-Multicdn-Demo-Secret header sent from CloudFront to the R2 origin"
  type        = string
  sensitive   = true
  default     = "REDACTED_MULTICDN_SECRET="
}
