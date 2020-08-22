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

echo line 1 >a
shrug-add a
shrug-commit -m 'first commit' >stdout.txt

out=`cat stdout.txt`
ans="Committed as commit 0"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

shrug-show 0:a >stdout.txt

out=`cat stdout.txt`
ans="line 1"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

if [ "$pass" -eq 1 ]
then
    echo "Test02 passed"
else
    echo "Test02 failed"
fi

