#!/usr/bin/env bash

set -o nounset
set -o errexit

echo "Starting script"
current_ipv4="$(curl -s https://ipv4.icanhazip.com/)"
zone_id=$(curl -s -X GET \
    -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones?name=${CLOUDFLARE_RECORD_NAME}&status=active" \
      | jq --raw-output ".result[0] | .id"
)
record_ipv4=$(curl -s -X GET \
    -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=${CLOUDFLARE_RECORD_NAME}&type=A"
)
old_ip4=$(echo "$record_ipv4" | jq --raw-output '.result[0] | .content')
if [[ "${current_ipv4}" == "${old_ip4}" ]]; then
    echo "$(date -u) - IP Address '${current_ipv4}' has not changed"
    exit 0
fi

record_ipv4_identifier="$(echo "$record_ipv4" | jq --raw-output '.result[0] | .id')"
update_ipv4=$(curl -s -X PUT \
    "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_ipv4_identifier}" \
    -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"id\":\"${zone_id}\",\"type\":\"A\",\"proxied\":true,\"name\":\"${CLOUDFLARE_RECORD_NAME}\",\"content\":\"${current_ipv4}\"}" \
)
if [[ "$(echo "$update_ipv4" | jq --raw-output '.success')" == "true" ]]; then
    echo "$(date -u) - Success - IP Address '${current_ipv4}' has been updated"
    exit 0
else
    echo "$(date -u) - Yikes - Updating IP Address '${current_ipv4}' has failed"
    exit 1
fi
