#!/bin/dash

if [ -d tmp ]
then
    rm -rf tmp
fi

mkdir tmp
cd tmp
PATH=..:$PATH
pass=1

shrug-init >stdout.txt

out=`cat stdout.txt`
ans="Initialized empty shrug repository in .shrug"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

echo 0 >a
shrug-add a b >stdout.txt

out=`cat stdout.txt`
ans="shrug-add: error: can not open 'non_existent_file'"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

echo 1 >b
shrug-add a b
shrug-commit -m commit-0 >>stdout.txt

out=`cat stdout.txt`
ans="Committed as commit 0"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

if [ "$pass" -eq 1 ]
then
    echo "Test01 passed"
else
    echo "Test01 failed"
fi
