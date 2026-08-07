# aws-cf-cdn

A complete reference architecture demonstrating Cloudflare CDN in front of AWS infrastructure: Amplify static hosting → CloudFront distribution → AWS WAF origin lockdown → Cloudflare edge caching and security.

This repo contains both the **demo static site** (`src/`) and the **Terraform infrastructure** (`terraform/`) to deploy it.

---

## Architecture

```
User Request Flow:
==================

Internet
    ↓
Route 53 (DNS)
    CNAME: images.sherron-cloud.com
    Target: images.sherron-cloud.com.cdn.cloudflare.net
    ↓
Cloudflare Edge Network (CDN + Security)
    - DDoS Protection
    - Global Caching (HTML + Assets)
    - SSL/TLS Termination
    IPs: 104.x.x.x, 172.x.x.x (Cloudflare Anycast)
    ↓
AWS WAF (IP Allowlist)
    Only allows Cloudflare IP ranges
    Blocks all other traffic → 403 Forbidden
    ↓
CloudFront Distribution
    Origin: S3 (Amplify)
    Custom Domain: images.sherron-cloud.com
    Distribution ID: d2vcgkdl5as6rs.cloudfront.net
    ↓
AWS Amplify (Origin)
    S3 Static Website Hosting
    Default Domain: main.dkipny3chz7d8.amplifyapp.com
```

### Origin Lockdown

| Access Method | URL | Status |
|--------------|-----|--------|
| ✅ **Via Cloudflare** | `https://images.sherron-cloud.com/` | 200 OK |
| ❌ **Direct CloudFront** | `https://d2vcgkdl5as6rs.cloudfront.net/` | 403 Forbidden |
| ❌ **Direct Amplify** | `https://main.dkipny3chz7d8.amplifyapp.com/` | 403 Forbidden |

---

## Project Structure

```
aws-cf-cdn/
├── src/                    # Static site content
│   ├── index.html          # Demo page
│   ├── styles.css          # Styling
│   ├── script.js           # Interactivity
│   └── dog.jpg             # Image asset
├── terraform/              # Infrastructure as Code
│   ├── *.tf                # Terraform resources
│   ├── scripts/            # Standup/teardown helpers
│   └── README.md           # Terraform ops guide
├── amplify.yml             # AWS Amplify build config
└── README.md               # This file
```

---

## Quick Start

### Deploy the Infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Fill in values from 1Password ("AWS CDN Demo — Terraform secrets")
terraform init
terraform apply
```

See `terraform/README.md` for detailed teardown/standup procedures (partial and full modes).

### Site Content

The `src/` directory contains a simple static demo site. Amplify deploys from `src/` via `amplify.yml`.

---

## Security

- **DDoS Protection**: Cloudflare
- **Origin Lockdown**: AWS WAF with Cloudflare IP allowlisting
- **Global Edge Caching**: Cloudflare + CloudFront
- **SSL/TLS**: Automatically managed

### AWS WAF Configuration

**Web ACL Name**: `amplify-cloudflare-only`
**Rule**: `allow_cloudflare_ipv4` — Allow action for 15 Cloudflare IPv4 CIDR blocks
**Default Action**: Block (denies all non-Cloudflare IPs)

---

## Costs

| Service | Monthly Cost |
|---------|-------------|
| AWS Amplify (Hosting) | Free (under limits) |
| AWS WAF | ~$5 base + $1/million requests |
| Cloudflare (Free Plan) | Free |
| Route 53 | ~$0.50/month per hosted zone |
| **Total** | **~$5-6/month** |

---

## Merged From

- `personal-website` — Static site content and architecture docs
- `aws-cdn-demo` — Terraform infrastructure and operational scripts

Renamed from `cf-cdn-aws-amplify` to `aws-cf-cdn`.

*Last updated: August 2026*
