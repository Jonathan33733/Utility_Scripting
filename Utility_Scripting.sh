#!/bin/bash

function generate_v4() {
  local uuid=""
  local updateUuid=""
  local byte7=""
  local byte9=""
  #List from the hexadecimal table
  local hex_digits=(0 1 2 3 4 5 6 7 8 9 a b c d e f)

  # UUID format consists of 36 characters separated by hyphens
  for i in {1..36}; do
  # everytime i reaches these numbers it will put a -
    if [[ $i == 9 || $i == 14 || $i == 19 || $i == 24 ]]; then
      uuid="${uuid}-"
    else
      # Generates a random integer between 0 and 15 using the $((RANDOM%16)) syntax
      uuid="${uuid}${hex_digits[$((RANDOM%16))]}"
    fi
  done
  # Once UUID has been created it goes through the length of the UUID even though already knowing its 36 characters long
  for (( i=0; i<${#uuid}; i++ )); do
    # At these point will use the bitwise AND and OR to solve the 7th byte
    if [[ $i == 14 ]]; then
      #This would store the 2 bits as the 7th byte when the loop reaches to the position
      byte7="${uuid:i:1}${uuid:i+1:1}"
      byte7=$(( ( 0x${byte7} & 0x0f ) | 0x40 ))
      byte7=$(printf '%x' $byte7)
      updateUuid="${updateUuid}${byte7}"
      i=$((i+1))
    # This goes through same for the 9th byte
    elif [[ $i == 15 ]]; then
      # It adds this - because couldn't figure out why the calucaltions were wrong when not adding this bit
      updateUuid="${updateUuid}-"
    elif [[ $i == 19 ]]; then
      #This would store the 2 bits as the 9th byte when the loop reaches to the position
      byte9="${uuid:i:1}${uuid:i+1:1}"
      byte9=$(( ( 0x${byte9} & 0x3f ) | 0x80 ))
      byte9=$(printf '%x' $byte9)
      updateUuid="${updateUuid}${byte9}"
      i=$((i+1))
    else
      #Once its loop is finished creates the update UUID that makes it a verision 4
      updateUuid="${updateUuid}${uuid:i:1}"
    fi
  done

  echo "${updateUuid}"
}

function generate_v5() {
  # NameSpace_DNS: {6ba7b810-9dad-11d1-80b4-00c04fd430c8} got it from a site
  # https://stackoverflow.com/questions/10867405/generating-v5-uuid-what-is-name-and-namespace#:~:text=to%20be%20given.-,The%20namespace%20is%20either%20a%20UUID%20in%20string%20representation%20or,a%20string%20of%20arbitrary%20length.&text=The%20name%20is%20a%20string%20of%20arbitrary%20length.,-The%20name%20is
  local namespace="6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  # Have this so its not the name word all the time
  local name="$1"
  # Link the namespace and name 
  # When the sha1sum when its piped to the awk '{print $1}' it extracts the first field of the output, which is the actual hash value
  # awk '{print $1}': This extracts the first field of the output, which is the hexadecimal representation of the SHA1 hash.
  # sed -r 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/g': This uses a regular expression to split the hexadecimal string into groups of 8, 4, 4, 4, and 12 characters and inserts hyphens between the groups to generate a UUID-like format.
  # cut -c-36: This cuts the output to the first 36 characters, which is the length of a standard UUID
  local uuid="$(echo -n "${namespace}${name}" | sha1sum | awk '{print $1}' | sed -r 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/g' | cut -c-36)"
  
  echo "${uuid}"
}

function uuid4_textfile(){
  local uuid4="$(generate_v4)"
  
  # Removes file uuid4.txt
  if [[ -f "uuid4.txt" ]]; then
    echo "Old UUID4"
    cat "uuid4.txt"
    rm "uuid4.txt"
  fi

  # This check if there is a uuid5.txt
  if [[ -f "uuid5.txt" ]]; then
    # Check if uuid4 is the same as uuid5
    local uuid5=$(grep "$uuid4" uuid5.txt || true)
    if [[ -n "$uuid5" ]]; then
      uuid4="$(generate_v4)"
    fi

    # Searches for the UUID value in the "uuid5.txt" file
    if ! grep -q "${uuid4}" uuid5.txt; then
      echo "${uuid4}" >> uuid4.txt
      echo "New UUID4"
      echo "${uuid4}"
    fi
  else
    echo "${uuid4}" >> uuid4.txt
    echo "New UUID4"
    echo "${uuid4}"
  fi
  # Same this for uuid5_textfile
}

function uuid5_textfile(){
  local name="$1"
  local uuid5="$(generate_v5 "$name")"

  # Removes file uuid5.txt
  if [[ -f "uuid5.txt" ]]; then
    echo "Old UUID5"
    cat "uuid5.txt"
    rm "uuid5.txt"
  fi

  # This check if there is a uuid4.txt
  if [[ -f "uuid4.txt" ]]; then
    # Searches for the UUID value in the "uuid4.txt" file
    if ! grep -q "${uuid5}" uuid4.txt; then
      # Check if uuid5 is the same as uuid4
      local uuid4=$(grep "$uuid5" uuid4.txt || true)
      if [[ -n "$uuid4" ]]; then
        name="$uuid4"
        uuid5="$(generate_v5 "$name")"
      fi

      echo "${uuid5}" >> uuid5.txt
      echo "New UUID5"
      echo "${uuid5}"
    fi
  else
    echo "${uuid5}" >> uuid5.txt
    echo "New UUID5"
    echo "${uuid5}"
  fi
}

function folder_content() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  # The commands_PID Store the PID of the shell script commands
  local commands_PID=""
  local dir_name="$1"
  # List all files in the _Directory directory
  files=$(ls -R ${folder_name}/*)

  # Find all files in the specified directory and their sizes
  files_dir=$(find "$dir_name" -type f -printf "%s %f\n")

  # Loops through all subdirectories in _Directory
  for subdir in $(echo "$files" | grep ":$" | sed 's/://' | sort -u); do
    echo "$subdir"

    # Find the most recently modified file of this type and display its details
    # find "$subdir" -type f -name "*.$type": This command searches for regular files in the specified subdirectory that have a file name ending in the specified file type
    # -printf "%T+ %p\n": This command specifies the output format for each file that is found. %T+ tells find to output the modification time of the file in the format YYYY-MM-DDTHH:MM:SS.ssssss[±ZZ:ZZ], where the T separates the date and time, and the optional ±ZZ:ZZ specifies the time zone offset from UTC. %p tells find to output the full path of the file. 
    #| cut -d' ' -f2-: removes the modification time from the output by selecting only the second field and everything after it
    recent_file=$(find "$subdir" -type f -name "*.$type" -printf "%T+ %p\n" | sort -nr | head -1 | cut -d' ' -f2-)
    if [ -n "$recent_file" ]; then
      # Use stat to display details of the most recently modified file
      stat_output=$(stat "$recent_file")
      echo "Most recently modified $type file: $recent_file"
      echo "$stat_output"
      echo ""
    fi

    # Find the total size used in the current subdirectory
    # du: This is a command that estimates file space usage.
    #-hs: These are options for the du command. -h specifies that the output should be in human-readable format and -s specifies that the output should be a summary for the specified directory, rather than a list of individual 
    # awk: This is a text processing tool that can be used to manipulate and analyze data in text files.
    # '{ print $1 }': This is an awk command that selects the first field of each line of input Since the du command produces output in the format "<size> <path>", selecting the first field isolates the size information.
    size=$(du -hs "$subdir" | awk '{ print $1 }')
    echo "Total space used: $size"

    # Find the file types and their sizes in the current subdirectory
    # -type f: This is an option for the find command that specifies that only regular files should be selected.
    # "sed 's/.*.//'" which replaces everything up to and including the last dot in each filename with an empty string. This effectively extracts the file extension from each filename.
    # "uniq -c"removes duplicate lines and counts the number of occurrences of each line
    # "awk '{ print $2 }'" which prints only the second field of each line
    types=$(find "$subdir" -type f | sed 's/.*\.//' | sort | uniq -c | awk '{ print $2 }')
    # Types is just in an example: .txt .png .jpg and ect.
    for type in $types; do
      # Counts the number of files of that type
      # "-type f" specifies that we are looking for regular files
      # -name "*.$type": This is an option for the find command that specifies that only files with names that match the given pattern should be selected
      count=$(find "$subdir" -type f -name "*.$type" | wc -l)
      # Use "find" to search for files of the specified type in the current subdirectory
      # "-type f" specifies that we are looking for regular files (not directories, symlinks, etc.)
      # "-name "*.$type"" specifies that we are looking for files with names that end in ".$type"
      # "-exec stat --format="%s" {} +" tells "find" to execute the "stat" command on each file it finds and output the file size in bytes (using the "%s" format specifier)
      # The output of "find" and "stat" is piped to "awk", which adds up all the file sizes and prints the total
      size=$(find "$subdir" -type f -name "*.$type" -exec stat --format="%s" {} + | awk '{s+=$1} END {print s}')
      # Use "numfmt" to convert the file size from bytes to a human-readable format with units (e.g., KB, MB, GB)
      # "--to=iec-i" specifies the format of the output (using IEC binary prefixes)
      # "--suffix=B" specifies that the units should be "B" (i.e., bytes)
      size_with_units=$(numfmt --to=iec-i --suffix=B "$size")
      echo "File type: $type, Count: $count, Size: $size_with_units"
      commands_PID=$(pgrep -f "$count")
      PID_log_file "(PID: $commands_PID)[${timestamp}] Count: $count"
      echo ""

    done

    # Finds the shortest and longest file name in each subdirectory
    # -printf '%f\n' prints only the file name and a newline character
    # awk '{ print length, $0 }' adds the length of each file name to the beginning of the line, separated by a space
    # awk '{ print $2 }' prints only the file name without the length
    shortest=$(find "$subdir" -type f -printf '%f\n' | awk '{ print length, $0 }' | sort -n | head -n1 | awk '{ print $2 }')
    longest=$(find "$subdir" -type f -printf '%f\n' | awk '{ print length, $0 }' | sort -n | tail -n1 | awk '{ print $2 }')
    echo "Shortest file name: $shortest"
    echo "Longest file name: $longest"
    echo ""
    echo ""

  done

}

function log_folder_content() {
  # Assign the value of folder_name to a local variable called folder_name.
  local folder_name="$1"
  # Set the name of the log file to "log_<folder_name>.txt".
  local log_file_name="log_${folder_name}.txt"

  # Check if a file with the log file name already exists.
  if [[ -f "$log_file_name" ]]; then
    # If a file with the log file name exists, append a number to the end of the file name.
    count=1
    while [[ -f "${log_file_name%.*}${count}.txt" ]]; do
      ((count++))
    done
    log_file_name="${log_file_name%.*}${count}.txt"
  fi

  # Call the folder_content function with the specified folder name and assign the result to a local variable called log.
  local log="$(folder_content "$folder_name")"

  # Write the contents of the log variable to the log file.
  echo "$log" > "$log_file_name"
}

function log_activity() {
  # Get the current user's username
  local user=$(whoami)
  # Get the argument passed to the function and store it in a variable
  local argument_command="$1"
  # Combine the name of the current script file with the argument command and store it in a variable
  local command="${BASH_SOURCE[0]}${argument_command}"
  # Get the current timestamp and store it in a variable
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  # Set the name of the log file to store the activity information
  local log_file="log_activity.log"
  # Initialize a variable to store the process IDs of the commands that are run by the current user
  local commands_PID=""

  # Check if the log file exists; if not, create it
  if [ ! -f "${log_file}" ]; then
    touch "${log_file}"
  fi

  # Append the activity information to the log file
  echo "${timestamp} ${user} ran command: ${command}" >> "${log_file}"
  # Get the process IDs of the commands that are run by the current user
  commands_PID=$(pgrep -f "$user")
  # Call the PID_log_file function to append the process ID information to the log file
  PID_log_file "(PID: $commands_PID)[${timestamp}] ${user}"
}

function PID_log_file() {
  # The PID log to append.
  local pid_log="$1"
  # The name of the log file.
  local log_file="log_pid.log"

  # If the log file already exists, append the PID log to it.
  if [[ -f "$log_file" ]]; then
    echo "$pid_log" >> "$log_file"
    # If the log file does not exist, create it and append the PID log to it.
  else
    touch "$log_file"
    echo "$pid_log" >> "$log_file"
  fi
}

function argument() {
  local cmd="$1"
  local folder_name="$2"
  local word="$3"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  # Store the PID of the script
  local PID="$$"

  # Use a case statement to determine which command was specified.
  case "$cmd" in
  #-fc is the stands for directory content
    "-fc")
      if [[ -n "$folder_name" && -d "$folder_name" ]]; then
        # Log the command and PID to a file.
        PID_log_file "-fc \"$folder_name\""
        PID_log_file "(PID: $PID)[${timestamp}] script"
        # Log the activity to a file.
        log_activity " -fc \"$folder_name\""
        # Show the contents of the specified folder.
        log_folder_content "$folder_name"
        folder_content "$folder_name"
      else
        echo "Error: Folder name is missing or invalid."
        echo "Usage: ./uuid -fc <folder_name>"
      fi
      ;;
      #-v4 is for version 4 uuid
    "-v4")
      # Log the command and PID to a file.
      PID_log_file "-v4"
      PID_log_file "(PID: $PID)[${timestamp}] script"
      # Generate a version 4 UUID and write it to a text file.
      uuid4_textfile
      # Log the activity to a file.
      log_activity " -v4"
      ;;
      #-v5 is for version 5 uuid and -n is to input a whatever the word is
    "-v5")
      if [[ -n "$word" ]]; then
        # Log the command and PID to a file.
        PID_log_file "-v5 -n \"$word\""
        PID_log_file "(PID: $PID)[${timestamp}] script"
        # Generate a version 5 UUID with the specified word and write it to a text file.
        uuid5_textfile "$word"
        # Log the activity to a file.
        log_activity " -v5 -n \"$word\""
      else
        echo "Error: Word is missing."
        echo "Usage: ./uuid -v5 -n <word>"
      fi
      ;;
      # If the command is anything else, print an error message and usage instructions.
    *)
      echo "Invalid command: $cmd"
      echo "Usage: ./Utility_Scripting [-fc <folder_name> | -v4 | -v5 -n <word>]"
      ;;
  esac
}

# Check the number of command-line arguments.
if [[ $# -lt 1 || $# -gt 4 ]]; then
  echo "Invalid number of arguments."
  echo "Usage: ./Utility_Scripting [-fc <folder_name> | -v4 | -v5 -n <word>]"
  exit 1
fi


# Call the argument function with the command-line arguments.
argument "$@"