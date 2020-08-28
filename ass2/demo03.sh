#!/bin/dash
# Designed for Subset 3

# define index and range
i=0
range=$1

# justify numbers in range
while test $i -lt $range
do
    mod=`expr $i % 2`
    if [ $mod -eq 0 ]
    then
        echo $i is even number
    else
        echo $i is odd number
    fi

    $i=$((i+1))
done

echo -n "Finished!"