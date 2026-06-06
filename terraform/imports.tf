# Import blocks for bootstrapping Terraform state from existing AWS resources.
# Run once with: terraform plan (to preview) then terraform apply
# After a successful import these blocks can be removed, or left in place safely.

import {
  to = aws_wafv2_ip_set.cloudflare_ipv4
  id = "cloudflare_ipv4/6a21fa1a-6282-48d5-86f6-8a0f89e034d0/CLOUDFRONT"
}

import {
  to = aws_wafv2_ip_set.cloudflare_ipv6
  id = "cloudflare_ipv6/626d4ed6-dfbe-4ea6-8036-b459dd969826/CLOUDFRONT"
}

import {
  to = aws_wafv2_web_acl.allow_cloudflare
  id = "allow_cloudflare/f73d19fe-b9df-430b-af3c-218141410488/CLOUDFRONT"
}

import {
  to = aws_acm_certificate.cloudfront_pool
  id = "arn:aws:acm:us-east-1:512629184821:certificate/61445144-6bc4-4f98-96ac-950013484a1d"
}

import {
  to = aws_cloudfront_distribution.cloudfront_pool
  id = "E362FEEO2DM9NE"
}

import {
  to = aws_amplify_app.personal_website
  id = "dkipny3chz7d8"
}

import {
  to = aws_amplify_branch.main
  id = "dkipny3chz7d8/main"
}

import {
  to = aws_amplify_domain_association.sherron_cloud
  id = "dkipny3chz7d8/sherron-cloud.com"
}

import {
  to = aws_route53_zone.sherron_cloud
  id = "Z082027022QDAGZ0OMKJ7"
}

import {
  to = aws_route53_record.root_a
  id = "Z082027022QDAGZ0OMKJ7_sherron-cloud.com_A"
}

import {
  to = aws_route53_record.acm_validation
  id = "Z082027022QDAGZ0OMKJ7__80b2b3bba1f2353136322d5adf8a049a.sherron-cloud.com_CNAME"
}

import {
  to = aws_route53_record.cloudflare_verify
  id = "Z082027022QDAGZ0OMKJ7_cloudflare-verify.sherron-cloud.com_TXT"
}

import {
  to = aws_route53_record.images
  id = "Z082027022QDAGZ0OMKJ7_images.sherron-cloud.com_CNAME"
}

import {
  to = aws_route53_record.www
  id = "Z082027022QDAGZ0OMKJ7_www.sherron-cloud.com_CNAME"
}
