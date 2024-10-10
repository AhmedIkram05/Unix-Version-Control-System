#!/bin/bash

# Ahmed Ikram  2571642
# Scott Hamilton 2580109
# Charlie McSherry 2570537


# Variables
currentRepo="" # Stores the currently selected repository 
logFile="log.txt" # The name of the log file where changes and comments will be recorded
backupDir="backups" # The directory where file backups are stored

# Function to CREATE a new repository
createRepository() {
	# Ask the user for the name of the repository
	echo "Enter the name of the repository: "
	read repoName
	
	# Check if the repository already exists
	if [ -d "$repoName" ]; then
		echo "Repository '$repoName' already exists."
	else
		# Create the repository directory and a backup directory inside it
		mkdir "$repoName"
		mkdir -p "$repoName/$backupDir"
		currentRepo="$repoName"
		echo "Repository '$repoName' created"
	fi
}

# Function to SELECT a repository
selectRepository () {
        # List the available repositories
	echo "Available Repositories"
        for dir in */; do
                directoryName="${dir%/}" #remove trailing slash(/)
		echo " - ${directoryName}"
        done
	
	# Ask the user to select a repository
        echo "Enter the name of the repository you want to select: "
        read selectedRepo
	
	# Check if the repository exists
        if [ -d "$selectedRepo" ]; then
                currentRepo="$selectedRepo"
                echo "Selected Repository: '$currentRepo'"
		echo "Contents of the selected repository:"
		ls "$currentRepo"
		
		# Create a backup directory - if it doesn't already exist - for the selected repository
		if [ ! -d "$currentRepo/backups" ]; then
			mkdir "$currentRepo/$backupDir"
			echo "Backup directory created for the selected repository '$currentRepo'!"
        	fi
	else
                echo "Repository '$selectedRepo' does not exist."
        fi
}

# Function to LIST the contents of the current repository
listRepositoryContents() {
        # Check user has selected a repository
	if [ -z "$currentRepo" ]; then
		echo "No repository selected. Please create or select a repository first."
	else
		echo "Contents of the current '$currentRepo' repository:"
		ls "$currentRepo"
	fi
}

# Function to ADD files to the repository
addFile() {
	# Check user has selected a repository
	if [ -z "$currentRepo" ]; then
		echo "No repository selected. Please create or select a repository first."
	else
		# Ask the uer for the name of the file to add
		echo "Enter the name of the file to add: "
		read fileName
		# Create the file in the repository
		touch "$currentRepo/$fileName"
		echo "File '$fileName' added to the repository"
	fi
}

# Function to CHECK OUT a file for editing
checkOut() {
        # Check user has selected a repository
	if [ -z "$currentRepo" ]; then
                echo "No repository selected. Please create or select a repository first."
	else
		echo "Contents of the '$currentRepo' repo:"
		ls "$currentRepo"

		# Ask the user for the name of the file to check out
		echo "Enter the name of the file to check out: "
		read fileName
		if [ -f "$currentRepo/$fileName" ]; then
			# Check if the file has already been checked-out for editing
			if [ -f "$currentRepo/$fileName.checkedout" ]; then
				echo "File '$fileName' has already been checked-out for editing"
		else
			# Create a checked-out copy of the file and log the action
			cp "$currentRepo/$fileName" "$currentRepo/$fileName.checkedout"
			echo "File '$fileName' checked out for editing on $(date)"
			echo "User '$USER' checked out file '$fileName' on $(date)" >> "$currentRepo/$logFile"
			
			# Open the checked-out file for editing
			nano "$currentRepo/$fileName.checkedout"
		fi
		else
			echo "File '$fileName' does not exist in the repository '$currentRepo'"
		fi
	fi
}

# Function to CHECK IN a file after editing
checkIn() {
        if [ -z "$currentRepo" ]; then
                echo "No repository selected. Please create or select a repository first."
        else
		# Ask the user for the name of the file to check in 
                echo "Enter the name of the file to check-in: "
                read fileName
		
		# Check if the file has been checked-out
                if [ -f "$currentRepo/$fileName.checkedout" ]; then
                        originalFileContent=$(cat "$currentRepo/$fileName")
			# Replace the original file with the checked-in version
                        mv "$currentRepo/$fileName.checkedout" "$currentRepo/$fileName"
                        newFileContent=$(cat "$currentRepo/$fileName")

			# Check if the file has been edited since being checked-out
                        if [ "$originalFileContent" != "$newFileContent" ]; then
				# Log file text
				echo "User '$USER' checked in file '$fileName' on $(date)" >> "$currentRepo/$logFile"
                                echo "Changes made:" >> "$currentRepo/$logFile"
                                diff -u <(echo "$originalFileContent") <(echo "$newFileContent") | tail -n +4 >> "$currentRepo/$logFile"
				
				# Create a backup copy of the checked-in file with a timestamp and store it in the 'backups' directory
				echo "A copy of the file '$fileName' has been made in the backup directory!"
				cp "$currentRepo/$fileName" "$currentRepo/$backupDir/$fileName.backup_$(date +'%Y-%m-%d_%H-%M-%S')"
				
				# Print log file text to user in terminal
                        	echo "User '$USER' checked in file '$fileName' on $(date)"
				echo "Changes made:"
				diff -u <(echo "$originalFileContent") <(echo "$newFileContent") | tail -n +4

				# Ask the user for a comment about the changes they made for the log (press enter to skip)
				echo "Plese enter a comment about the changes made to the file for the log (Press enter to skip)"
                                read comment

				# If a comment is provided by the user, add it to the log
				if [ ! -z "$comment" ]; then
					echo "Comment from '$USER': $comment" >> "$currentRepo/$logFile"
				fi
			else
				echo "User '$USER' checked in file '$fileName' but no changes were made" >> "$currentRepo/$logFile"
			fi
		else
			echo "File '$fileName' was not checked out for editing"	
		fi
	fi
}

