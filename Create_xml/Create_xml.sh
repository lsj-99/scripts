#!/bin/bash

StartNumber=4100051

for((i=1;i<=8;i++))
do
	let StartNumber+=1
	mkdir M"$StartNumber"LSG3589102
	cp Source.mpg M"$StartNumber"LSG3589102/M"$StartNumber".mpg
	cp Source.jpg M"$StartNumber"LSG3589102/M"$StartNumber".jpg
	cp ADI.dtd M"$StartNumber"LSG3589102
	cat ADI.xml | sed "s/M4174569/M"$StartNumber"/g" >> M"$StartNumber"LSG3589102/ADI.xml
	
done