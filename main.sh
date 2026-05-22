#!/bin/bash


# set up error handling
set -eET
trap 'echo "❌ ERROR in $0 file at line $LINENO (code $?)"' ERR

# navigate to absolute path
cd $(dirname "$0") || exit 

# default config
source .env 
[[ -f .env.keys ]] && source .env.keys 

# create log folder if not exists
if ! [ -d log ]; then 
	# check required dependencies
	for x in curl jq; do 
		[[ "$(command -v $x)" == "" ]] && echo "❌ ERROR: '$x' is a required dependency and should be installed." && exit
	done

	mkdir -p log
fi


### FUNCTIONS ### 

should_retry(){
	local try_again=""
	while [[ "$try_again" != "y" && "$try_again" != "n" ]]; do
		read -e -p "🔸no answer received, try again? (y/n): " try_again
	done
	
	[[ "$try_again" == "n" ]] && exit 0
}

print_answer(){
	local answer="$1"
	printf "\n%s\n" "$answer"
}

build_title(){
	local prompt=$1
	# replace non alphanumeric chars | truncate
	echo -e "$prompt" | sed 's/[^[:alnum:]]\+/-/g' | cut -c 1-50
}

build_log_file_name(){
	local title=$1
	local file_name=$(echo "${title}_${AIHUB_PROVIDER}_${AIHUB_MODEL}" | tr '/' '-')
	echo "log/$(date '+%Y%m%d-%H%M%S')_${file_name}.txt"
}

prompt_once(){
	local title="$1"
	local prompt="$2"

	local log_file=$(build_log_file_name "$title")
	local role=$AIHUB_ROLE

	local payload=$(init_completions_payload_$AIHUB_PROVIDER "$role")
	payload=$(concate_completions_payload_$AIHUB_PROVIDER "$payload" "user" "$prompt")
	
	echo -e "$(date) payload: \n "$payload" \n" > $log_file

	while true; do
		response=$(request_completions_$AIHUB_PROVIDER "$payload")		
		[[ "$response" != "" ]] && break
		should_retry
	done

	echo -e "$(date) response: \n $response \n" >> $log_file

	answer=$(parse_completions_response_$AIHUB_PROVIDER "$response")
	[[ "$answer" == "" ]] && printf "\n🔸unexpected response: $response" && exit 1

	print_answer "$answer"
}

start_chat(){
	local role="$@"
	[[ "$role" == "" ]] && role=$AIHUB_ROLE
	printf "🔷 role: $role\n"

	local payload=$(init_completions_payload_$AIHUB_PROVIDER "$role")

	local log_file=""
	while true; do

		while [ "$prompt" == "" ]; do read -e -p "🔹you: " prompt; done

		if [[ $log_file == "" ]]; then 
			title=$(build_title "$prompt")
			log_file=$(build_log_file_name "CHAT_$title")
		fi

		payload=$(concate_completions_payload_$AIHUB_PROVIDER "$payload" "user" "$prompt")

		echo -e "$(date) payload: \n $payload \n" >> $log_file
		
		while true; do
			response=$(request_completions_$AIHUB_PROVIDER "$payload")
			[[ "$response" != "" ]] && break
			should_retry
		done

		echo -e "$(date) response: \n $response \n" >> $log_file

		answer=$(parse_completions_response_$AIHUB_PROVIDER "$response")
		[[ "$answer" == "" ]] && printf "\n🔸unexpected response: $response" && exit 1

		print_answer "$answer"

		payload=$(concate_completions_payload_$AIHUB_PROVIDER "$payload" "assistant" "$answer")

		prompt=""
	done
}

validate_provider_key() {
    local var_name=$1
    local provider_url=$2
    local current_val="${!var_name}"

    if [[ "$current_val" == "" ]]; then 
        local api_key=""
        while [[ "$api_key" == "" ]]; do 
			read -e -p "🔑 $var_name required ($provider_url): " api_key; 
		done
        
        # Add to the top of the custom env file
        touch .env.keys
        echo -e "$var_name=$api_key\n$(cat .env.keys)" > .env.keys
        source ".env.keys"
    fi
}

save_state() {
    echo "AIHUB_PROVIDER=$1" > ".env.state"
    echo "AIHUB_MODEL=$2" >> ".env.state"
}

