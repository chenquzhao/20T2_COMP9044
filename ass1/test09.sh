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

seq 2 9 >7.txt
shrug-commit -a -m commit-1 >stdout.txt

out=`cat stdout.txt`
ans="Committed as commit 0"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

shrug-branch new
echo hello >7.txt
shrug-merge new -m >stdout.txt

out=`cat stdout.txt`
ans="shrug-merge: error: empty commit message"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

if [ "$pass" -eq 1 ]
then
    echo "Test09 passed"
else
    echo "Test09 failed"
fi