# Agent Instructions — CF-CDN-AWS-Amplify

This repo contains both static site content and Terraform infrastructure. Quick reference for operating the demo.

---

## Project Structure

```
src/              # Static site (index.html, styles.css, script.js, dog.jpg)
terraform/        # Infrastructure as Code
  *.tf            # Terraform resources
  scripts/        # Standup/teardown helpers
  README.md       # Detailed Terraform ops guide
amplify.yml       # Amplify build config (builds from src/)
```

---

## Quick Operations

### Deploy Infrastructure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Fill in values from 1Password ("AWS CDN Demo — Terraform secrets")
terraform init
terraform apply
```

### Teardown (save money)
```bash
cd terraform
./scripts/teardown-partial.sh   # Recommended: destroys WAF + Amplify only
./scripts/teardown-full.sh      # Destroys everything (slower)
```

### Standup (restore service)
```bash
cd terraform
./scripts/standup-partial.sh    # After partial teardown
./scripts/standup-full.sh       # After full teardown
```

**CRITICAL after standup:** Update Cloudflare origin to new Amplify CloudFront domain or site returns Error 1016. See `terraform/README.md` for exact steps.

---

## Architecture Reminder

```
User → Route53 → Cloudflare (CDN + DDoS) → AWS WAF (Cloudflare IPs only) → CloudFront → Amplify (src/)
```

- Direct CloudFront/Amplify access: **403 Forbidden**
- Only Cloudflare IPs can reach origin

---

## Files to Never Commit

- `terraform/terraform.tfvars` (secrets)
- `terraform/.terraform/` (provider cache)
- `terraform/*.tfstate*` (state)

Already gitignored.