choose_provider(){
	# avoid double execution when there is no state and -p option is provided
	[[ "$choose_provider_once" == true ]] && return 

    local providers=($(ls provider | sed 's/\.sh//'))
    
    PS3="⚙️  choose provider: "
    select AIHUB_PROVIDER in "${providers[@]}"; do
        [[ -n "$AIHUB_PROVIDER" ]] && break
    done
	validate_provider_functions "$AIHUB_PROVIDER"

    models=($(models_$AIHUB_PROVIDER))
    models+=("see-all")

    PS3="⚙️  choose $AIHUB_PROVIDER model: "
    select CHOICE in "${models[@]}"; do
        if [[ -n "$CHOICE" ]]; then
            if [[ "$CHOICE" == "see-all" ]]; then
                all_models=($(all_models_$AIHUB_PROVIDER))
                
                PS3="⚙️  choose $AIHUB_PROVIDER model (see all): "
                select SUB_CHOICE in "${all_models[@]}"; do
                    if [[ -n "$SUB_CHOICE" ]]; then
                        AIHUB_MODEL="$SUB_CHOICE"
                        break
                    fi
                done
            else
                AIHUB_MODEL="$CHOICE"
            fi
			break
        fi
    done

    save_state "$AIHUB_PROVIDER" "$AIHUB_MODEL" 
    show_provider
	choose_provider_once=true
}

validate_provider_functions() {
    local provider=$1
    local required_functions=(
        "models_$provider"
        "all_models_$provider"
        "request_completions_$provider"
        "parse_completions_response_$provider"
    )
    
    for func in "${required_functions[@]}"; do
        if ! declare -f "$func" > /dev/null; then
            echo "❌ ERROR: provider '$provider' missing required function: $func"
            exit 1
        fi
    done
}

show_provider(){
	echo -e "🤖 $AIHUB_PROVIDER/$AIHUB_MODEL"
}

init_completions_payload_standard() {
    local role="$1"
	jq -n \
        --arg model "$AIHUB_MODEL" \
        --arg temp "${AIHUB_TEMPERATURE}" \
		--arg max "${AIHUB_MAX_TOKENS}" \
        --arg role "$role" \
        '{
			model: $model, 
			temperature: ($temp | tonumber),
			max_completion_tokens: ($max | tonumber),
			messages: [{role: "system", content: $role}]
		}'
}

concate_completions_payload_standard() {
    local current_payload="$1"
    local role="$2"
    local content="$3"

    local new_message=$(jq -n --arg r "$role" --arg c "$content" '{role: $r, content: $c}')
    echo "$current_payload" | jq --argjson msg "$new_message" '.messages += [$msg]'
}

parse_completions_response_standard() {
    jq -r '.choices[]?.message?.content' <<< "$1"
}

### MAIN ###

# load all providers
for provider in provider/*.sh; do source "$provider"; done

# handle state
[[ -f ".env.state" ]] && source ".env.state"
[[ -z "$AIHUB_PROVIDER" ]] && choose_provider || show_provider

# handle options
if [[ "$1" =~ ^(--help|-h)$ ]]; then 
	cat usage.txt

elif [[ "$1" =~ ^(--chat|-c)$ ]]; then 	
	start_chat "${@:2}"

elif [[ "$1" =~ ^(--code|-C)$ ]]; then 
	lang="${@:2}"
	while [ "$lang" == "" ]; do read -e -p "language: " lang; done

	while [ "$prompt" == "" ]; do read -e -p "code prompt: " prompt; done

	title=$(build_title "$prompt")
	full_prompt="$AIHUB_CODE_PREFIX \n\n [lang]: $lang \n\n [prompt]: $prompt"

	prompt_once "CODE_$title" "$full_prompt"

elif [[ "$1" =~ ^(--shell|-s)$ ]]; then
	source /etc/*-release
	my_os="$(uname) $(echo $DISTRIB_ID) $(echo $DISTRIB_RELEASE)"	

	prompt="${@:2}"
	while [ "$prompt" == "" ]; do read -e -p "shell prompt: " prompt; done

	title=$(build_title "$prompt")
	full_prompt="$AIHUB_SHELL_PREFIX \n\n [os]: $my_os \n\n [prompt]: $prompt"

	prompt_once "SHELL_$title" "$full_prompt"

elif [[ "$1" =~ ^(--provider|-p)$ ]]; then
	choose_provider

else	
	prompt="$@"
	while [ "$prompt" == "" ]; do read -e -p "prompt once: " prompt; done

	title=$(build_title "$prompt")
	
	prompt_once "PROMPT_$title" "$prompt"
fi