# WARNING ON TEARDOWN: Destroying the hosted zone and recreating it will assign
# new nameservers. You must update the nameservers at your domain registrar
# (Route53 Registrar) to match the new NS record before DNS will resolve again.
# Allow up to 48h for propagation.

resource "aws_route53_zone" "sherron_cloud" {
  name    = "sherron-cloud.com"
  comment = "HostedZone created by Route53 Registrar"
}

locals {
  # Parse Amplify's internal CloudFront domain from domain association
  # Find root subdomain (prefix == null or empty), dns_record format: "* CNAME d2wdz403fe8z37.cloudfront.net"
  # Extract the CloudFront domain (3rd space-separated token)
  amplify_root_subdomain = [
    for s in aws_amplify_domain_association.sherron_cloud.sub_domain : s if try(s.prefix, "") == ""
  ][0]
  amplify_cloudfront_domain = split(" ", local.amplify_root_subdomain.dns_record)[2]
}

# Root apex → Amplify (Amplify manages this CloudFront distribution internally)
resource "aws_route53_record" "root_a" {
  zone_id = aws_route53_zone.sherron_cloud.zone_id
  name    = "sherron-cloud.com"
  type    = "A"

  alias {
    name                   = local.amplify_cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID (constant)
    evaluate_target_health = false
  }
}

# Cloudflare domain ownership verification
resource "aws_route53_record" "cloudflare_verify" {
  zone_id = aws_route53_zone.sherron_cloud.zone_id
  name    = "cloudflare-verify.sherron-cloud.com"
  type    = "TXT"
  ttl     = 300
  records = [var.cloudflare_verify_token]
}

# images.sherron-cloud.com → Cloudflare CDN
resource "aws_route53_record" "images" {
  zone_id = aws_route53_zone.sherron_cloud.zone_id
  name    = "images.sherron-cloud.com"
  type    = "CNAME"
  ttl     = 60
  records = ["images.sherron-cloud.com.cdn.cloudflare.net"]
}

# www.sherron-cloud.com → Cloudflare CDN
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.sherron_cloud.zone_id
  name    = "www.sherron-cloud.com"
  type    = "CNAME"
  ttl     = 60
  records = ["www.sherron-cloud.com.cdn.cloudflare.net"]
}
