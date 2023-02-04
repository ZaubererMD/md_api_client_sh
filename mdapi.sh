#!/bin/bash

# replace with url and port of your own md_api_server instance
API_URL="http://localhost:3000"

# function copied from https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command
rawurlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"    # You can either set a return variable (FASTER) 
    REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

# function copied from https://stackoverflow.com/questions/1955505/parsing-json-with-unix-tools
function parse_json()
{
    echo $1 | \
    sed -e 's/[{}]/''/g' | \
    sed -e 's/", "/'\",\"'/g' | \
    sed -e 's/" ,"/'\",\"'/g' | \
    sed -e 's/" , "/'\",\"'/g' | \
    sed -e 's/","/'\"---SEPERATOR---\"'/g' | \
    awk -F=':' -v RS='---SEPERATOR---' "\$1~/\"$2\"/ {print}" | \
    sed -e "s/\"$2\"://" | \
    tr -d "\n\t" | \
    sed -e 's/\\"/"/g' | \
    sed -e 's/\\\\/\\/g' | \
    sed -e 's/^[ \t]*//g' | \
    sed -e 's/^"//'  -e 's/"$//'
}

# check whether this is a login attempt
if [ $1 = "login" ];
then
    USERNAME=$2
    PASSWORD=$3
    USERNAME_UC=$( echo -n "$USERNAME" | awk '{ printf toupper($$0) }')
    HASH1=$( echo -n "$USERNAME_UC" | sha256sum | cut -d ' ' -f1 )
    PASSWORD_HASH=$( echo -n "$HASH1$PASSWORD" | sha256sum | cut -d ' ' -f1 )
    echo $($0 login_hashed $USERNAME $PASSWORD_HASH)

elif [ $1 = "login_hashed" ]; # login with a stored password hash
then
    # request login-token
    TOKEN_RESPONSE=$($0 -method "session/request_login_token")
    LOGIN_TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.data.token')
    
    # calculate tokenized password hash
    PASSWORD_HASH=$( echo -n "$3$LOGIN_TOKEN" | sha256sum | cut -d ' ' -f1 )

    #perform login
    echo $($0 -method "session/login" -username $2 -password $PASSWORD_HASH)
    
else
    METHOD=""
    PARMS=""

    # Parsing of named parameters, adapted from https://brianchildress.co/named-parameters-in-bash/
    while [ $# -gt 0 ]; do
        if [[ $1 == *"-"* ]]; then
            KEY=$( rawurlencode "${1/-/}" )
            if [[ $KEY == "method" ]]; then
                METHOD="/$2"
            else
                VALUE=$( rawurlencode "$2" )
                PARMS+="&$KEY=$VALUE"
            fi
        fi
        shift
    done

    # replace first "&" with "?"
    PARMS="${PARMS/&/?}"

    FULL_URL="$API_URL$METHOD$PARMS"
    RESPONSE=$(curl -sS $FULL_URL)
    echo $RESPONSE
fi