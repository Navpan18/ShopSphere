#!/bin/bash

# Jenkins Webhook Proxy Script
# This script handles CSRF tokens for webhook triggers

JENKINS_URL="http://localhost:9090"
WEBHOOK_TOKEN="shopsphere-webhook-token"

echo "Getting CSRF crumb from Jenkins..."
CRUMB=$(curl -s "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

if [ -z "$CRUMB" ]; then
    echo "Failed to get CSRF crumb"
    exit 1
fi

echo "CSRF Crumb: $CRUMB"
echo "Triggering Jenkins build..."

curl -X POST "${JENKINS_URL}/generic-webhook-trigger/invoke?token=${WEBHOOK_TOKEN}" \
  -H "${CRUMB}" \
  -H "Content-Type: application/json" \
  -d '{"repository":{"full_name":"Navpan18/ShopSphere"},"ref":"refs/heads/main"}'

echo ""
echo "Build trigger sent!"
