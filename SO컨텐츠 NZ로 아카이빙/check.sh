#!/bin/bash

cd /home/castis/temp
ls -l $1 | cut -d" " -f5
