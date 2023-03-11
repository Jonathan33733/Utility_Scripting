#!/bin/bash

function generate_v4() {
  local uuid=""
  local updateUuid=""
  local byte7=""
  local byte9=""
  local hex_digits=(0 1 2 3 4 5 6 7 8 9 a b c d e f)

  # UUID format consists of 36 characters separated by hyphens
  for i in {1..36}; do
    if [[ $i == 9 || $i == 14 || $i == 19 || $i == 24 ]]; then
      uuid="${uuid}-"
    else
      # generates a random integer between 0 and 15 using the $((RANDOM%16)) syntax
      uuid="${uuid}${hex_digits[$((RANDOM%16))]}"
    fi
  done

  for (( i=0; i<${#uuid}; i++ )); do
    if [[ $i == 14 ]]; then
      byte7="${uuid:i:1}${uuid:i+1:1}"
      byte7=$(( ( 0x${byte7} & 0x0f ) | 0x40 ))
      byte7=$(printf '%x' $byte7)
      updateUuid="${updateUuid}${byte7}"
      i=$((i+1))
    elif [[ $i == 15 ]]; then
      updateUuid="${updateUuid}-"
    elif [[ $i == 19 ]]; then
      byte9="${uuid:i:1}${uuid:i+1:1}"
      byte9=$(( ( 0x${byte9} & 0x3f ) | 0x80 ))
      byte9=$(printf '%x' $byte9)
      updateUuid="${updateUuid}${byte9}"
      i=$((i+1))
    else
      updateUuid="${updateUuid}${uuid:i:1}"
    fi
  done

  echo "${updateUuid}"
}

function generate_v5() {
  # NameSpace_DNS: {6ba7b810-9dad-11d1-80b4-00c04fd430c8} 
  # https://stackoverflow.com/questions/10867405/generating-v5-uuid-what-is-name-and-namespace#:~:text=to%20be%20given.-,The%20namespace%20is%20either%20a%20UUID%20in%20string%20representation%20or,a%20string%20of%20arbitrary%20length.&text=The%20name%20is%20a%20string%20of%20arbitrary%20length.,-The%20name%20is

  local namespace="6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  local name="$1"
  # link the namespace and name 
  # when the sha1sum when its piped to the awk '{print $1}' it extracts the first field of the output, which is the actual hash value
  local uuid="$(echo -n "${namespace}${name}" | sha1sum | awk '{print $1}' | sed -r 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/g' | cut -c-36)"
  
  echo "${uuid}"
}

function uuid4_textfile(){
  local uuid4="$(generate_v4)"

  if [[ -f "uuid4.txt" ]]; then
    rm "uuid4.txt"
  fi

  if [[ -f "uuid5.txt" ]]; then
    if ! grep -q "${uuid4}" uuid5.txt; then
      echo "${uuid4}" >> uuid4.txt
      echo "${uuid4}"
    fi
  else
    echo "${uuid4}" >> uuid4.txt
    echo "${uuid4}"
  fi
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

function file_content() {
   #list all files in the _Directory directory
  files=$(ls -R _Directory/*)

  #Loops through all subdirectories under _Directory
  for subdir in $(echo "$files" | grep ":$" | sed 's/://' | sort -u); do
    echo "$subdir"

    #Find the total size used in the current subdirectory
    size=$(du -hs "$subdir" | awk '{ print $1 }')
    echo "Total space used: $size"

    #Find the file types and their sizes in the current subdirectory
    types=$(find "$subdir" -type f | sed 's/.*\.//' | sort | uniq -c | awk '{ print $2 }')
    for type in $types; do
      echo "File type: $type, Size: $size"
    done
  done
}

function argument() {
  if [[ "$1" == "-v4" ]]; then
    uuid4_textfile "$2"
  elif [[ "$1" == "-v5" && "$2" == "-n" && -n "$3" ]]; then
    uuid5_textfile "$3"
  elif [[ "$1" == "-fc" ]]; then
    file_content
  else
    echo "Invalid arguments specified. Please use -v4 or -v5 -n [word], or -fc."
    return 1
  fi
}

if [[ $# -ne 2 && $# -ne 3 ]]; then
  echo "Usage: $0 [-v4|-v5 -n word]"
  exit 1
fi

argument "$@"
