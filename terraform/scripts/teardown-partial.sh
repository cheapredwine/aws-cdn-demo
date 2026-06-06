#!/usr/bin/env bash
# Partial teardown — destroys only the resources that cost money (WAF + Amplify).
# Leaves CloudFront, ACM, and Route53 in place so standup is fast and fully
# automated with no manual DNS steps.
#
# Usage: ./scripts/teardown-partial.sh

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Verifying AWS access..."
aws sts get-caller-identity > /dev/null

echo "==> Removing WAF association from Amplify before destroying WAF..."
APP_ID=$(terraform output -raw amplify_app_id 2>/dev/null || true)
if [ -n "$APP_ID" ]; then
  aws amplify update-app \
    --region us-west-2 \
    --app-id "$APP_ID" \
    --waf-configuration '{}' 2>/dev/null || true
fi

echo "==> Planning partial teardown (Amplify + WAF)..."
terraform plan \
  -target=aws_amplify_domain_association.sherron_cloud \
  -target=aws_amplify_branch.main \
  -target=aws_amplify_app.personal_website \
  -target=aws_wafv2_web_acl.allow_cloudflare \
  -target=aws_wafv2_ip_set.cloudflare_ipv4 \
  -target=aws_wafv2_ip_set.cloudflare_ipv6 \
  -destroy

echo ""
echo "The following will be DESTROYED. CloudFront, ACM, and Route53 are NOT affected."
echo "Proceed? (yes/no)"
read -r CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

terraform destroy \
  -target=aws_amplify_domain_association.sherron_cloud \
  -target=aws_amplify_branch.main \
  -target=aws_amplify_app.personal_website \
  -target=aws_wafv2_web_acl.allow_cloudflare \
  -target=aws_wafv2_ip_set.cloudflare_ipv4 \
  -target=aws_wafv2_ip_set.cloudflare_ipv6 \
  -auto-approve

echo ""
echo "==> Partial teardown complete."
echo "    CloudFront, ACM cert, and Route53 are still running."
echo "    Run scripts/standup-partial.sh to restore."
