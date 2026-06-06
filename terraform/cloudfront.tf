resource "aws_cloudfront_distribution" "cloudfront_pool" {
  comment = "Multi-CDN demo CloudFront distribution"

  aliases = ["cloudfront-pool.demo.jsherron.com"]

  origin {
    origin_id   = "r2-origin"
    domain_name = "cf-pool.demo.jsherron.com"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 30
      origin_keepalive_timeout = 5
    }

    custom_header {
      name  = "X-Multicdn-Demo-Secret"
      value = var.multicdn_demo_secret
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"
  http_version    = "http2"

  default_cache_behavior {
    target_origin_id       = "r2-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # Managed-CachingOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    # Managed-ResponseHeadersPolicy (SecurityHeadersPolicy)
    response_headers_policy_id = "c9fc8768-3860-4ec0-b623-10848f3061f0"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront_pool.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # MANUAL STEP ON STANDUP: After apply, add a CNAME record in Cloudflare
  # for cloudfront-pool.demo.jsherron.com → dks8defodma2n.cloudfront.net
  # (or whatever the new distribution domain is — see outputs.tf)
}
