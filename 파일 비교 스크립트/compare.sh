#!/bin/bash
#equal
LIST1="a2.txt"
LIST2="a1.txt"
for list in `cat $LIST1`
do
        cat $LIST2 | grep -w $list > /dev/null 2>&1 # > /dev/null 2> dev/null
	        if [ $? -eq 1 ]  #ne = only eq= equal
		    then
		    echo $list >> result.txt
		fi
done