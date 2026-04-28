#!/bin/bash

models_google() {
    echo "gemini-2.5-flash gemini-2.5-pro"
}


request_completions_google() {
    local payload="$1"
    
    validate_provider_key "GEMINI_API_KEY" "https://platform.openai.com/account/api-keys"

    curl $CURL_OPTS -s https://generativelanguage.googleapis.com/v1beta/openai/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $GEMINI_API_KEY" \
        -d "$payload"
}

init_completions_payload_google() { init_completions_payload_standard "$1"; }

concate_completions_payload_google() { concate_completions_payload_standard "$1" "$2" "$3"; }

parse_completions_response_google() { parse_completions_response_standard "$1"; }
