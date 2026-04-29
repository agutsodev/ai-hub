#!/bin/bash

models_groq() {
    echo "llama-3.1-8b-instant openai/gpt-oss-20b"
}

all_models_groq() {
    validate_provider_key "GROQ_API_KEY" "https://console.groq.com/keys"
    curl -s https://api.groq.com/openai/v1/models \
        -H "Authorization: Bearer $GROQ_API_KEY" | \
        jq -r '.data[].id' | sort -u
}

request_completions_groq() {
    local payload="$1"
    validate_provider_key "GROQ_API_KEY" "https://console.groq.com/keys"

    curl $CURL_OPTS -s https://api.groq.com/openai/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $GROQ_API_KEY" \
        -d "$payload"
}

init_completions_payload_groq() {
    init_completions_payload_standard "$1"
}

concate_completions_payload_groq() {
    concate_completions_payload_standard "$1" "$2" "$3"
}

parse_completions_response_groq() {
    parse_completions_response_standard "$1"
}