#!/bin/bash

models_alibaba() {
    echo "qwen-turbo qwen3.6-flash qwen3.6-plus qwen3-max"
}

request_alibaba() {
    local prompt="$1"
    
    validate_provider_key "ALIBABA_API_KEY" "https://www.alibabacloud.com/help/en/model-studio/first-api-call-to-qwen"
    
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
    
    curl $CURL_OPTS -s https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $ALIBABA_API_KEY" \
        -d "$payload"
}

parse_response_alibaba() { parse_response_standard "$1"; }
init_chat_payload_alibaba() { init_chat_payload_standard "$1"; }
concate_chat_payload_alibaba() { concate_chat_payload_standard "$1" "$2" "$3"; }