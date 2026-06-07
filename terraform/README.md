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

**Important**: Do NOT add `aws_access_key_id` or `aws_secret_access_key` to `terraform.tfvars`. AWS credentials should only be set via environment variables or AWS CLI configuration.

### Setting AWS credentials in your shell

```bash
export AWS_ACCESS_KEY_ID=...        # from 1Password or AWS CLI
export AWS_SECRET_ACCESS_KEY=...    # from 1Password or AWS CLI  
export AWS_DEFAULT_REGION=us-west-2
```

Or use AWS CLI profiles configured via AWS Toolkit.

---

## First-time setup

If starting fresh or after cloning the repo:

```bash
cd terraform
terraform init
terraform plan   # should show "No changes" if state already imported
```

Note: `imports.tf` was used for initial state import and has been removed after successful import.

---

## Tear down

Two modes — **partial is recommended** for routine cost saving.

### Partial (recommended)

Destroys only WAF and Amplify (the resources that cost money). Leaves
CloudFront, ACM, and Route53 running. Standup is fully automated with no
manual DNS steps.

```bash
cd terraform
./scripts/teardown-partial.sh
```

### Full

Destroys everything. Use only if you want to completely eliminate the
infrastructure. Standup will require manual Cloudflare and possibly registrar
steps, and Route53 nameservers may change.

```bash
cd terraform
./scripts/teardown-full.sh
```

---

## Stand back up

### Partial (after a partial teardown)

```bash
cd terraform
./scripts/standup-partial.sh
```

**Important**: After standup completes, you must update Cloudflare origin configuration:
1. Get new Amplify CloudFront domain: `terraform output -raw amplify_default_domain`
2. In Cloudflare dashboard, update origin for `sherron-cloud.com` subdomains to point to the new domain
3. Without this step, images and CSS will fail to load (Error 1016)

### Full (after a full teardown)

```bash
cd terraform
./scripts/standup-full.sh
```

The script prints the manual Cloudflare DNS and nameserver steps required
after it completes.

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
