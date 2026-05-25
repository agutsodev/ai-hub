#!/bin/bash


# set up error handling
set -eET
trap 'echo "🔸error in $0 file at line $LINENO (code $?)"' ERR

# navigate to absolute path
cd "$(dirname "$0")" || exit 

# default config
source .env 
[[ -f .env.keys ]] && source .env.keys

# create log folder if not exists
if ! [ -d log ]; then 
	# check required dependencies
	for x in curl jq xclip; do 
		[[ "$(command -v $x)" == "" ]] && echo "🔸'$x' is a required dependency and should be installed." && exit
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
	printf "\n%s\n\n" "$answer"
}

build_title(){
	local prompt=$1
	# replace non alphanumeric chars | truncate
	echo -e "$prompt" | sed 's/[^[:alnum:]]\+/-/g' | cut -c 1-50
}

build_log_file_name(){
	local title=$1
	local file_name=$(echo "${title}_${AIHUB_PROVIDER}-${AIHUB_MODEL}" | tr '/' '-')
	echo "log/$(date '+%y%m%d-%H%M%S')_${file_name}.txt"
}

print_role(){
	printf "▫️  %s\n" "$1"
}

start_chat(){
	local role="$1"
	[[ "$role" == "" ]] && role=$AIHUB_ROLE
	print_role "$role"

	local actions="$2"

	local payload=$(init_completions_payload_$AIHUB_PROVIDER "$role")

	local log_file=""
	local title=""
	while true; do

		while [ "$prompt" == "" ]; do read -e -p "🔹 " prompt; done

		if [[ $log_file == "" ]]; then 
			title=$(build_title "$prompt")
			log_file=$(build_log_file_name "$title")
		fi

		payload=$(concate_completions_payload_$AIHUB_PROVIDER "$payload" "user" "$prompt")
		printf "%s\n%s\n\n" "$(date) payload:" "$payload" >> "$log_file"		

		while true; do
			response=$(request_completions_$AIHUB_PROVIDER "$payload")
			[[ "$response" != "" ]] && break
			should_retry
		done

		printf "%s\n%s\n\n" "$(date) response:" "$response" >> "$log_file"		

		answer=$(parse_completions_response_$AIHUB_PROVIDER "$response" || true)
		[[ "$answer" == "" ]] && printf "\n🔸unexpected response: $response" && exit 1

		print_answer "$answer"

		if [[ $actions != "" ]]; then
			read -e -p "⚙️  $actions (k)keep on chat: " option
			case $option in 
				"c")
					clean_answer=$(cleanup_output "$answer")
					echo "$clean_answer" | xclip -selection clipboard
					echo "⚡️ comand copied to clipboard";
					exit 0;			
					;;
				"p")
					clean_answer=$(cleanup_output "$answer")
					read -e -i "$clean_answer" -p "⚡️ " comand_edited
					bash -c "$comand_edited"
					exit 0;
					;;
				"s")
					clean_answer=$(cleanup_output "$answer")
					timestamp=$(date +"%y%m%d-%H%M%S")
					filename="code/${timestamp}_${title}.md"
					[[ ! -d code ]] && mkdir -p code
					echo "$clean_answer" > "$filename"
					echo "💾 $filename"
					exit 0;
					;;
			esac
		fi
		
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
        
		[[ ! -f .env.keys ]] && touch .env.keys && chmod 600 .env.keys
        printf '%s=%s\n' "$var_name" "$api_key" >> .env.keys
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
            echo "🔸provider '$provider' missing required function: $func"
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
    jq -r '.choices[].message.content' <<< "$1" 2>/dev/null
}

cleanup_output(){
	# break lines from begin/end, quoted lines from begin/end, trim
	echo "$1" | sed ':a;N;$!ba; s/^[[:space:]]*//; s/[[:space:]]*$//' \
			  | sed '1{/^[[:space:]]*```/d}; ${/^[[:space:]]*```[[:space:]]*$/d;}' \
			  | sed '1{s/^[[:space:]]*//}; ${s/[[:space:]]*$//}'
}

### MAIN ###

# handle options
if [[ "$1" =~ ^(--help|-h)$ ]]; then 
	cat usage.txt

elif [[ "$1" =~ ^(--update|-u)$ ]]; then
	git fetch && git pull

elif [[ "$1" =~ ^(--version|-v)$ ]]; then
	git branch | grep "*"
	git rev-parse HEAD

else
	# load all providers
	for provider in provider/*.sh; do source "$provider"; done

	# handle state
	[[ -f ".env.state" ]] && source ".env.state"
	[[ -z "$AIHUB_PROVIDER" ]] && choose_provider || show_provider

	if [[ "$1" =~ ^(--provider|-p)$ ]]; then
		choose_provider	
		
	elif [[ "$1" =~ ^(--code|-c)$ ]]; then
		lang="${@:2}"
		while [ "$lang" == "" ]; do read -e -p "⚙️  language: " lang; done

		full_prompt="$AIHUB_CODE_PREFIX [language: $lang]"
		start_chat "$full_prompt" "(c)copy to clipboard (s)save to file"

	elif [[ "$1" =~ ^(--shell|-s)$ ]]; then
		source /etc/*-release
		my_os="$(uname) $(echo $DISTRIB_ID) $(echo $DISTRIB_RELEASE)"	

		full_prompt="$AIHUB_SHELL_PREFIX [os: $my_os]"
		start_chat "$full_prompt" "(c)copy to clipboard (p)paste to edit"
	else	
		start_chat "${@:1}"
	fi
fi