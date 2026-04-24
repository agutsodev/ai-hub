#!/bin/bash

models_google() {
    echo "gemini-2.5-flash gemini-2.5-pro"
}

request_google() {
    local prompt="$1"

    validate_provider_key "GEMINI_API_KEY" "https://aistudio.google.com/app/api-keys"

    local payload=$(jq -n \
        --arg model "$AIHUB_MODEL" \
        --arg prompt "$prompt" \
        --arg temp "$AIHUB_TEMPERATURE" \
        --arg max "$AIHUB_MAX_TOKENS" \
        '{
			"contents": [
			{
				"parts": [
				{
					"text": $prompt
				}
				]
			}
			]
		}')
    
    curl $CURL_OPTS -s "https://generativelanguage.googleapis.com/v1beta/models/${AIHUB_MODEL}:generateContent" \
		-H "x-goog-api-key: $GEMINI_API_KEY" \
        -H "Content-Type: application/json" \
		-X POST \
        -d "$payload"
}

parse_response_google() {
    jq -r '.candidates[]?.content?.parts[]?.text' <<< "$1"
}

init_chat_payload_google() {
    local role="$1"
    jq -n \
        --arg role "$role" \
        --arg temp "${AIHUB_TEMPERATURE:-0.7}" \
        '{
            system_instruction: { parts: { text: $role } },
            generationConfig: { temperature: ($temp | tonumber) },
            contents: []
        }'
}

concate_chat_payload_google() {
    local current_payload="$1"
    local role="$2"
    local content="$3"
    
    # Map 'assistant' to 'model' for Google
    [[ "$role" == "assistant" ]] && role="model"
    
    local new_message=$(jq -n --arg r "$role" --arg c "$content" '{role: $r, parts: [{text: $c}]}')
    echo "$current_payload" | jq --argjson msg "$new_message" '.contents += [$msg]'
}