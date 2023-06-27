#!/bin/bash

# Save with rsync on an external disk

# Get information from template file
DIRECTORIES=$(cat config.json | jq ".DIRECTORIES[]" --raw-output)
BACKUP_PATH=$(cat config.json | jq ".BACKUP_PATH" --raw-output)

for file in $DIRECTORIES
do
    	echo "[+] Saving $file ...
"
    	if [ -d "$file" ]
    	then
        	OUTPUT=$(echo "$file" | awk -F "/" 'NF{OFS="/";NF-=1};1')
        	rsync -avh --mkpath $file $BACKUP_PATH$OUTPUT --delete
    	else
    	    	rsync -avh --mkpath $file $BACKUP_PATH$file --delete
    	fi
	exit=$?
    	if [ $exit -eq 0 ]
	then
	   	echo "[+][+] $file saved !
"
	elif [ $exit -eq 23 ]
	then
		echo "!!! $file could not be save, retrying with sudo !!!"
		echo "[+] Saving $file ...
"
    		if [ -d "$file" ]
   		then
        		OUTPUT=$(echo "$file" | awk -F "/" 'NF{OFS="/";NF-=1};1')
        		sudo rsync -avh --mkpath $file $BACKUP_PATH$OUTPUT --delete
    		else
    		    	sudo rsync -avh --mkpath $file $BACKUP_PATH$file --delete
    		fi
    		if [ $? -eq 0 ]
		then
			echo "[+][+] $file saved !
"
		fi
	else
		echo "exit $exit"
		echo "!!! $file could not be saved !!!
"
	fi
done
exit 0