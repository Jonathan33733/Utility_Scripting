#!/bin/bash

function generate_v4() {
  local uuid=""
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
  
  echo "${uuid}"
}

function generate_v5() {
  # NameSpace_DNS: {6ba7b810-9dad-11d1-80b4-00c04fd430c8} 
  # https://stackoverflow.com/questions/10867405/generating-v5-uuid-what-is-name-and-namespace#:~:text=to%20be%20given.-,The%20namespace%20is%20either%20a%20UUID%20in%20string%20representation%20or,a%20string%20of%20arbitrary%20length.&text=The%20name%20is%20a%20string%20of%20arbitrary%20length.,-The%20name%20is

  local namespace="6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  local name="secert.com"
  # link the namespace and name 
  # when the sha1sum when its piped to the awk '{print $1}' it extracts the first field of the output, which is the actual hash value
  local uuid="$(echo -n "${namespace}${name}" | sha1sum | awk '{print $1}' | sed -r 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/g')"
  
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
  local uuid5="$(generate_v5)"

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

function argument() {
  local version="$1"
  
  if [[ "$version" == "-v4" ]]; then
    uuid4_textfile
  elif [[ "$version" == "-v5" ]]; then
    uuid5_textfile
  else
    echo "Invalid version specified. Please use -v4 or -v5."
    return 1
  fi
}

argument "$@"
