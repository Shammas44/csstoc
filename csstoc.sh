#!/bin/bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-f, --flag      Some flag description
-p, --param     Some param description

In order to generate a csstoc the following conditions must apply:
1) css document must have thos two tags inside à css block comment:

<-- toc -->
<-- tocstop -->

It is used to indicated where toc should start and finish.

2) Titles are identified like this:
level 1 Title:
/*1# some content...

Level 2 Title:
/*2# some content...

etc.
EOF
    exit
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    rm /tmp/csstoc.*
}

setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local _msg=$1
    local _code=${2-1} # default exit status 1
    if [ "$_msg" == "0" ]; then
        IFS="$OLDIFS"
        removeToc
        printToc
        setLastUpdateTime
        if [ $standartOuput == true ]; then
            cat $TMPFILE
        else
            cat $TMPFILE >"${param}"
        fi
        cleanup
    fi
    exit "$_code"
}

parse_params() {
    # default values of variables set from params
    param=''
    standartOuput=false

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        --no-color) NO_COLOR=1 ;;
        -s) standartOuput=true ;;
        -p | --param) # example named parameter
            param="${2-}"
            shift
            ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done
    [[ -z "${param-}" ]] && die "Missing required parameter: param"

    return 0
}

parse_params "$@"

# script logic here

TMPFILE=$(mktemp /tmp/csstoc.$(date +"%s"))
cat "${param}" >>$TMPFILE

readonly EXTENSION=$(echo "${param}" | grep -o "\..*")
readonly FILENAME=$TMPFILE
tocStartSymbol="<-- toc -->"
tocStopSymbol="<-- tocstop -->"

if [ "$EXTENSION" == '.css' ]; then
    commentIdentifier='\/\*'
    sassComment=''
elif [ "$EXTENSION" == '.scss' ] || [ "$EXTENSION" == '.sass' ]; then
    commentIdentifier='\/\/'
    sassComment='\/\/ '
else
    die "Unknown extension $EXTENSION"
fi

h1=0
h2=0
h3=0
OLDIFS="$IFS"
IFS=$'\n'
titles=($(grep -o -n -E "$commentIdentifier\d#.*" <"${FILENAME}"))
summaryStartRowNumber=$(grep -o -n -i "$tocStartSymbol" <"${FILENAME}" | head -n 1 | cut -f1 -d:)
summaryEndRowNumber=$(grep -o -n "$tocStopSymbol" <"${FILENAME}" | head -n 1 | cut -f1 -d:)
output=()

#updateTitle
#@param $1 the item to replace with the ligne number
#@param $2 new number
#@param $3 title hierachy
#@return void
function updateTitle() {
    local _newNumber=$2
    local _rowNumber=$(echo $1 | grep -o "^\d*")
    local _replacement=$(echo $1 | grep -o "#.*" | grep -o -E -i "[a-z].*")
    local _tocReplacement="${_newNumber} ${_replacement}"
    _replacement="${commentIdentifier}${3}# \$${_newNumber} ${_replacement}"
    sed -i '' $_rowNumber"s/.*/$_replacement/" $FILENAME
    updateToc "${_tocReplacement}" "${_newNumber}" "${3}"
}

#updateToc generate the new toc as a string
#@param $1 the title
#@param $2 the number
#@param $3 title hierachy
#@return void
function updateToc() {
    case "${3}" in
    1)
        local str=""
        ;;
    2)
        local str="\t- "
        ;;
    3)
        local str="\t\t- "
        ;;
    esac
    output+=("${str}${1}")
}

#printToc refresh toc in source file
#return void
function printToc() {
    local i=$(($summaryStartRowNumber + 1))
    local size=$((${#output[@]} - 1))
    for value in "${output[@]}"; do
        sed -i '' $i"s/.*/${sassComment}${value} \n/" $FILENAME
        i=$(($i + 1))
    done
    #display tocstop symbol in the current file
    sed -i '' $i"s/.*/${sassComment}${tocStopSymbol}/" $FILENAME
}

#removeToc remove toc in the current file
#return void
function removeToc() {
    local _diff=$((${summaryEndRowNumber} - ${summaryStartRowNumber}))
    if [ $_diff != 1 ]; then
        local firstLineToRemove=$(($summaryStartRowNumber + 1))
        local lastLineToRemove=$(($summaryEndRowNumber - 1))
        sed -i '' -e "${firstLineToRemove},${lastLineToRemove}d" "${FILENAME}"
    fi
}

#setLastUpdateTime set time of the last writing in the current file
#return void
function setLastUpdateTime() {
    local _lastTime=$(grep -o -n -E "Last update:" <"${FILENAME}")
    if [ -n "$_lastTime" ]; then
        local _rowNumber=$(echo $_lastTime | grep -o -E "^\d*")
        local _currentTime=$(date +"%D %T")
        _currentTime=$(echo $_currentTime | sed 's/\//:/g')
        sed -i '' $_rowNumber"s/.*/${sassComment}Last update: $_currentTime/" $FILENAME
    fi
}

for item in "${titles[@]}"; do
    titleNumber=$(echo "${item}" | grep -E -o "${commentIdentifier}\d#" | grep -E -o '\d')
    case "${titleNumber}" in
    1)
        h1=$(($h1 + 1))
        _sectionNumber=$h1"."
        updateTitle "${item}" "${_sectionNumber}" 1
        ;;
    2)
        h2=$(($h2 + 1))
        _sectionNumber=$h1"."$h2"."
        updateTitle "${item}" "${_sectionNumber}" 2
        ;;
    3)
        h3=$(($h3 + 1))
        _sectionNumber=$h1"."$h2"."$h3"."
        updateTitle "${item}" "${_sectionNumber}" 3
        ;;
    esac
done
die 0
