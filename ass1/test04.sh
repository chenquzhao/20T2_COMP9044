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

echo hello >a
echo hello >b
echo hello >c
shrug-add a c
shrug-commit -m 0 >stdout.txt

out=`cat stdout.txt`
ans="Committed as commit 0"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

echo world >a
shrug-status >stdout.txt

out=`cat stdout.txt`
ans="a - file changed, changes not staged for commit
b - untracked
c - same as repo
stdout.txt - untracked"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

if [ "$pass" -eq 1 ]
then
    echo "Test04 passed"
else
    echo "Test04 failed"
fi
