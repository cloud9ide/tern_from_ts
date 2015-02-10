#!/bin/bash -e

MY_DIR=$(cd $(dirname $BASH_SOURCE); pwd)

cd $MY_DIR
[ -e sigs_ts ] || git clone https://github.com/borisyankov/DefinitelyTyped.git sigs_ts
cd sigs_ts
git pull
[ -e sigs/revision.txt ] && git checkout $(cat sigs/revision.txt)
REVISION=$(git rev-parse HEAD)

cd $MY_DIR
mkdir -p sigs
cd sigs
echo $REVISION > revision.txt
cp ../sigs_ts/LICENSE .

if ! which parallel &> /dev/null; then
    echo "Please install GNU parallel" >&2
    return 1
fi

ls ../sigs_ts | parallel '
    DIR=../sigs_ts/{1}
    find_main_file() {
        local DIR=$1
        local NAME=$2
        try() {
            if [ -e $1 ]; then
                echo "$1"
            else
                return 1
            fi
        }
        
        try $DIR/$DIR.d.ts ||
        try $DIR/angular.d.ts ||
        try `ls $DIR/*.d.ts` ||
        echo "$NAME.json - could not find main signature file :("
    }
    
    if [ ! -d $DIR ]; then
        exit
    fi
    NAME=$(basename $DIR)
    MAIN=$(find_main_file $DIR $NAME)
    if [ "$MAIN" ]; then
        bash '$MY_DIR'/from_ts.sh $MAIN $NAME.json
    fi
    for OTHER in $DIR/*.d.ts; do
        if [ "$OTHER" == "$MAIN" ]; then
            continue
        fi
        bash -e '$MY_DIR'/from_ts.sh $OTHER _$(basename $DIR)_$(basename $OTHER .d.ts).json
    done
'

rm -f sigs/yosay.json

{
    echo '{"sigs":{'
    for D in $(cd $MY_DIR/sigs; ls); do
        if [[ "$D" =~ ^_ ]]; then
            continue
        fi
        echo -n '"'${D%.json}'": {'
        echo -n '"main": "'$D'",'
        PROJECT=$(grep -s 'Project: http' $MY_DIR/sigs_ts/${D%.json}/${D%.json}.d.ts | head -1 | grep -o 'http:.*' | tr -d '\r' || :)
        if [ "$PROJECT" ]; then
            echo "PROJECT: $PROJECT" >&2
            echo -n '"url": "'$PROJECT'",'
        fi
        echo -n '"extra": {'
        for E in $(cd $MY_DIR/sigs; ls _${D%.json}* 2>/dev/null); do
            echo -n '"'${E%.json}'": "'$E'",'
        done
        echo -n '}},'
    done
    echo '}}'
} | sed 's/"extra": {}//g; s/, *}/}/g' > $MY_DIR/sigs/__list.json
