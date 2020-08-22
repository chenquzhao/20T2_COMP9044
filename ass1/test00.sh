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

shrug-init >stdout.txt

out=`cat stdout.txt`
ans="shrug-init: error: .shrug already exists"
if [ "$out" != "$ans" ]
then
    pass=0
fi
rm stdout.txt

if [ "$pass" -eq 1 ]
then
    echo "Test00 passed"
else
    echo "Test00 failed"
fi