#!/usr/bin/env bash
# Full teardown — destroys ALL managed resources including CloudFront, ACM,
# and Route53. Use this only if you want to completely eliminate the infrastructure.
#
# WARNING: This will change your Route53 nameservers when recreated, requiring
# a manual registrar update and up to 48h DNS propagation. Prefer
# teardown-partial.sh for routine cost-saving teardowns.
#
# Usage: ./scripts/teardown-full.sh

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Verifying AWS access..."
aws sts get-caller-identity > /dev/null

echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "  FULL TEARDOWN — this destroys everything including Route53."
echo "  Standup will require manual DNS and Cloudflare steps."
echo "  Are you sure? Type 'destroy everything' to confirm:"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
read -r CONFIRM
if [ "$CONFIRM" != "destroy everything" ]; then
  echo "Aborted."
  exit 1
fi

echo "==> Removing WAF association from Amplify before destroying WAF..."
APP_ID=$(terraform output -raw amplify_app_id 2>/dev/null || true)
if [ -n "$APP_ID" ]; then
  WAF_ARN=$(terraform output -raw waf_web_acl_arn 2>/dev/null || true)
  if [ -n "$WAF_ARN" ]; then
    aws wafv2 disassociate-web-acl \
      --resource-arn "arn:aws:amplify:us-west-2:512629184821:apps/$APP_ID" \
      --region us-east-1 2>/dev/null || true
  fi
fi

terraform destroy -auto-approve

echo ""
echo "==> Full teardown complete."
echo "    See AGENT.md for the manual steps required before standup will work."
