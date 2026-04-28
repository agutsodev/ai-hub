#!/bin/bash

models_openai() {
    echo "gpt-5-nano gpt-5-mini gpt-5 gpt-5-pro"
}

request_completions_openai() {
    local payload="$1"
    
    validate_provider_key "OPENAI_API_KEY" "https://platform.openai.com/account/api-keys"

    curl $CURL_OPTS -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$payload"

}

init_completions_payload_openai() { init_completions_payload_standard "$1"; }

concate_completions_payload_openai() { concate_completions_payload_standard "$1" "$2" "$3"; }

parse_completions_response_openai() { parse_completions_response_standard "$1"; }