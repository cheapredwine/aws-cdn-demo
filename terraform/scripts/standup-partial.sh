#!/usr/bin/env bash
# Partial standup — recreates WAF and Amplify, then automatically re-attaches
# WAF to Amplify and triggers a site deploy. No manual DNS or cert steps needed.
#
# Usage: ./scripts/standup-partial.sh

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Verifying AWS access..."
aws sts get-caller-identity > /dev/null

echo "==> Planning partial standup (WAF + Amplify)..."
terraform plan \
  -target=aws_wafv2_ip_set.cloudflare_ipv4 \
  -target=aws_wafv2_ip_set.cloudflare_ipv6 \
  -target=aws_wafv2_web_acl.allow_cloudflare \
  -target=aws_amplify_app.personal_website \
  -target=aws_amplify_branch.main \
  -target=aws_amplify_domain_association.sherron_cloud

echo ""
echo "Proceed with standup? (yes/no)"
read -r CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

# WAF IP sets must exist before the ACL that references them
terraform apply \
  -target=aws_wafv2_ip_set.cloudflare_ipv4 \
  -target=aws_wafv2_ip_set.cloudflare_ipv6 \
  -auto-approve

terraform apply \
  -target=aws_wafv2_web_acl.allow_cloudflare \
  -target=aws_amplify_app.personal_website \
  -target=aws_amplify_branch.main \
  -target=aws_amplify_domain_association.sherron_cloud \
  -auto-approve

echo "==> Attaching WAF to Amplify..."
APP_ID=$(terraform output -raw amplify_app_id)
WAF_ARN=$(terraform output -raw waf_web_acl_arn)

aws wafv2 associate-web-acl \
  --web-acl-arn "$WAF_ARN" \
  --resource-arn "arn:aws:amplify:us-west-2:512629184821:apps/$APP_ID" \
  --region us-east-1

# Verify WAF association
STATUS=$(aws amplify get-app \
  --region us-west-2 \
  --app-id "$APP_ID" \
  --query 'app.wafConfiguration.wafStatus' \
  --output text)

if [ "$STATUS" != "ASSOCIATION_SUCCESS" ]; then
  echo "WARNING: WAF association status is '$STATUS' — check the Amplify console."
else
  echo "==> WAF attached successfully."
fi

echo "==> Restoring Cloudflare CNAME records (Amplify overwrites these)..."
ZONE_ID=$(terraform output -raw route53_zone_id)

# Amplify domain association creates CNAMEs pointing directly to CloudFront,
# bypassing Cloudflare. Restore them to route through Cloudflare CDN so WAF
# sees Cloudflare IPs instead of client IPs.
aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch '{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "images.sherron-cloud.com",
        "Type": "CNAME",
        "TTL": 60,
        "ResourceRecords": [{"Value": "images.sherron-cloud.com.cdn.cloudflare.net"}]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "www.sherron-cloud.com",
        "Type": "CNAME",
        "TTL": 60,
        "ResourceRecords": [{"Value": "www.sherron-cloud.com.cdn.cloudflare.net"}]
      }
    }
  ]
}'

echo "==> Triggering Amplify deployment..."
aws amplify start-job \
  --region us-west-2 \
  --app-id "$APP_ID" \
  --branch-name main \
  --job-type RELEASE

echo ""
echo "==> Standup complete. Site is deploying."
echo "    Monitor build progress:"
echo "    https://us-west-2.console.aws.amazon.com/amplify/apps/$APP_ID"
echo ""
echo "!!! MANUAL STEP REQUIRED !!!"
echo "Update Cloudflare origin configuration for sherron-cloud.com subdomains:"
AMPLIFY_CF_DOMAIN=$(aws amplify get-domain-association \
  --app-id "$APP_ID" \
  --domain-name sherron-cloud.com \
  --region us-west-2 \
  --query 'domainAssociation.subDomains[0].dnsRecord' \
  --output text 2>/dev/null | awk '{print $NF}')
echo "  New Amplify CloudFront domain: ${AMPLIFY_CF_DOMAIN:-unknown}"
echo "  In Cloudflare dashboard, update origin to point to this domain."
echo "  Without this, images/CSS will fail with Error 1016."
echo ""
echo "NOTE: Route53 CNAMEs for images/www have been restored to route through"
echo "      Cloudflare CDN. This ensures WAF sees Cloudflare IPs, not client IPs."
echo ""
echo "    Outputs:"
terraform output
