# TODO

## cheapredwine S3 bucket
- Bucket exists in us-east-1, is empty, has no website config or bucket policy
- Decide whether to include in teardown/standup or delete permanently
- Add `aws_s3_bucket` resource and import if keeping

## Orphaned CloudFront distribution E3BRD56Y886ZV5
- Origin: jungledisk-s3.s3.amazonaws.com (bucket no longer exists)
- Origin Access Identity E36E2SR9XLZ98 also orphaned
- WAF (allow_cloudflare) is attached to this distribution
- Options:
  a) Delete the distribution and OAI outright (AWS console or CLI)
  b) Restore with a new S3 bucket and add to Terraform
- Once decided, add `aws_cloudfront_distribution` + `aws_cloudfront_origin_access_identity`
  resources and import or apply accordingly

## Manual steps required after standup (not automatable via Terraform)
- **Cloudflare DNS**: Add/restore CNAME for `cloudfront-pool.demo.jsherron.com`
  pointing to the value in `output.cloudfront_pool_domain`
- **Amplify WAF**: Re-attach the allow_cloudflare WAF ACL to the Amplify app.
  Use the ARN from `output.waf_web_acl_arn`:
    aws amplify update-app --app-id <id> \
      --waf-configuration webAclArn=<waf_web_acl_arn>
- **Nameservers**: If the Route53 hosted zone was destroyed and recreated,
  update nameservers at the Route53 Registrar to match `output.route53_nameservers`
- **ACM validation**: If the ACM cert for cloudfront-pool.demo.jsherron.com
  was recreated, add the new DNS validation CNAME to Cloudflare (demo.jsherron.com zone)
