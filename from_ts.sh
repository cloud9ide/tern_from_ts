#!/bin/bash -e

MY_DIR=$(cd $(dirname $BASH_SOURCE); pwd)

: ${2:?Usage: from_ts.sh (PATH|URL) TARGET.json}

readonly SOURCE=$1
readonly TARGET=$2

echo -n $TARGET

reportError() {
    echo " - error: $(cat | grep Error:)"
}

if ! ERROR=$($MY_DIR/node_modules/tern/bin/from_ts "$SOURCE" 2>&1 | sed 's/\[object Object\]/?/g' >$TARGET.tmp); then
    rm -f $TARGET.tmp $TARGET
    echo "$ERROR" | reportError
else
    if ! node -e 'JSON.parse(require("fs").readFileSync("'$TARGET.tmp'").toString())' 2>/dev/null; then
        # Error reported with zero exit code
        cat $TARGET.tmp | reportError
        rm -f $TARGET.tmp $TARGET
        exit
    fi
    if [ $(cat $TARGET.tmp | wc -l) -lt 7 ]; then
        echo "Output file really short, no definitions found?"
        exit
    fi

    mv $TARGET.tmp $TARGET
    echo
fi

