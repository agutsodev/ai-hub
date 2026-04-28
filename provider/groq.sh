#!/bin/bash

models_groq() {
    echo "llama-3.1-8b-instant openai/gpt-oss-20b"
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