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

aws amplify update-app \
  --region us-west-2 \
  --app-id "$APP_ID" \
  --waf-configuration webAclArn="$WAF_ARN"

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
echo "    Outputs:"
terraform output
