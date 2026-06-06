# AWS CDN Demo — Terraform

Manages the AWS infrastructure for the CDN demo. Use this to tear everything
down to save money and stand it back up when needed.

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- AWS credentials with admin (or sufficiently broad) IAM permissions
- A GitHub personal access token with `repo` scope (for the Amplify app)

Set credentials in your shell:

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=us-west-2
```

---

## First-time setup (import existing state)

If resources already exist in AWS and you need to bring them under Terraform
management, run the import once:

```bash
cd terraform
terraform init
TF_VAR_github_access_token=<token> terraform plan   # preview — should show imports, no changes
TF_VAR_github_access_token=<token> terraform apply  # import into state
```

After a clean import the plan should show **no changes**. You can then remove
`imports.tf` or leave it in place (it's safe to keep).

---

## Tear down

Destroys all managed resources. DNS will stop resolving, the site goes dark.

```bash
cd terraform
TF_VAR_github_access_token=<token> terraform destroy
```

Terraform will print a list of everything it will delete and ask for
confirmation before touching anything.

> **Warning — Route53 nameservers**: If you destroy the hosted zone, AWS will
> assign different nameservers when you recreate it. You'll need to update the
> nameservers at your domain registrar (Route53 Registrar) before DNS works
> again. The new values are printed in `output.route53_nameservers` after
> standup.

---

## Stand back up

Recreates everything from scratch.

```bash
cd terraform
TF_VAR_github_access_token=<token> terraform apply
```

### Manual steps required after standup

These can't be automated via Terraform — do them after `apply` completes:

1. **ACM certificate validation**
   The cert for `cloudfront-pool.demo.jsherron.com` needs a DNS validation
   CNAME added in Cloudflare (the `demo.jsherron.com` zone). Get the record:
   ```bash
   terraform output acm_certificate_arn
   aws acm describe-certificate --region us-east-1 \
     --certificate-arn <arn> \
     --query 'Certificate.DomainValidationOptions'
   ```
   Add the resulting CNAME in Cloudflare and wait for the cert to issue
   (usually a few minutes).

2. **Cloudflare DNS for cloudfront-pool**
   Add or update the CNAME in Cloudflare (`demo.jsherron.com` zone):
   ```
   cloudfront-pool  CNAME  <value of: terraform output cloudfront_pool_domain>
   ```

3. **Amplify WAF re-association**
   The WAF ACL can't be attached to Amplify via Terraform. Run:
   ```bash
   aws amplify update-app \
     --app-id $(terraform output -raw amplify_app_id) \
     --waf-configuration webAclArn=$(terraform output -raw waf_web_acl_arn)
   ```

4. **Route53 nameservers** (only if the hosted zone was destroyed and recreated)
   Check whether nameservers changed:
   ```bash
   terraform output route53_nameservers
   ```
   If they differ from what your registrar has, update them at
   Route53 Registrar → Registered domains → sherron-cloud.com → Name servers.
   Allow up to 48h for propagation.

---

## Check what will happen without making changes

```bash
terraform plan
```

---

## Resources managed

| Resource | Terraform file |
|---|---|
| Amplify app `personal-website` + `main` branch + `sherron-cloud.com` domain | `amplify.tf` |
| CloudFront distribution `cloudfront-pool.demo.jsherron.com` | `cloudfront.tf` |
| WAFv2 Web ACL `allow_cloudflare` + IPv4/IPv6 IP sets | `waf.tf` |
| ACM certificate `cloudfront-pool.demo.jsherron.com` | `acm.tf` |
| Route53 hosted zone `sherron-cloud.com` + records | `route53.tf` |

See `TODO.md` for resources not yet included.
