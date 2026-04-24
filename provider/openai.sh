#!/bin/bash

models_openai() {
    echo "gpt-4o gpt-4-turbo gpt-3.5-turbo"
}

request_openai() {
    local prompt="$1"
    
    validate_provider_key "OPENAI_API_KEY" "https://platform.openai.com/account/api-keys"

    local payload=$(jq -n \
        --arg model "$AIHUB_MODEL" \
        --arg prompt "$prompt" \
        --arg temp "$AIHUB_TEMPERATURE" \
        --arg max "$AIHUB_MAX_TOKENS" \
        '{
            model: $model, 
            temperature: ($temp | tonumber), 
            max_tokens: ($max | tonumber), 
            messages: [{role: "user", content: $prompt}]
        }')

    curl $CURL_OPTS -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$payload"

}

parse_response_openai() { parse_response_standard "$1"; }
init_chat_payload_openai() { init_chat_payload_standard "$1"; }
concate_chat_payload_openai() { concate_chat_payload_standard "$1" "$2" "$3"; }