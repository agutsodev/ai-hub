#!/bin/bash

models_anthropic() {
    echo "claude-sonnet-4-6 claude-opus-4-6 claude-opus-4-7"
}

all_models_anthropic() {
    validate_provider_key "ANTHROPIC_API_KEY" "https://platform.claude.com/settings/keys"
    curl -s https://api.anthropic.com/v1/models \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" | \
        jq -r '.data[].id' | sort -u
}

request_completions_anthropic() {
    local payload="$1"
    validate_provider_key "ANTHROPIC_API_KEY" "https://platform.claude.com/settings/keys"

    curl $CURL_OPTS -s https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "$payload"
}

init_completions_payload_anthropic() {
    local role="$1"
    jq -n \
        --arg model "$AIHUB_MODEL" \
        --arg system "$role" \
        --arg temp "${AIHUB_TEMPERATURE}" \
        --arg max "${AIHUB_MAX_TOKENS}" \
        '{
            model: $model, 
            system: $system,
            temperature: ($temp | tonumber), 
            max_tokens: ($max | tonumber),
            messages: []
        }'
}

concate_completions_payload_anthropic() {
    concate_completions_payload_standard "$1" "$2" "$3"
}

parse_completions_response_anthropic() {
    jq -r '.content[]?.text' <<< "$1"
}