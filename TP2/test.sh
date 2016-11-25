#!/bin/bash

TESTS_REP=""
TEST="./tests/level2if1"

OUTPUT="output_exec"

ANTLR_JAR="../antlr-3.5.2-complete.jar"
ANTLR_RUNT="../antlr-3.5.2-runtime.jar"
SRC_DIR="./src"

VSL=".vsl"
OUT=".mips_out"
IN=".test_in"
TEST_DIR="./tests/"

CLASSPATHRUN=$SRC_DIR:$ANTLR_JAR:$ANTLR_RUNT

for TEST in $(find tests/testlevel? -type f -name '*.vsl')
do
TEST=${TEST%.*}
echo "$TEST"
#if [ $# -ne 1 ]
#then
#    echo "Usage : test.sh <testfilepath>"
#    echo "        with <testfilepath> provided without its extension"
#    exit 1
#fi
#TEST=$1

java -cp $CLASSPATHRUN VslComp $TEST$VSL > 3aOutput
if [ 0 -eq $? ]
then 
    cd nachos
    ./asm2bin.sh output

    if [ -e ../$TEST$IN ]
    then
	cat ../$TEST$IN | ./exec.sh output | head -n -3 > ../$OUTPUT
    else
	./exec.sh output | head -n -3 > ../$OUTPUT
    fi 
    cd ..
    echo "DIFF : "
    diff -Bb $OUTPUT $TEST$OUT
fi
done
