#!/bin/bash

models_together() {
    echo "LiquidAI/LFM2-24B-A2B openai/gpt-oss-20b google/gemma-3n-E4B-it Qwen/Qwen3.5-9B essentialai/rnj-1-instruct moonshotai/Kimi-K2.5 deepseek-ai/DeepSeek-V3.1 meta-llama/Llama-3.3-70B-Instruct-Turbo"
}

request_completions_together() {
    local payload="$1"
    
    validate_provider_key "TOGETHER_API_KEY" "https://api.together.ai/settings/api-keys"

    curl $CURL_OPTS -s https://api.together.ai/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOGETHER_API_KEY" \
        -d "$payload"
}

init_completions_payload_together() {
    init_completions_payload_standard "$1"
}

concate_completions_payload_together() {
    concate_completions_payload_standard "$1" "$2" "$3"
}


parse_completions_response_together() {
    parse_completions_response_standard "$1"
}