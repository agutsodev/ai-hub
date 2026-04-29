#!/bin/bash

models_deepseek() {
    echo "deepseek-v4-flash deepseek-v4-pro"
}

all_models_deepseek() {
    validate_provider_key "DEEPSEEK_API_KEY" "https://platform.deepseek.com/api_keys"
    curl -s https://api.deepseek.com/models \
        -H "Authorization: Bearer $DEEPSEEK_API_KEY" | \
        jq -r '.data[].id' | sort -u
}

request_completions_deepseek() {
    local payload="$1"
    validate_provider_key "DEEPSEEK_API_KEY" "https://platform.deepseek.com/api_keys"
    
    curl $CURL_OPTS -s https://api.deepseek.com/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
        -d "$payload"
}

init_completions_payload_deepseek() { init_completions_payload_standard "$1"; }

concate_completions_payload_deepseek() { concate_completions_payload_standard "$1" "$2" "$3"; }

parse_completions_response_deepseek() { parse_completions_response_standard "$1"; }
