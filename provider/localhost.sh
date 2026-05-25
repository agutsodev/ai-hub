#!/bin/bash

AIHUB_LOCALHOST_URL=http://localhost:3001

models_localhost() {
    echo "model"
}

all_models_localhost() {
    models_localhost    
}

request_completions_localhost() {
    local payload="$1"
    curl $CURL_OPTS $AIHUB_LOCALHOST_URL/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d "$payload"

}

init_completions_payload_localhost() { init_completions_payload_standard "$1"; }

concate_completions_payload_localhost() { concate_completions_payload_standard "$1" "$2" "$3"; }

parse_completions_response_localhost() { parse_completions_response_standard "$1"; }