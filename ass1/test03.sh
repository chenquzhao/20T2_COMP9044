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

touch a b c
echo hello >a
echo hello >b
echo hello >c
shrug-commit -a -m commit-0 >stdout.txt

out=`cat stdout.txt`
ans="Committed as commit 0"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

shrug-show 0:a >stdout.txt

out=`cat stdout.txt`
ans="hello"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

shrug-show 0:b >stdout.txt

out=`cat stdout.txt`
ans="hello"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

shrug-show 0:c >stdout.txt

out=`cat stdout.txt`
ans="hello"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

if [ "$pass" -eq 1 ]
then
    echo "Test03 passed"
else
    echo "Test03 failed"
fi
