#!/bin/bash

# Save with rsync on an external disk

# Color variables
red=$(tput setaf 1)
reset=$(tput sgr0)

# Get information from template file
function get_config () {
directories=$(cat config_test.json | jq ".DIRECTORIES[]" --raw-output)
backup_path=$(cat config_test.json | jq ".BACKUP_PATH" --raw-output)
}

# Try to save file in $1 in the backup_path
function save_user_files() {
	local file=$1
	printf "[+] Saving "${file}" ...
"
	if [ -d ""${file}"" ]
    then
       	local output=$(printf ""${file}"" | awk -F "/" 'NF{OFS="/";NF-=1};1')
       	rsync -avh --mkpath "${file}" "${backup_path}""${output}" --delete
    else
       	rsync -avh --mkpath "${file}" "${backup_path}""${file}" --delete
    fi
}

# Try to save file in $1 in the backup_path throught sudo
function save_privileged_files() {
	local file=$1
	printf "!!! "${file}" could not be save, retrying with sudo !!!"
	printf "[+] Saving "${file}" ...
"
 	if [ -d ""${file}"" ]
   	then
    	local output=$(printf ""${file}"" | awk -F "/" 'NF{OFS="/";NF-=1};1')
        sudo rsync -avh --mkpath "${file}" "${backup_path}""${output}" --delete
    else
       	sudo rsync -avh --mkpath "${file}" "${backup_path}""${file}" --delete
    fi
    
}

# Write the error message on stderr
function error() {
	printf "${red}!!! %s${reset}\n" "${*}" 1>&2
}

function main(){
	get_config
	for file in ${directories}
	do
		save_user_files "${file}"
		if [ $? -eq 0 ]
		then
		   	printf "[+][+] "${file}" saved !\n"
		else
			save_privileged_files "${file}"
			if [ $? -eq 0 ]
			then
				printf "[+][+] "${file}" saved !\n"
			else
				error "exit $? "${file}" could not be saved"
				exit 1
			fi
		fi
	done
	exit 0
}

main