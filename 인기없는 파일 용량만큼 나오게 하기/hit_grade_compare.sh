#!/bin/bash

#####config#####
hitcount=/data2/FailOver/.hitcount.history
grade_info=/data2/FailOver/.grade.info
################
Program_path=`dirname $0`
MEM=""

cp -f $hitcount $Program_path/.hitcount
cp -f $grade_info $Program_path/.grade.info

rm -rf $Program_path/.Result.txt

cat $Program_path/.grade.info | egrep -n "*" | sort -nr | cut -d: -f2 | awk '{print $1}' > $Program_path/.sort.txt
cat $Program_path/.hitcount | cut -d, -f1,4 > $Program_path/.hit_cut

echo -n "File Size in GB:"
read size;
let MEM=$size*1024*1024*1024
for list in `cat $Program_path/.sort.txt`
do
        sum=`cat $Program_path/.hit_cut | grep ^$list, | cut -d, -f2`
        let tmp=tmp+$sum
                if [ $tmp -gt $MEM ]
                        then
                        break
                elif [ $tmp -lt $MEM ]
                        then
                        echo  $list >> $Program_path/.Result.txt;
                else
                        break;
                fi
done