#!/bin/bash
hash_1(){

date=`date`
echo $date

#a_1=$(cat $1)
#a_2=$(cat $2)

for a_1 in `cat $1`
do
        a_max[$i]=$a_1
        let i+=1
done

for a_2 in `cat $2`
do
        b_max[$j]=$a_2
        let j+=1
done

#for list in ${b_max[@]}
#do
#       for list_2 in ${a_max[@]}
#       do
#               if [ $list = $list_2 ]
#               then
#                       echo $list_2
#                       break
#               fi
#       done
#done

for((i=0;i<=${#a_max[@]};i++))
do
        for((j=0;j<=${#b_max[@]};j++))
        do
                if [ ${b_max[$i]} = ${a_max[$j]} ]
                then
                        echo ${b_max[$j]}
                        break
                fi
        done
done
date=`date`
echo $date

}

bash_1(){

date=`date`
echo $date
for list in `cat b`
do
        cat a | grep $list > /dev/null 2> /dev/null
        if [ $? -eq 0 ]
        then
                echo $list > /dev/null
        fi
done
date=`date`
echo $date


}
Main(){

a=Hit_cut
b=static

hash_1 $a $b

}

case $1 in
        hash)
                Main
                hash_1
                ;;
        bash)
                bash_1
                ;;
        *)
                echo No
esac
exit