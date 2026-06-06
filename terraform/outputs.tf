output "amplify_app_id" {
  value = aws_amplify_app.personal_website.id
}

output "amplify_default_domain" {
  value = aws_amplify_app.personal_website.default_domain
}

output "cloudfront_pool_domain" {
  description = "Update the cloudfront-pool.demo.jsherron.com CNAME in Cloudflare to this value after standup"
  value       = aws_cloudfront_distribution.cloudfront_pool.domain_name
}

output "cloudfront_pool_distribution_id" {
  value = aws_cloudfront_distribution.cloudfront_pool.id
}

output "waf_web_acl_arn" {
  description = "Re-attach this ARN to the Amplify app WAF config after standup"
  value       = aws_wafv2_web_acl.allow_cloudflare.arn
}

output "route53_zone_id" {
  value = aws_route53_zone.sherron_cloud.zone_id
}

output "route53_nameservers" {
  description = "If nameservers changed after teardown/standup, update these at the Route53 Registrar"
  value       = aws_route53_zone.sherron_cloud.name_servers
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.cloudfront_pool.arn
}
