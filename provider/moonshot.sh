#!/bin/bash

models_moonshot() {
    echo "moonshot-v1-8k moonshot-v1-32k moonshot-v1-128k kimi-k2.6"
}

request_moonshot() {
    local prompt="$1"
    
    validate_provider_key "MOONSHOT_API_KEY" "https://platform.moonshot.ai/console/api-keys"
    
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
    
    curl $CURL_OPTS -s https://api.moonshot.ai/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $MOONSHOT_API_KEY" \
        -d "$payload"
}

parse_response_moonshot() { parse_response_standard "$1"; }
init_chat_payload_moonshot() { init_chat_payload_standard "$1"; }
concate_chat_payload_moonshot() { concate_chat_payload_standard "$1" "$2" "$3"; }
