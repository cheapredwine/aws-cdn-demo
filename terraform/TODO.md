# TODO

## Manual steps required after PARTIAL teardown (Amplify destroyed)

When Amplify is destroyed and recreated (partial or full teardown), the CloudFront distribution domain changes. **CRITICAL**: Update Cloudflare origin configuration.

- **Cloudflare Origin for sherron-cloud.com**: Update origin to new Amplify CloudFront domain
  - Get new domain: `terraform output amplify_default_domain` (e.g., `d2spmcz01vlrw1.amplifyapp.com`)
  - Or use CloudFront domain from Amplify subdomain: `dyswkzz22dlcy.cloudfront.net`
  - Update Cloudflare dashboard: DNS → sherron-cloud.com → Origin settings
  - Without this update, images/CSS will fail with Error 1016

## Manual steps required after FULL teardown only

These steps are only needed after running `./scripts/teardown-full.sh`.

- **Cloudflare DNS**: Add/restore CNAME for `cloudfront-pool.demo.jsherron.com`
  pointing to the value in `output.cloudfront_pool_domain`
- **Nameservers**: If the Route53 hosted zone was destroyed and recreated,
  update nameservers at the Route53 Registrar to match `output.route53_nameservers`
- **ACM validation**: If the ACM cert for cloudfront-pool.demo.jsherron.com
  was recreated, add the new DNS validation CNAME to Cloudflare (demo.jsherron.com zone)

## Automated by standup scripts

- ✅ Amplify WAF attachment (via `aws wafv2 associate-web-acl`)
- ✅ Amplify deployment trigger (via `aws amplify start-job`)
- ✅ Route53 root A record automatically updates to new Amplify CloudFront domain
