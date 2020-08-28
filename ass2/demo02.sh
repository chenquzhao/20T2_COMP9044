#!/bin/dash
# Designed for Subset 2

bonus="right"
if test $bonus = "left"
then
    echo left is bonus
elif test $bonus == "right"
    echo right is bonus
else
    echo bonus not found
fi

num=12
if test $num -gt 15
then
    echo 'num is larger than 15'
elif test $num -lt 10
    echo 'num is less than 10'
else
    echo 'num is between 10 and 15'
fi