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
  # NameSpace_DNS: {6ba7b810-9dad-11d1-80b4-00c04fd430c8} 
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
  # List all files in the _Directory directory
  files=$(ls -R _Directory/*)

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
      echo "File type: $type, Count: $count, Size: $size"
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

function argument() {
  #-fc is the stands for folder content
  if [[ "$1" == "-fc" ]]; then
    folder_content
  #-v4 is for version 4 uuid
  elif [[ "$1" == "-v4" ]]; then
    uuid4_textfile
  #-v5 is for version 5 uuid and -n is to input a whatever the word is
  elif [[ "$1" == "-v5" && "$2" == "-n" && -n "$3" ]]; then
    uuid5_textfile "$3"
  else
    echo "Invalid arguments specified. Please use -fc, -v4, or -v5 -n [word]."
    return 1
  fi
}

if [[ $# -ne 1 && $# -ne 2 && $# -ne 3 ]]; then
  echo "Usage: $0 [-v4|-v5 -n word|-fc]"
  exit 1
fi

argument "$@"
