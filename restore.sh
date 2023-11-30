#!/bin/bash

# Save with rsync on an external disk

# Color variables
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

# Get information from template file
function get_config () {
	local config_file="${1}"
	if [[ -f "${config_file}" ]]
	then
		printf "${green}[+]Config file \""${config_file}"\" loaded.\n\n${reset}"
	else
		printf "${red}[+]Config file \""${config_file}"\" couldn't be found.\n${reset}"
		exit
	fi
	directories=$(cat "${config_file}" | jq ".DIRECTORIES[]" --raw-output)
	backup_path=$(cat "${config_file}" | jq ".BACKUP_PATH" --raw-output)
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

function print_help() {
   # Display Help
   printf "Saveit is a backup management tool, based on json templates.\n\n"
   printf "Syntax: ./restore.sh [-h] backup_template.json\n"
   printf "options:\n"
   printf "   -h	Print this help.\n"
   printf "   backup_template.json is a template in json format. An example can be found in the file backup_template.json\n"
}

function main(){
    # Check args number
	if [[ $# != 1 || $1 == "-h" ]]
	then
		print_help
		exit
	fi

    # Load config file
    if [ -f ${1} ]
    then
	    get_config "${1}"
    else
        error "exit $?: "${1}" is not a file"
        exit 1
    fi

	for file in ${directories}
	do
		local src="${backup_path}""${file}"
		local dst="${file}"
	
		# Try to sync as current user. If failed, try again as sudo.
		sync_user_files "${src}" "${dst}"
		if [ $? -eq 0 ]
		then
		   	printf "${green}[+][+] "${file}" saved !\n\n${reset}"
		else
			sync_privileged_files "${src}" "${dst}"
			if [ $? -eq 0 ]
			then
				printf "${green}[+][+] "${file}" saved !\n\n${reset}"
			else
				error "exit $?: "${file}" could not be saved"
				exit 2
			fi
		fi
	done
	exit 0
}

main $*