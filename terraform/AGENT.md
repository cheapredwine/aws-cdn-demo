# Agent Instructions — AWS CDN Demo Terraform

This document tells an AI agent how to operate this Terraform configuration.
Read it fully before running any commands.

---

## What you are managing

AWS infrastructure for a CDN demo in account `512629184821`. Resources span
two regions (us-west-2 and us-east-1). The goal is either to tear resources
down (save money) or stand them back up (restore service).

---

## Two modes — choose before doing anything

### Partial (default — recommended)

Destroys and recreates only the resources that cost money: **WAF and Amplify**.
Leaves CloudFront, ACM, and Route53 running (they are effectively free idle).

- Standup requires one manual step: updating Cloudflare origin configuration
- Takes ~3 minutes each way
- Saves the bulk of the cost

### Full

Destroys and recreates everything including CloudFront, ACM, and Route53.
Only use this if the user explicitly asks to eliminate all infrastructure.

- Standup requires manual steps in Cloudflare and possibly at the DNS registrar
- Route53 nameservers may change, causing up to 48h of DNS downtime
- Use the partial mode unless there is a specific reason not to

**If the user hasn't specified, ask.** Default to partial.

---

## Before running anything

### 1. Check for credentials

Check whether `terraform/terraform.tfvars` already exists and has all fields:

```bash
cat terraform/terraform.tfvars 2>/dev/null
```

Required fields:
- `github_access_token` — GitHub PAT with `repo` scope
- `multicdn_demo_secret` — CloudFront-to-R2 origin secret header value
- `cloudflare_verify_token` — Cloudflare domain ownership TXT value

**CRITICAL**: Do NOT add `aws_access_key_id` or `aws_secret_access_key` to this file.
AWS credentials must only be set via environment variables.

If the file is missing or incomplete, ask the user for the values from
1Password ("AWS CDN Demo — Terraform secrets"), then write the file:

```bash
cat > terraform/terraform.tfvars <<EOF
github_access_token     = "<value>"
multicdn_demo_secret    = "<value>"
cloudflare_verify_token = "<value>"
EOF
```

Never print these values back into the conversation.

### 2. Set AWS credentials

Also from 1Password ("AWS CDN Demo — Terraform secrets"):

```bash
export AWS_ACCESS_KEY_ID=<value>
export AWS_SECRET_ACCESS_KEY=<value>
export AWS_DEFAULT_REGION=us-west-2
```

Verify before proceeding:

```bash
aws sts get-caller-identity
```

Expected: account `512629184821`. Stop if this fails.

### 3. Install dependencies if needed

```bash
terraform version 2>/dev/null || {
  curl -fsSL https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip \
    -o /tmp/tf.zip && unzip /tmp/tf.zip -d /usr/local/bin/ && rm /tmp/tf.zip
}
aws --version 2>/dev/null || pip install awscli -q
```

### 4. Initialize Terraform

```bash
cd terraform && terraform init
```

---

## Partial teardown (default)

```bash
cd terraform
./scripts/teardown-partial.sh
```

The script will show a plan and ask for confirmation before destroying anything.
It destroys: WAF ACL, WAF IP sets, Amplify app, branch, and domain association.
It does NOT touch: CloudFront, ACM cert, Route53.

When complete, the site is dark but standup will be fast and fully automated.

---

## Partial standup (default)

```bash
cd terraform
./scripts/standup-partial.sh
```

The script will:
1. Recreate WAF IP sets, WAF ACL, Amplify app, branch, and domain association
2. Automatically re-attach the WAF ACL to the Amplify app
3. Trigger an Amplify deployment to redeploy the site

### Manual step required after partial standup

**Cloudflare origin update** (CRITICAL — site will fail without this):

When Amplify is recreated, its CloudFront distribution domain changes. You must
update the Cloudflare origin configuration:

1. Get the new Amplify CloudFront domain:
   ```bash
   cd terraform && terraform output -raw amplify_default_domain
   ```
   
2. In the Cloudflare dashboard for `sherron-cloud.com`:
   - Navigate to DNS → Origin settings
   - Update the origin to point to the new CloudFront domain
   - Example: `dyswkzz22dlcy.cloudfront.net`