# Function to RESTORE a previous version of a file
restore() {
	# Check user has selected a repository
	if [ -z "$currentRepo" ]; then
                echo "No repository selected. Please create or select a repository first."
	else
		# Ask the user for the name of the file to rollback 
		echo "Enter the name of the file to rollback"
		read fileName

		# Check if there are previous versions of the file
		if [ -f "$currentRepo/$fileName" ]; then
			# Find the most recent backup file for the given file
			latestBackup="$(ls -t "$currentRepo/$backupDir/$fileName.backup_"* | head -n 2 | tail -n 1)"

			# Check if a backup file was found and restore it
			if [ -n "$latestBackup" ]; then
				# Restore the file from the latest backup
                                mv "$latestBackup" "$currentRepo"
                                echo "File '$fileName' rolled back to the previous version and backed up."
			else
				echo "No backup found for '$fileName'."
			fi		
		else
			# Check if a deleted file exists in backups and restore it
			latestDeletedBackup=$(ls -t "$currentRepo/$backupDir/$fileName.deleted_"* | head -n 1)
			echo $fileName
			if [ -n "$latestDeletedBackup)" ]; then
				echo $latestDeletesBackup
				mv "$latestDeletedBackup" "$currentRepo"
				echo "File '$fileName' rolled back to a previously deleted version."
			else 
				echo "File '$fileName' not found in the repository or its backups"
		
			fi
		fi
	fi
}

# Function to ARCHIVE the entire repository
archiveRepository() {
        # Check user has selected a repository
	if [ -z "$currentRepo" ]; then
                echo "No repository selected. Please create or select a repository first."
	else
		# Ask the user for the archive file name
		echo "Enter the name of the archive file e.g., archive.zip: "
		read archiveName

		# Check if the archive already exists
		if [ -f "$archiveName" ]; then
			echo "Archive file 'archiveName' already exists but it will now be overwritten"
		fi

		# Create the archive of the current repository
		zip -r "$archiveName" "$currentRepo"
		echo "Repository 'currentRepo' archived to '$archiveName'."
	fi
}

deleteFile() {        
	# Check user has selected a repository
	if [ -z "$currentRepo" ]; then
		echo "No repository selected. Please create or select a repository first."
	else
		# Ask the user for the name of the file to delete
		echo "Enter the name of the file to delete"
		read fileName
		
		# Check if the file exists in the current repository
		if [ -f "$currentRepo/$fileName" ]; then
			# Create a backup of the file then securely delete the file
			cp "$currentRepo/$fileName" "$currentRepo/$backupDir/$fileName.deleted_$(date +'%Y-%m-%d_%H-%M-%S')"
			rm  "$currentRepo/$fileName"
			echo "File '$fileName' backed up and securely deleted."
		else
			echo "File '$fileName' not found in the repository."
		fi
	fi
}

viewFile() {
	# Check if user has selected a repository
	if [ -z "$currentRepo" ]; then
		echo "No repository selected. Please create or select a repository first"
	else
		# Ask the user for the name of the file to view
		echo "Enter the name of the file to view"
		read fileName

		# Check if the file exists in the current repository
		if [ -f "$currentRepo/$fileName" ]; then
			# Display the contents of the file in the terminal
			less "$currentRepo/$fileName"
		else
			echo "File '$fileName' not found in the repository"
		fi
	fi
}

# Main menu
while true; do
	echo "==== Version Control System ===="
	echo "1. Create Repository"
	echo "2. Select Repository"
	echo "3. List Repository Contents"
	echo "4. Add File to Repository"
	echo "5. Check out file for editing"
	echo "6. Check in file after editing"
	echo "7. Restore a previous version"
	echo "8. Archive Repository"
	echo "9. Delete a file"
	echo "10  View a file"
	echo "11. Exit"
	echo "================================"

	read choice
	case $choice in
		1) createRepository ;;
		2) selectRepository ;;
		3) listRepositoryContents ;;
		4) addFile ;;
		5) checkOut ;;
		6) checkIn ;;
		7) restore ;;
		8) archiveRepository ;;
		9) deleteFile ;;
		10) viewFile ;;
		11) exit ;;
		*) echo "Invalid choice, please try again."
	esac
done
