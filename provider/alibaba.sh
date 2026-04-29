#!/bin/bash

models_alibaba() {
    echo "qwen-turbo qwen3.6-flash qwen3.6-plus qwen3-max"
}

all_models_alibaba() {
    validate_provider_key "ALIBABA_API_KEY" "https://www.alibabacloud.com/help/en/model-studio/first-api-call-to-qwen"
    curl -s https://dashscope-intl.aliyuncs.com/api/v1/models \
        -H "Authorization: Bearer $ALIBABA_API_KEY" | \
        jq -r '.output.models[].model' | sort -u
}

request_completions_alibaba() {
    local payload="$1"
    validate_provider_key "ALIBABA_API_KEY" "https://www.alibabacloud.com/help/en/model-studio/first-api-call-to-qwen"
    
    curl $CURL_OPTS -s https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $ALIBABA_API_KEY" \
        -d "$payload"
}

init_completions_payload_alibaba() { init_completions_payload_standard "$1"; }

concate_completions_payload_alibaba() { concate_completions_payload_standard "$1" "$2" "$3"; }

parse_completions_response_alibaba() { parse_completions_response_standard "$1"; }