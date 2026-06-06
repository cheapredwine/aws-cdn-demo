# Agent Instructions — AWS CDN Demo Terraform

This document tells an AI agent how to operate this Terraform configuration.
Read it fully before running any commands.

---

## What you are managing

AWS infrastructure for a CDN demo in account `512629184821`. Resources span
two regions (us-west-2 and us-east-1). The full list is in README.md. The
goal is either to **tear everything down** (save money) or **stand it back up**
(restore service).

---

## Before you do anything

### 1. Confirm the task

Ask the user whether the goal is:
- **Tear down** — destroy all resources
- **Stand up** — create/restore all resources
- **Import** — first-time only, pull existing AWS resources into Terraform state
- **Plan only** — show what would change without touching anything

Do not proceed until this is confirmed.

### 2. Check for credentials

You need five secrets. Check whether a `terraform.tfvars` file already exists:

```bash
cat terraform/terraform.tfvars 2>/dev/null
```

If it exists and has all five fields, you can proceed. If not, ask the user
to provide the values from 1Password ("AWS CDN Demo — Terraform secrets"):

- `github_access_token` — GitHub PAT with `repo` scope
- `multicdn_demo_secret` — CloudFront-to-R2 origin secret header value
- `cloudflare_verify_token` — Cloudflare domain ownership TXT record value
- `aws_access_key_id` — AWS key ID
- `aws_secret_access_key` — AWS secret

Once you have them, write `terraform/terraform.tfvars` (it is gitignored):

```bash
cat > terraform/terraform.tfvars <<EOF
github_access_token     = "<value>"
multicdn_demo_secret    = "<value>"
cloudflare_verify_token = "<value>"
EOF
```

And export the AWS credentials:

```bash
export AWS_ACCESS_KEY_ID=<value>
export AWS_SECRET_ACCESS_KEY=<value>
export AWS_DEFAULT_REGION=us-west-2
```

Verify AWS access before going further:

```bash
aws sts get-caller-identity
```

Expected: account `512629184821`, user `claude-discovery` (or similar).
If this fails, stop and ask the user to check their credentials.

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
cd terraform
terraform init
```

This must succeed before any other Terraform commands.

---

## Tear down

```bash
cd terraform
terraform destroy
```

Terraform will print a destruction plan and prompt `yes` to confirm.
Type `yes` only after reviewing the list with the user if there is any doubt.

**After destroy completes**, confirm with the user that the intent was full
teardown. Do not run any standup steps unless asked.

---

## Stand up (full restore)

Run apply:

```bash
cd terraform
terraform apply
```

Review the plan output. If it looks correct, approve with `yes`.

After `apply` completes, capture the outputs:

```bash
terraform output -json
```

Then work through the post-standup steps below **in order**. Each step depends
on the previous one completing successfully.

### Post-standup step 1 — ACM certificate validation

The cert for `cloudfront-pool.demo.jsherron.com` requires a DNS validation
CNAME to be added in Cloudflare (`demo.jsherron.com` zone). Retrieve the
required record:

```bash
aws acm describe-certificate --region us-east-1 \
  --certificate-arn $(terraform output -raw acm_certificate_arn) \
  --query 'Certificate.DomainValidationOptions[0].{Name:ResourceRecord.Name,Value:ResourceRecord.Value}'
```

Present the Name and Value to the user and tell them:
> Add this as a CNAME record in Cloudflare under the demo.jsherron.com zone,
> then let me know when it's done.

Wait for the user to confirm, then poll until the cert is issued (usually
2–5 minutes after the record is added):

```bash
watch -n 15 aws acm describe-certificate --region us-east-1 \
  --certificate-arn $(terraform output -raw acm_certificate_arn) \
  --query 'Certificate.Status'
```

Do not proceed to step 2 until status is `ISSUED`.

### Post-standup step 2 — Cloudflare DNS for cloudfront-pool

Tell the user:
> In Cloudflare, under the demo.jsherron.com zone, add or update:
>
>   cloudfront-pool  CNAME  <terraform output cloudfront_pool_domain>
>
> This routes cloudfront-pool.demo.jsherron.com to the new distribution.

Get the value to give them:

```bash
terraform output cloudfront_pool_domain
```

Wait for the user to confirm it's done. You cannot verify this automatically
unless you have DNS lookup tools available (`dig` or `nslookup`).

### Post-standup step 3 — Amplify WAF re-association

This step can be done without user input. Run:

```bash
aws amplify update-app \
  --region us-west-2 \
  --app-id $(terraform output -raw amplify_app_id) \
  --waf-configuration webAclArn=$(terraform output -raw waf_web_acl_arn)
```

Verify it took:

```bash
aws amplify get-app \
  --region us-west-2 \
  --app-id $(terraform output -raw amplify_app_id) \
  --query 'app.wafConfiguration'
```

Expected: `wafStatus` of `ASSOCIATION_SUCCESS`.

### Post-standup step 4 — Route53 nameservers (conditional)

Only required if the Route53 hosted zone was **destroyed and recreated**
(i.e., this was a full teardown/standup cycle, not just an update).

Check the current nameservers:

```bash
terraform output route53_nameservers
```

Then ask the user:
> Do the nameservers above match what's set at your Route53 Registrar?
> (AWS Console → Route53 → Registered domains → sherron-cloud.com → Name servers)
>
> If not, update them there. DNS propagation can take up to 48 hours.

---

## Import (first-time only)

If resources already exist in AWS and state is empty, import them first:

```bash
cd terraform
terraform init
terraform plan   # should show import actions, no destructive changes
terraform apply  # imports into state
```

After a successful import, `terraform plan` should show **no changes**.
If it shows changes, review them carefully with the user before applying.

---

## Plan only (dry run)

```bash
cd terraform
terraform plan
```

Summarize the output for the user: how many resources will be added,
changed, or destroyed. Do not apply without being asked.

---

## Safety rules

- **Never run `terraform destroy` without explicit user confirmation** of the
  goal, even if that was the stated task at the start of the session.
- **Never commit `terraform.tfvars`** — it is gitignored for a reason.
- **Never print secret values** from `terraform.tfvars` or outputs marked
  sensitive into the conversation.
- If `terraform plan` shows unexpected destructions (resources you didn't
  intend to remove), stop and ask the user before proceeding.
- The Route53 hosted zone teardown is the most consequential action — losing
  the zone means DNS goes dark and nameservers may change. Flag this
  explicitly before any destroy that includes it.

---

## Troubleshooting

**`Error: No valid credential sources found`**
→ AWS env vars not set. Export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

**`Error acquiring the state lock`**
→ A previous run may have crashed. Check for a lock and release if safe:
`terraform force-unlock <lock-id>`

**`Certificate not yet issued` after step 1**
→ The Cloudflare CNAME may not have propagated yet. Wait a few minutes and
retry the `aws acm describe-certificate` check.

**`terraform apply` wants to recreate the CloudFront distribution**
→ This is expected if the ACM cert ARN changed (new cert after teardown).
The distribution will briefly be unavailable during replacement.

**Amplify WAF association shows `ASSOCIATION_FAILED`**
→ The WAF ACL must exist and be in us-east-1 scope CLOUDFRONT before
associating. Confirm `terraform output waf_web_acl_arn` returns a valid ARN,
then retry the `update-app` command.
