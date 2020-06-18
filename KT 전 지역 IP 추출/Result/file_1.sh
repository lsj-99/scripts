
#!/bin/bash

ListFile="lsmiplist.txt"

for list in `cat $ListFile`
do

        /usr/local/castis/tools/SampleNetIODownloader $list /home/castis/20141230/all_lb.cfg /usr/local/castis/lb.cfg 10000000

        lb_list=`cat /home/castis/20141230/all_lb.cfg | grep "Server" | grep "Address" | grep -v "Using" | grep -v "Representative" | grep -v "^#" | cut -d = -f 2`

        DFSIP=`cat /home/castis/20141230/all_lb.cfg | grep "MainDFSIP" | cut -d = -f 2`          

        count=`cat all_lb.cfg | grep "MainDFSIP" | wc -l` 

		if [ $count = 1 ]
	
         	then	
        		echo "$lb_list" | grep -v $DFSIP >> /home/castis/20141230/all_ip.txt       
	        else 
			echo "$lb_list" >> /home/castis/20141230/all_ip.txt 
		fi
sleep 1
done
