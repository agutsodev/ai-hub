#!/bin/bash

cd $(dirname "$0") || exit # navigate to absolute path

source .env # default env config

[[ -f .env.custom ]] && source .env.custom # custom config

if [[ "$OPENAI_API_KEY" == "" ]]; then # ask for api key if not exists
	ask="OPENAI_API_KEY envinromet varible not found. Please provide a valid key (https://platform.openai.com/account/api-keys):"
	
	api_key=""
	while [[ "$api_key" == "" ]]; do read -e -p "$ask" api_key; done
	
	touch .env.custom
	echo -e "OPENAI_API_KEY=$api_key\n\n$(cat .env.custom)" > .env.custom # add env var to begin of custom env file

	echo "*** OPENAI_API_KEY added to .env.custom file ***"	
	source .env.custom
fi

if ! [ -d log ]; then # create log folder if not exists

	for x in curl jq; do # check required dependencies once
		[[ "$(which $x)" == "" ]] && echo "ERROR: '$x' is a required dependency and should be installed." && exit
	done
	
	mkdir -p log
fi

### FUNCTIONS ### 

should_retry(){
	local try_again=""
	while [[ "$try_again" != "y" && "$try_again" != "n" ]]; do
		read -e -p "🔸no answer receiveid, try again? (y/n): " try_again
	done
	
	[[ "$try_again" == "n" ]] && exit 0
}

print_answer(){
	local answer="$1"

	answer=$(sed 's/%/%%/g' <<< "$answer") # escape percent char before print
	
	printf "$answer"
}

build_title(){
	local prompt=$1
	
	echo -e $prompt | sed s/[^[:alnum:]+]/-/g # replace non alphanumeric chars
}

build_log_file_name(){
	local title=$1

	echo "log/log_$(date '+%Y%m%d-%H%M%S')_$title.txt"
}

prompt_once(){
	local title="$1"
	local prompt="$2"

	payload='{
		"model": "'$OPENAI_COMPL_MODEL'",
		"temperature": '$OPENAI_COMPL_TEMPERATURE',
		"max_tokens": '$OPENAI_COMPL_MAX_TOKENS',
		"prompt": "'$prompt'"
	}'
	
	log_file=$(build_log_file_name "$title")
	echo -e "$(date) payload: \n $payload \n" > $log_file

	while [ true ]; do
		response=$(curl https://api.openai.com/v1/completions \
			-H "Content-Type: application/json" \
			-H "Authorization: Bearer $OPENAI_API_KEY" \
			-d "$payload" -k -L -s \
			--connect-timeout 10 --max-time 60 --retry 2 --retry-delay 0 --retry-max-time 120)
		
		[[ "$response" != "" ]] && break
		should_retry
	done

	echo -e "$(date) response: \n $response \n" >> $log_file

	answer=$(jq -r '.choices[]?.text' <<< "$response") 
	[[ "$answer" == "" ]] && echo "🔸Unexpected response: $response" && exit 1

	print_answer "$answer \n"
}

start_chat(){
	local role="$@"
	[[ "$role" == "" ]] && role=$OPENAI_CHAT_ROLE
	printf "\n🔹assistant role: $role\n\n"

	local payload='{
		"model": "'$OPENAI_CHAT_MODEL'",
		"temperature": '$OPENAI_CHAT_TEMPERATURE',
		"messages": [{"role": "assistant", "content": "'$role'"}]
	}'

	local log_file=""
	while [ true ]; do

		while [ "$prompt" == "" ]; do read -e -p "🔹you: " prompt; done

		if [[ $log_file == "" ]]; then 
			title=$(build_title "$prompt")
			log_file=$(build_log_file_name "CHAT_$title")
		fi

		user_message='{"role": "user", "content": "'$prompt'"}'

		payload=$(echo $payload | jq ".messages[.messages| length] |= . + $user_message")

		echo -e "$(date) payload: \n $payload \n" >> $log_file
		
		while [ true ]; do
			response=$(curl https://api.openai.com/v1/chat/completions \
				-H "Content-Type: application/json" \
				-H "Authorization: Bearer $OPENAI_API_KEY" \
				-d "$payload" -k -L -s \
				--connect-timeout 10 --max-time 60 --retry 2 --retry-delay 0 --retry-max-time 120)
			
			[[ "$response" != "" ]] && break
			should_retry
		done

		echo -e "$(date) response: \n $response \n" >> $log_file

		answer=$(jq -r '.choices[]?.message?.content' <<< "$response")	
		[[ "$answer" == "" ]] && echo "🔸Unexpected response: $response" && exit 1

		print_answer "\n $answer \n\n"

		answer=$(echo $answer | sed 's/"/\\"/g') # escape double quotes
		
		assistant_message='{"role": "assistant", "content": "'$answer'"}'

		payload=$(echo $payload | jq ".messages[.messages| length] |= . + $assistant_message")

		prompt=""
	done
}

### MAIN ###

if [[ ( $1 == "--help") ||  $1 == "-h" ]]; then 
	cat usage.txt

elif [[ ( $1 == "--chat") ||  $1 == "-c" ]]; then 	
	start_chat "${@:2}"

elif [[ ( $1 == "--code") ||  $1 == "-C" ]]; then 
	lang="${@:2}"
	while [ "$lang" == "" ]; do read -e -p "language: " lang; done

	while [ "$prompt" == "" ]; do read -e -p "code prompt: " prompt; done

	title=$(build_title "$prompt")
	full_prompt="$OPENAI_CODE_PREFIX \n\n [lang]: $lang \n\n [prompt]: $prompt"

	prompt_once "CODE_$title" "$full_prompt"

elif [[ ( $1 == "--shell") ||  $1 == "-s" ]]; then 
	source /etc/*-release
	my_os="$(uname) $(echo $DISTRIB_ID) $(echo $DISTRIB_RELEASE)"	

	prompt="${@:2}"
	while [ "$prompt" == "" ]; do read -e -p "shell prompt: " prompt; done

	title=$(build_title "$prompt")
	full_prompt="$OPENAI_SHELL_PREFIX \n\n [os]: $my_os \n\n [prompt]: $prompt"

	prompt_once "SHELL_$title" "$full_prompt"

else	
	prompt="$@"
	while [ "$prompt" == "" ]; do read -e -p "prompt once: " prompt; done

	title=$(build_title "$prompt")
	
	prompt_once "PROMPT_$title" "$prompt"
fi