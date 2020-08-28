#!/bin/dash
# Designed for Subset 4
lan="Java"

case $lan in
"C") 
echo "C is the best language"
;;
"Java") 
echo "Java is the best language"
;;
*)
echo "Python is the best language"
;;
esac

i=0
while true
do
    echo $i >>'tmp.txt'
    if [ $i -eq 5 ]
    then
        exit 0
    fi
    i=`expr $i + 1`
done