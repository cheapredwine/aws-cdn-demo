# TODO

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
