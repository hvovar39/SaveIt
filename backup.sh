#!/bin/bash

# Save with rsync on an external disk

# Color variables
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

# Get information from template file
function get_config () {
	directories=$(cat config_test.json | jq ".DIRECTORIES[]" --raw-output)
	backup_path=$(cat config_test.json | jq ".BACKUP_PATH" --raw-output)
}

# Try to save src ($1) in dst ($2)
function sync_user_files() {
	local src="${1}"
	local dst="${2}"
	printf "[+] Saving "${src}" in "${dst}" ...\n"
	if [ -d ""${src}"" ]
    then
       	rsync -avh --mkpath "${src}"/ "${dst}" --delete
    else
       	rsync -avh --mkpath "${src}" "${dst}" --delete
    fi
}

# Try to save src ($1) in dst ($2) throught sudo
function sync_privileged_files() {
	local src="${1}"
	local dst="${2}"
	printf "${yellow}!!! "${src}" could not be save, retrying with sudo !!!\n${reset}"
	printf "[+] Saving "${src}" in "${dst}" ...\n"
	if [ -d ""${src}"" ]
    then
       	sudo rsync -avh --mkpath "${src}"/ "${dst}" --delete
    else
       	sudo rsync -avh --mkpath "${src}" "${dst}" --delete
    fi
    
}

# Write the error message on stderr
function error() {
	printf "${red}!!! %s${reset}\n" "${*}" 1>&2
}

function main(){
	get_config
	local flag=$1
	for file in ${directories}
	do
		# Check backup flag (either backup or restore)
		if [[ "${flag}" == "-b" ]]
		then
			local src="${file}"
			local dst="${backup_path}""${file}"
		elif [[ "${flag}" == "-r" ]]
		then
			local src="${backup_path}""${file}"
			local dst="${file}"
		else
			exit
		fi

		# Try to sync as current user. If failed, try again as sudo.
		sync_user_files "${src}" "${dst}"
		if [ $? -eq 0 ]
		then
		   	printf "${green}[+][+] "${file}" saved !\n${reset}"
		else
			sync_privileged_files "${src}" "${dst}"
			if [ $? -eq 0 ]
			then
				printf "${green}[+][+] "${file}" saved !\n${reset}"
			else
				error "exit $? "${file}" could not be saved"
				exit 1
			fi
		fi
	done
	exit 0
}

main $*