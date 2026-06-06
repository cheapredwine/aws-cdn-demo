# AWS CDN Demo — Terraform

Manages the AWS infrastructure for the CDN demo. Use this to tear everything
down to save money and stand it back up when needed.

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- AWS credentials for account `512629184821`
- A GitHub personal access token with `repo` scope (for the Amplify app)

---

## Secrets

All secrets are stored in 1Password under **"AWS CDN Demo — Terraform secrets"**.

| 1Password field | Used for |
|---|---|
| `aws_access_key_id` | AWS authentication |
| `aws_secret_access_key` | AWS authentication |
| `github_access_token` | Amplify pulls from `cheapredwine/personal-website` |
| `multicdn_demo_secret` | `X-Multicdn-Demo-Secret` header from CloudFront to R2 origin |
| `cloudflare_verify_token` | Cloudflare domain ownership TXT record for `sherron-cloud.com` |

### Setting up your local secrets file

Copy the example file and fill in values from 1Password:

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with values from 1Password
```

`terraform.tfvars` is gitignored and must never be committed.

### Setting AWS credentials in your shell

```bash
export AWS_ACCESS_KEY_ID=...        # from 1Password
export AWS_SECRET_ACCESS_KEY=...    # from 1Password
export AWS_DEFAULT_REGION=us-west-2
```

---

## First-time setup (import existing state)

If resources already exist in AWS and you need to bring them under Terraform
management, run the import once:

```bash
cd terraform
terraform init
terraform plan   # preview — should show imports, no changes
terraform apply  # import into state
```

After a clean import the plan should show **no changes**. You can then remove
`imports.tf` or leave it in place (it's safe to keep).

---

## Tear down

Destroys all managed resources. DNS will stop resolving, the site goes dark.

```bash
cd terraform
terraform destroy
```

Terraform will print a list of everything it will delete and ask for
confirmation before touching anything.

> **Warning — Route53 nameservers**: Destroying the hosted zone means AWS will
> assign different nameservers when you recreate it. You'll need to update them
> at the registrar before DNS works again. See step 4 in the standup section.

---

## Stand back up

Recreates everything from scratch.

```bash
cd terraform
terraform apply
```

### Manual steps required after standup

These can't be automated via Terraform — do them after `apply` completes:

1. **ACM certificate validation**
   The cert for `cloudfront-pool.demo.jsherron.com` needs a DNS validation
   CNAME added in Cloudflare (`demo.jsherron.com` zone). Get the record to add:
   ```bash
   aws acm describe-certificate --region us-east-1 \
     --certificate-arn $(terraform output -raw acm_certificate_arn) \
     --query 'Certificate.DomainValidationOptions'
   ```
   Add the resulting CNAME in Cloudflare and wait a few minutes for the cert to issue.

2. **Cloudflare DNS for cloudfront-pool**
   Add or update the CNAME in Cloudflare (`demo.jsherron.com` zone):
   ```
   cloudfront-pool  CNAME  <value of: terraform output cloudfront_pool_domain>
   ```

3. **Amplify WAF re-association**
   The WAF ACL can't be attached to Amplify via Terraform. Run after apply:
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
   If they differ from what the registrar has, update them at:
   AWS Console → Route53 → Registered domains → sherron-cloud.com → Name servers.
   Allow up to 48h for propagation.

---

## Check what will happen without making changes

```bash
cd terraform
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
| Route53 hosted zone `sherron-cloud.com` + all DNS records | `route53.tf` |

See `TODO.md` for resources not yet included.
