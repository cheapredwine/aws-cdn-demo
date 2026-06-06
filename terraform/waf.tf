# All WAFv2 global resources must be created in us-east-1

resource "aws_wafv2_ip_set" "cloudflare_ipv4" {
  provider = aws.us_east_1

  name               = "cloudflare_ipv4"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"

  # Source: https://www.cloudflare.com/ips-v4
  addresses = [
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "108.162.192.0/18",
    "131.0.72.0/22",
    "141.101.64.0/18",
    "162.158.0.0/15",
    "172.64.0.0/13",
    "173.245.48.0/20",
    "188.114.96.0/20",
    "190.93.240.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
  ]
}

resource "aws_wafv2_ip_set" "cloudflare_ipv6" {
  provider = aws.us_east_1

  name               = "cloudflare_ipv6"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV6"

  # Source: https://www.cloudflare.com/ips-v6
  addresses = [
    "2400:cb00::/32",
    "2405:8100::/32",
    "2405:b500::/32",
    "2606:4700::/32",
    "2803:f800::/32",
    "2a06:98c0::/29",
    "2c0f:f248::/32",
  ]
}

resource "aws_wafv2_web_acl" "allow_cloudflare" {
  provider = aws.us_east_1

  name  = "allow_cloudflare"
  scope = "CLOUDFRONT"

  # Block everything that isn't explicitly allowed below
  default_action {
    block {}
  }

  rule {
    name     = "allow_cloudflare_ipv4"
    priority = 0

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.cloudflare_ipv4.arn
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "allow_cloudflare_ipv4"
    }
  }

  rule {
    name     = "allow_cloudflare_ipv6"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.cloudflare_ipv6.arn
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "allow_cloudflare_ipv6"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "allow_cloudflare"
  }
}
