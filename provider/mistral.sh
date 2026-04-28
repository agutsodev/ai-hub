#!/bin/bash

models_mistral() {
    echo "mistral-small-latest mistral-medium-latest mistral-large-latest"
}

request_completions_mistral() {
    local payload="$1"
    
    validate_provider_key "MISTRAL_API_KEY" "https://admin.mistral.ai/organization/api-keys"
    
    curl $CURL_OPTS -s https://api.mistral.ai/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $mistral_API_KEY" \
        -d "$payload"
}

init_completions_payload_mistral() { init_completions_payload_standard "$1"; }

concate_completions_payload_mistral() { concate_completions_payload_standard "$1" "$2" "$3"; }

parse_completions_response_mistral() { parse_completions_response_standard "$1"; }
