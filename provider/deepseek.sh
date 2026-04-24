#!/bin/bash

models_deepseek() {
    echo "deepseek-v4-flash deepseek-v4-pro"
}

request_deepseek() {
    local prompt="$1"
    
    validate_provider_key "DEEPSEEK_API_KEY" "https://platform.deepseek.com/api_keys"
    
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
    
    curl $CURL_OPTS -s https://api.deepseek.com/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
        -d "$payload"
}

parse_response_deepseek() { parse_response_standard "$1"; }
init_chat_payload_deepseek() { init_chat_payload_standard "$1"; }
concate_chat_payload_deepseek() { concate_chat_payload_standard "$1" "$2" "$3"; }
