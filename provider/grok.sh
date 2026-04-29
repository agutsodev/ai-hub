#!/bin/bash

models_grok() {
    echo "grok-4-1-fast-non-reasoning grok-4-1-fast-reasoning"
}

all_models_grok() {
    validate_provider_key "XAI_API_KEY" "https://docs.x.ai/developers/quickstart"
    curl -s https://api.x.ai/v1/models \
        -H "Authorization: Bearer $XAI_API_KEY" | \
        jq -r '.data[].id' | sort -u
}

request_completions_grok() {
    local payload="$1"
    validate_provider_key "XAI_API_KEY" "https://docs.x.ai/developers/quickstart"

    curl $CURL_OPTS -s https://api.x.ai/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $XAI_API_KEY" \
        -d "$payload"
}

init_completions_payload_grok() {
    init_completions_payload_standard "$1"
}

concate_completions_payload_grok() {
    concate_completions_payload_standard "$1" "$2" "$3"
}

parse_completions_response_grok() {
    parse_completions_response_standard "$1"
}