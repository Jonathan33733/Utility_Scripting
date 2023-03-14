#!/bin/bash

function generate_v4() {
  local uuid=""
  local updateUuid=""
  local byte7=""
  local byte9=""
  local PID="$$" # Store the PID of the script
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
  local uuid="$(echo -n "${namespace}${name}" | sha1sum | awk '{print $1}' | sed -r 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/g' | cut -c-36)"
  
  echo "${uuid}"
}

function uuid4_textfile(){
  local uuid4="$(generate_v4)"
  # This will get store inside a txt file just for UUID if it exist remove it
  if [[ -f "uuid4.txt" ]]; then
    rm "uuid4.txt"
  fi

  # This check if there is a  uuid5.txt
  if [[ -f "uuid5.txt" ]]; then
    # Searches for the UUID value in the "uuid5.txt" file
    if ! grep -q "${uuid4}" uuid5.txt; then
      echo "${uuid4}" >> uuid4.txt
      echo "${uuid4}"
    fi
  else
    echo "${uuid4}" >> uuid4.txt
    echo "${uuid4}"
  fi
  # Same this for uuid5_textfile
}

function uuid5_textfile(){
  local name="$1"
  local uuid5="$(generate_v5 "$name")"

  if [[ -f "uuid5.txt" ]]; then
    rm "uuid5.txt"
  fi

  if [[ -f "uuid4.txt" ]]; then
    if ! grep -q "${uuid5}" uuid4.txt; then
      echo "${uuid5}" >> uuid5.txt
      echo "${uuid5}"
    fi
  else
    echo "${uuid5}" >> uuid5.txt
    echo "${uuid5}"
  fi
}

function folder_content() {
  # The commands_PID Store the PID of the shell script commands
  local commands_PID=""
  local dir_name="$1"
  # List all files in the _Directory directory
  files=$(ls -R ${folder_name}/*)

  # Loops through all subdirectories in _Directory
  for subdir in $(echo "$files" | grep ":$" | sed 's/://' | sort -u); do
    echo "$subdir"

    # Find the most recently modified file of this type and display its details
    recent_file=$(find "$subdir" -type f -name "*.$type" -printf "%T+ %p\n" | sort -nr | head -1 | cut -d' ' -f2-)
    if [ -n "$recent_file" ]; then
      # Use stat to display details of the most recently modified file
      stat_output=$(stat "$recent_file")
      echo "Most recently modified $type file: $recent_file"
      echo "$stat_output"
      echo ""
    fi

    # Find the total size used in the current subdirectory
    size=$(du -hs "$subdir" | awk '{ print $1 }')
    echo "Total space used: $size"

    # Find the file types and their sizes in the current subdirectory
    #"sed 's/.*.//'" which replaces everything up to and including the last dot in each filename with an empty string. This effectively extracts the file extension from each filename.
    #"uniq -c"removes duplicate lines and counts the number of occurrences of each line
    #"awk '{ print $2 }'" which prints only the second field of each line
    types=$(find "$subdir" -type f | sed 's/.*\.//' | sort | uniq -c | awk '{ print $2 }')
    # Types is just in an example: .txt .png .jpg and ect.
    for type in $types; do
      # Counts the number of files of that type
      # "-type f" specifies that we are looking for regular files
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
      PID_log_file "$commands_PID"
      echo ""

    done

    # Finds the shortest and longest file name in each subdirectory
    shortest=$(find "$subdir" -type f -printf '%f\n' | awk '{ print length, $0 }' | sort -n | head -n1 | awk '{ print $2 }')
    longest=$(find "$subdir" -type f -printf '%f\n' | awk '{ print length, $0 }' | sort -n | tail -n1 | awk '{ print $2 }')
    echo "Shortest file name: $shortest"
    echo "Longest file name: $longest"
    echo ""
    echo ""

  done

}

function log_folder_content() {
  local folder_name="$1"
  local log_file_name="log_${folder_name}.txt"

  if [[ -f "$log_file_name" ]]; then
    count=1
    while [[ -f "${log_file_name%.*}${count}.txt" ]]; do
      ((count++))
    done
    log_file_name="${log_file_name%.*}${count}.txt"
  fi

  local log="$(folder_content "$folder_name")"

  echo "$log" > "$log_file_name"
}

function log_activity() {
  local user=$(whoami)
  local argument_command="$1"
  local command="${BASH_SOURCE[0]}${argument_command}"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  local log_file="log_activity.log"
  local commands_PID=""

  # check if log file exists
  if [ ! -f "${log_file}" ]; then
    touch "${log_file}"
  fi

  # append activity information to log file
  echo "${timestamp} ${user} ran command: ${command}" >> "${log_file}"
  commands_PID=$(pgrep -f "$user")
  PID_log_file "$commands_PID"
}

function PID_log_file() {
  local pid_log="$1"
  local log_file="log_pid.log"

  if [[ -f "$log_file" ]]; then
    echo "$pid_log" >> "$log_file"
  else
    touch "$log_file"
    echo "$pid_log" >> "$log_file"
  fi
}

function argument() {
  local cmd="$1"
  local folder_name="$2"
  local word="$3"
  local PID="$$" # Store the PID of the script

  case "$cmd" in
  #-fc is the stands for directory content
    "-fc")
      if [[ -n "$folder_name" && -d "$folder_name" ]]; then
        PID_log_file "-fc \"$folder_name\""
        PID_log_file "$PID"
        log_activity " -fc \"$folder_name\""
        log_folder_content "$folder_name"
        folder_content "$folder_name"

      else
        echo "Error: Folder name is missing or invalid."
        echo "Usage: ./uuid -fc <folder_name>"
      fi
      ;;
      #-v4 is for version 4 uuid
    "-v4")
      PID_log_file "-v4"
      PID_log_file "$PID"
      uuid4_textfile
      log_activity " -v4"
      ;;
      #-v5 is for version 5 uuid and -n is to input a whatever the word is
    "-v5")
      if [[ -n "$word" ]]; then
        PID_log_file "-v5 -n \"$word\""
        PID_log_file "$PID"
        uuid5_textfile "$word"
        log_activity " -v5 -n \"$word\""
      else
        echo "Error: Word is missing."
        echo "Usage: ./uuid -v5 -n <word>"
      fi
      ;;
    *)
      echo "Invalid command: $cmd"
      echo "Usage: ./uuid [-fc <folder_name> | -v4 | -v5 -n <word>]"
      ;;
  esac
}

if [[ $# -lt 1 || $# -gt 4 ]]; then
  echo "Invalid number of arguments."
  echo "Usage: ./uuid [-fc <folder_name> | -v4 | -v5 -n <word>]"
  exit 1
fi

argument "$@"