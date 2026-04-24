#!/bin/bash

models_anthropic() {
    echo "claude-opus-4-6 claude-opus-4-7 claude-sonnet-4-6"
}

request_anthropic() {
    local prompt="$1"

    validate_provider_key "ANTHROPIC_API_KEY" "https://platform.claude.com/settings/keys"

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
    
    curl $CURL_OPTS -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "Content-Type: application/json" \
        -d "$payload"
}

parse_response_anthropic() {
    jq -r '.content[]?.text' <<< "$1"
}