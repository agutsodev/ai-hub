#!/bin/bash

models_moonshot() {
    echo "moonshot-v1-8k moonshot-v1-32k moonshot-v1-128k kimi-k2.6"
}

all_models_moonshot() {
    validate_provider_key "MOONSHOT_API_KEY" "https://platform.moonshot.ai/console/api-keys"
    curl -s https://api.moonshot.ai/v1/models \
        -H "Authorization: Bearer $MOONSHOT_API_KEY" | \
        jq -r '.data[].id' | sort -u
}

request_completions_moonshot() {
    local payload="$1"
    validate_provider_key "MOONSHOT_API_KEY" "https://platform.moonshot.ai/console/api-keys"
    
    curl $CURL_OPTS -s https://api.moonshot.ai/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $MOONSHOT_API_KEY" \
        -d "$payload"
}

init_completions_payload_moonshot() { init_completions_payload_standard "$1"; }

concate_completions_payload_moonshot() { concate_completions_payload_standard "$1" "$2" "$3"; }

parse_completions_response_moonshot() { parse_completions_response_standard "$1"; }
