#!/bin/bash -e

MY_DIR=$(cd $(dirname $BASH_SOURCE); pwd)

: ${2:?Usage: from_ts.sh (PATH|URL) TARGET.json}

readonly SOURCE=$1
readonly TARGET=$2

echo -n $TARGET

if ! ERROR=$($MY_DIR/node_modules/tern/bin/from_ts "$SOURCE" 2>&1 | sed 's/\[object Object\]/?/g' >$TARGET.tmp); then
    rm $TARGET.tmp
    DETAILS=$(echo "$ERROR" | grep Error:)
    echo " - $DETAILS"
else
    mv $TARGET.tmp $TARGET
    echo
fi