3. Without this step, images and CSS will fail with Error 1016 (Origin DNS Error)

When the script exits, monitor the Amplify build at the URL it prints.
The site is live once the build succeeds AND Cloudflare origin is updated (~2-3 minutes).

---

## Full teardown

Only run this if the user explicitly asks to destroy everything.

```bash
cd terraform
./scripts/teardown-full.sh
```

The confirmation prompt requires typing `destroy everything` (not just `yes`)
to prevent accidents.

---

## Full standup

Run after a full teardown. The script handles Terraform and WAF re-association
automatically, then prints the remaining manual steps.

```bash
cd terraform
./scripts/standup-full.sh
```

### Manual steps after full standup

The script will print the exact values needed. Work through these in order:

**1. Cloudflare origin update** (CRITICAL — site will fail without this):

When Amplify is recreated, its CloudFront distribution domain changes. You must
update the Cloudflare origin configuration:

1. Get the new Amplify CloudFront domain:
   ```bash
   cd terraform && terraform output -raw amplify_default_domain
   ```
   
2. In the Cloudflare dashboard for `sherron-cloud.com`:
   - Navigate to DNS → Origin settings
   - Update the origin to point to the new CloudFront domain
   - Example: `dyswkzz22dlcy.cloudfront.net`

3. Without this step, images and CSS will fail with Error 1016 (Origin DNS Error)

**2. ACM certificate validation**
Add the CNAME printed by the script to Cloudflare (`demo.jsherron.com` zone).
Poll until the cert is issued before telling the user standup is complete:

```bash
watch -n 15 aws acm describe-certificate --region us-east-1 \
  --certificate-arn $(cd terraform && terraform output -raw acm_certificate_arn) \
  --query 'Certificate.Status'
```

**3. Cloudflare DNS**
Add or update the CNAME printed by the script in Cloudflare (`demo.jsherron.com` zone):
```
cloudfront-pool  CNAME  <cloudfront_pool_domain output>
```
Ask the user to confirm when done — you cannot verify this automatically.

**4. Route53 nameservers**
Compare the nameservers in the output to what's at the registrar.
If they differ, tell the user to update them at:
AWS Console → Route53 → Registered domains → sherron-cloud.com → Name servers.
Warn that propagation takes up to 48h.

---

## Import (first-time only)

If resources exist in AWS but Terraform has no state:

```bash
cd terraform
terraform init
terraform plan   # should show imports only, no destructive changes
terraform apply
```

After a clean import, `terraform plan` should show no changes. If it shows
unexpected changes, stop and review with the user.

---

## Plan only

```bash
cd terraform && terraform plan
```

Summarize for the user: resources to add, change, or destroy. Do not apply.

---

## Safety rules

- Never run a destroy script without the user confirming the mode (partial vs full)
- Never commit `terraform.tfvars`
- Never print sensitive variable values into the conversation
- If plan output shows unexpected destructions, stop and ask before proceeding
- Partial mode is always the right default — confirm explicitly before running full

---

## Troubleshooting

**`No valid credential sources found`**
→ Export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` and retry.

**`Error acquiring the state lock`**
→ A previous run crashed. Release the lock if safe:
`terraform force-unlock <lock-id>`

**Amplify WAF status is not `ASSOCIATION_SUCCESS`**
→ Wait 30 seconds and re-run the `update-app` command. If it keeps failing,
check that the WAF ACL ARN is correct and in `us-east-1` scope CLOUDFRONT.

**ACM cert stuck in `PENDING_VALIDATION`**
→ The Cloudflare CNAME hasn't propagated yet. Wait a few minutes and recheck.

**Amplify build fails after standup**
→ Check the build log in the Amplify console. A domain verification failure
is expected if the domain association hasn't completed yet — retry the build
after a few minutes.

**`terraform apply` wants to recreate CloudFront distribution**
→ Expected after a full teardown/standup if the ACM cert ARN changed.
The distribution will be briefly unavailable during replacement (~15 minutes).
