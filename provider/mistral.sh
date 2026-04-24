#!/bin/bash

models_mistral() {
    echo "mistral-small-latest mistral-medium-latest mistral-large-latest"
}

request_mistral() {
    local prompt="$1"
    
    validate_provider_key "MISTRAL_API_KEY" "https://admin.mistral.ai/organization/api-keys"
    
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
    
    curl $CURL_OPTS -s https://api.mistral.ai/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $mistral_API_KEY" \
        -d "$payload"
}

parse_response_mistral() { parse_response_standard "$1"; }
init_chat_payload_mistral() { init_chat_payload_standard "$1"; }
concate_chat_payload_mistral() { concate_chat_payload_standard "$1" "$2" "$3"; }
