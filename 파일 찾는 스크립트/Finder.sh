#!/bin/sh

rm -rf Result.txt

for list in `cat list.txt`

do
	loc=`ls /home/lee/*/$list 2> /dev/null`
	[ -z "$loc" ] || echo $loc >> Result.txt
done
