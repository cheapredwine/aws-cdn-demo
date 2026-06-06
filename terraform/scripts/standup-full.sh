#!/usr/bin/env bash
# Full standup — recreates all resources from scratch after a full teardown.
# Requires manual Cloudflare and registrar steps after running.
# See AGENT.md for the complete post-standup checklist.
#
# Usage: ./scripts/standup-full.sh

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Verifying AWS access..."
aws sts get-caller-identity > /dev/null

echo "==> Planning full standup..."
terraform plan

echo ""
echo "Proceed? (yes/no)"
read -r CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

terraform apply -auto-approve

echo ""
echo "==> Attaching WAF to Amplify..."
APP_ID=$(terraform output -raw amplify_app_id)
WAF_ARN=$(terraform output -raw waf_web_acl_arn)

aws amplify update-app \
  --region us-west-2 \
  --app-id "$APP_ID" \
  --waf-configuration webAclArn="$WAF_ARN"

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

echo ""
echo "==> Infrastructure is up. Manual steps still required:"
echo ""
echo "1. ACM cert validation — add this CNAME to Cloudflare (demo.jsherron.com zone):"
aws acm describe-certificate --region us-east-1 \
  --certificate-arn "$(terraform output -raw acm_certificate_arn)" \
  --query 'Certificate.DomainValidationOptions[0].{Name:ResourceRecord.Name,Value:ResourceRecord.Value}' \
  --output table
echo ""
echo "2. Cloudflare DNS — add/update CNAME in demo.jsherron.com zone:"
echo "   cloudfront-pool  CNAME  $(terraform output -raw cloudfront_pool_domain)"
echo ""
echo "3. Route53 nameservers — check if these match your registrar:"
terraform output route53_nameservers
echo "   If not, update at: Route53 > Registered domains > sherron-cloud.com"
echo ""
echo "==> Triggering Amplify deployment (will succeed once domain/cert are valid)..."
aws amplify start-job \
  --region us-west-2 \
  --app-id "$APP_ID" \
  --branch-name main \
  --job-type RELEASE

echo ""
echo "    Monitor build: https://us-west-2.console.aws.amazon.com/amplify/apps/$APP_ID"
