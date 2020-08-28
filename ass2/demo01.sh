#!/bin/dash
# Designed for Subset 1

for fruit in apple pear orange melon
do
    read line
    echo $fruit $line
done

# traverse file
for sh_file in *.sh
do
    echo $sh_file found
done

# test exit
for season in spring summer autumn winter
do
    echo $season
    exit 0
done